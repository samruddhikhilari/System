from __future__ import annotations

import uuid
import os
import base64
import hashlib
import hmac
import json
import random
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Query, Request, WebSocket, WebSocketDisconnect, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from jose import JWTError, jwt
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import (
    Boolean,
    DateTime,
    ForeignKey,
    Integer,
    String,
    Text,
    create_engine,
    select,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, relationship, sessionmaker


DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./app.db")
JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_MINUTES = 15
REFRESH_TOKEN_DAYS = 7


def _env_int(name: str, default: int) -> int:
    value = os.getenv(name)
    if value is None:
        return default
    try:
        return int(value)
    except ValueError:
        return default


REGISTER_RATE_LIMIT_MAX = _env_int("REGISTER_RATE_LIMIT_MAX", 10)
REGISTER_RATE_LIMIT_WINDOW_SECONDS = _env_int("REGISTER_RATE_LIMIT_WINDOW_SECONDS", 60)
LOGIN_IP_RATE_LIMIT_MAX = _env_int("LOGIN_IP_RATE_LIMIT_MAX", 25)
LOGIN_IP_RATE_LIMIT_WINDOW_SECONDS = _env_int("LOGIN_IP_RATE_LIMIT_WINDOW_SECONDS", 60)
LOGIN_EMAIL_RATE_LIMIT_MAX = _env_int("LOGIN_EMAIL_RATE_LIMIT_MAX", 10)
LOGIN_EMAIL_RATE_LIMIT_WINDOW_SECONDS = _env_int("LOGIN_EMAIL_RATE_LIMIT_WINDOW_SECONDS", 60)
REPORT_GEN_USER_RATE_LIMIT_MAX = _env_int("REPORT_GEN_USER_RATE_LIMIT_MAX", 10)
REPORT_GEN_USER_RATE_LIMIT_WINDOW_SECONDS = _env_int("REPORT_GEN_USER_RATE_LIMIT_WINDOW_SECONDS", 60)
REPORT_GEN_IP_RATE_LIMIT_MAX = _env_int("REPORT_GEN_IP_RATE_LIMIT_MAX", 20)
REPORT_GEN_IP_RATE_LIMIT_WINDOW_SECONDS = _env_int("REPORT_GEN_IP_RATE_LIMIT_WINDOW_SECONDS", 60)


engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


class Base(DeclarativeBase):
    pass


class Organization(Base):
    __tablename__ = "organizations"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    sector: Mapped[str] = mapped_column(String, nullable=False, default="General")
    logo_url: Mapped[Optional[str]] = mapped_column(String, nullable=True)


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    email: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String, nullable=False)
    password_hash: Mapped[str] = mapped_column(String, nullable=False)
    role: Mapped[str] = mapped_column(String, nullable=False, default="analyst", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class UserOrganization(Base):
    __tablename__ = "user_organizations"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False, index=True)
    org_id: Mapped[str] = mapped_column(String, ForeignKey("organizations.id"), nullable=False, index=True)
    role_in_org: Mapped[str] = mapped_column(String, nullable=False, default="member")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False, index=True)
    token: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    revoked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    severity: Mapped[str] = mapped_column(String, nullable=False, index=True)
    title: Mapped[str] = mapped_column(String, nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    supplier_id: Mapped[Optional[str]] = mapped_column(String, nullable=True, index=True)
    status: Mapped[str] = mapped_column(String, nullable=False, default="active", index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    snoozed_until: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class AlertPreference(Base):
    __tablename__ = "alert_preferences"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    org_id: Mapped[str] = mapped_column(String, nullable=False)
    critical_alerts: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    high_priority: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)


class AlertAssignment(Base):
    __tablename__ = "alert_assignments"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    alert_id: Mapped[str] = mapped_column(String, ForeignKey("alerts.id"), nullable=False, unique=True, index=True)
    owner_email: Mapped[str] = mapped_column(String, nullable=False, index=True)
    assigned_by: Mapped[str] = mapped_column(String, nullable=False)
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class MitigationAction(Base):
    __tablename__ = "mitigation_actions"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    title: Mapped[str] = mapped_column(String, nullable=False)
    category: Mapped[str] = mapped_column(String, nullable=False, index=True)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    estimated_risk_reduction: Mapped[float] = mapped_column(nullable=False, default=0.0)
    cost_impact_percent: Mapped[float] = mapped_column(nullable=False, default=0.0)
    service_impact_percent: Mapped[float] = mapped_column(nullable=False, default=0.0)
    status: Mapped[str] = mapped_column(String, nullable=False, default="proposed", index=True)
    requires_approval: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    applied_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    approved_by: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    rejected_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)


class CompliancePolicy(Base):
    __tablename__ = "compliance_policies"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    org_id: Mapped[str] = mapped_column(String, nullable=False, index=True)
    retention_days: Mapped[int] = mapped_column(Integer, nullable=False, default=90)
    mask_sensitive_data: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    actor_email: Mapped[str] = mapped_column(String, nullable=False, index=True)
    action: Mapped[str] = mapped_column(String, nullable=False, index=True)
    entity_type: Mapped[str] = mapped_column(String, nullable=False)
    entity_id: Mapped[str] = mapped_column(String, nullable=False)
    details: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)


class ReportJob(Base):
    __tablename__ = "report_jobs"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    report_type: Mapped[str] = mapped_column(String, nullable=False, default="kpi", index=True)
    period: Mapped[str] = mapped_column(String, nullable=False, default="weekly", index=True)
    output_format: Mapped[str] = mapped_column(String, nullable=False, default="csv", index=True)
    status: Mapped[str] = mapped_column(String, nullable=False, default="ready", index=True)
    generated_by: Mapped[str] = mapped_column(String, nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    download_path: Mapped[str] = mapped_column(String, nullable=False)
    payload_json: Mapped[str] = mapped_column(Text, nullable=False)


class RegisterRequest(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    org_id: str = Field(min_length=1)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    org_id: str = Field(min_length=1)
    device_id: Optional[str] = None
    fcm_token: Optional[str] = None


class RefreshRequest(BaseModel):
    refresh_token: str


class AlertSnoozeRequest(BaseModel):
    duration_minutes: int = Field(default=30, ge=1, le=1440)


class AlertPreferenceRequest(BaseModel):
    critical_alerts: bool = True
    high_priority: bool = True


class AlertSeedRequest(BaseModel):
    count: int = Field(default=5, ge=1, le=50)


class SimulationRunRequest(BaseModel):
    iterations: int = Field(default=1000, ge=100, le=10000)
    disruption_type: str = Field(default="supplier_failure", min_length=3, max_length=64)
    region: str = Field(default="west", min_length=2, max_length=32)


class MitigationDecisionRequest(BaseModel):
    approved: bool
    reason: Optional[str] = Field(default=None, max_length=500)


class AssignAlertRequest(BaseModel):
    owner_email: EmailStr


class UpdateUserRoleRequest(BaseModel):
    role: str = Field(pattern="^(analyst|manager|admin)$")


class CompliancePolicyRequest(BaseModel):
    retention_days: int = Field(default=90, ge=7, le=3650)
    mask_sensitive_data: bool = True


class ReportGenerateRequest(BaseModel):
    period: str = Field(default="weekly", pattern="^(weekly|monthly)$")
    output_format: str = Field(default="csv", pattern="^(csv|pdf)$")


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def as_utc(value: Optional[datetime]) -> Optional[datetime]:
    if value is None:
        return None
    if value.tzinfo is None:
        return value.replace(tzinfo=timezone.utc)
    return value.astimezone(timezone.utc)


def hash_password(password: str) -> str:
    salt = os.urandom(16)
    key = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, 200_000)
    return f"pbkdf2_sha256$200000${base64.b64encode(salt).decode()}${base64.b64encode(key).decode()}"


def verify_password(plain_password: str, hashed_password: str) -> bool:
    try:
        algorithm, rounds, salt_b64, hash_b64 = hashed_password.split("$", 3)
        if algorithm != "pbkdf2_sha256":
            return False
        salt = base64.b64decode(salt_b64)
        expected_hash = base64.b64decode(hash_b64)
        computed = hashlib.pbkdf2_hmac(
            "sha256",
            plain_password.encode("utf-8"),
            salt,
            int(rounds),
        )
        return hmac.compare_digest(computed, expected_hash)
    except Exception:
        return False


def create_access_token(user_id: str, email: str) -> tuple[str, int]:
    expires_delta = timedelta(minutes=ACCESS_TOKEN_MINUTES)
    expires_at = now_utc() + expires_delta
    payload = {
        "sub": user_id,
        "email": email,
        "exp": expires_at,
        "type": "access",
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token, int(expires_delta.total_seconds())


def create_refresh_token(user_id: str) -> tuple[str, datetime]:
    expires_at = now_utc() + timedelta(days=REFRESH_TOKEN_DAYS)
    payload = {
        "sub": user_id,
        "exp": expires_at,
        "type": "refresh",
        "jti": str(uuid.uuid4()),
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return token, expires_at


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except JWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token") from exc


def user_from_access_token(token: str, db: Session) -> User:
    payload = decode_token(token)
    if payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

    user_id = payload.get("sub")
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    return user


def require_user(authorization: Optional[str], db: Session) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")

    token = authorization.split(" ", 1)[1]
    return user_from_access_token(token, db)


def require_role(authorization: Optional[str], db: Session, allowed_roles: set[str]) -> User:
    user = require_user(authorization, db)
    if user.role not in allowed_roles:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Insufficient permissions")
    return user


def write_audit_log(
    db: Session,
    *,
    actor_email: str,
    action: str,
    entity_type: str,
    entity_id: str,
    details: Optional[str] = None,
) -> None:
    db.add(
        AuditLog(
            id=str(uuid.uuid4()),
            actor_email=actor_email,
            action=action,
            entity_type=entity_type,
            entity_id=entity_id,
            details=details,
            created_at=now_utc(),
        )
    )


def _severity_sla_minutes(severity: str) -> int:
    key = severity.lower()
    if key == "critical":
        return 15
    if key == "high":
        return 60
    if key == "medium":
        return 240
    return 480


def _alert_payload(alert: Alert, owner_email: Optional[str] = None) -> dict:
    return {
        "id": alert.id,
        "severity": alert.severity,
        "title": alert.title,
        "body": alert.body,
        "supplier_id": alert.supplier_id,
        "timestamp": as_utc(alert.created_at).isoformat(),
        "status": alert.status,
        "owner_email": owner_email,
    }


def _mitigation_payload(action: MitigationAction) -> dict:
    return {
        "id": action.id,
        "title": action.title,
        "category": action.category,
        "description": action.description,
        "status": action.status,
        "requires_approval": action.requires_approval,
        "created_at": as_utc(action.created_at).isoformat() if action.created_at else None,
        "approved_by": action.approved_by,
        "approved_at": as_utc(action.approved_at).isoformat() if action.approved_at else None,
        "rejected_reason": action.rejected_reason,
        "applied_at": as_utc(action.applied_at).isoformat() if action.applied_at else None,
    }


def _build_kpi_snapshot(db: Session, days: int) -> dict:
    now = now_utc()
    window_start = now - timedelta(days=days)
    alerts = db.scalars(select(Alert).where(Alert.created_at >= window_start)).all()

    acknowledged = [alert for alert in alerts if alert.status == "acknowledged"]
    active = [alert for alert in alerts if alert.status == "active"]

    ack_elapsed = [
        max(int((now - (as_utc(alert.created_at) or now)).total_seconds() / 60), 0)
        for alert in acknowledged
    ]
    active_elapsed = [
        max(int((now - (as_utc(alert.created_at) or now)).total_seconds() / 60), 0)
        for alert in active
    ]

    mtta = round(sum(ack_elapsed) / len(ack_elapsed), 2) if ack_elapsed else 0.0
    mttr = round(sum(active_elapsed) / len(active_elapsed), 2) if active_elapsed else 0.0

    breached = 0
    for alert in active:
        elapsed = max(int((now - (as_utc(alert.created_at) or now)).total_seconds() / 60), 0)
        if elapsed > _severity_sla_minutes(alert.severity):
            breached += 1

    sla_compliance = 0.0 if not active else round((1 - breached / len(active)) * 100, 2)

    hotspot_map: dict[str, int] = {}
    for alert in alerts:
        supplier = alert.supplier_id or "unknown"
        hotspot_map[supplier] = hotspot_map.get(supplier, 0) + 1

    hotspots = [
        {"supplier_id": supplier, "count": count}
        for supplier, count in sorted(hotspot_map.items(), key=lambda item: item[1], reverse=True)[:5]
    ]

    return {
        "window_days": days,
        "generated_at": now.isoformat(),
        "kpis": {
            "alerts_total": len(alerts),
            "active_alerts": len(active),
            "acknowledged_alerts": len(acknowledged),
            "mtta_minutes": mtta,
            "mttr_minutes": mttr,
            "sla_compliance_percent": sla_compliance,
            "sla_breaches": breached,
        },
        "recurrence_hotspots": hotspots,
    }


def _snapshot_to_csv(report_id: str, report_type: str, period: str, snapshot: dict) -> str:
    kpis = snapshot.get("kpis", {})
    rows = [
        ["report_id", report_id],
        ["report_type", report_type],
        ["period", period],
        ["generated_at", snapshot.get("generated_at", "")],
        [],
        ["metric", "value"],
    ]

    for key, value in kpis.items():
        rows.append([key, value])

    rows.append([])
    rows.append(["recurrence_hotspots"])
    rows.append(["supplier_id", "count"])
    for hotspot in snapshot.get("recurrence_hotspots", []):
        rows.append([hotspot.get("supplier_id", ""), hotspot.get("count", 0)])

    return "\n".join(",".join(str(cell) for cell in row) for row in rows)


def ensure_seed_data(db: Session):
    default_org = db.get(Organization, "111")
    if default_org is None:
        db.add(Organization(id="111", name="Demo Organization", sector="General", logo_url=None))

    second_org = db.get(Organization, "222")
    if second_org is None:
        db.add(Organization(id="222", name="Supply Ops Group", sector="Logistics", logo_url=None))

    existing_alert = db.scalar(select(Alert).limit(1))
    if existing_alert is None:
        now = now_utc()
        db.add_all(
            [
                Alert(
                    id=str(uuid.uuid4()),
                    severity="critical",
                    title="Critical supplier concentration detected",
                    body="Pharmaceutical sector depends heavily on a single tier-1 supplier.",
                    supplier_id="supplier_001",
                    status="active",
                    created_at=now,
                    snoozed_until=None,
                ),
                Alert(
                    id=str(uuid.uuid4()),
                    severity="high",
                    title="Port congestion risk increased",
                    body="Western corridor congestion projected to rise by 18% this week.",
                    supplier_id="supplier_002",
                    status="active",
                    created_at=now - timedelta(minutes=20),
                    snoozed_until=None,
                ),
                Alert(
                    id=str(uuid.uuid4()),
                    severity="medium",
                    title="Route delay early warning",
                    body="Intermittent weather disruptions may impact on-time delivery.",
                    supplier_id="supplier_003",
                    status="active",
                    created_at=now - timedelta(hours=1),
                    snoozed_until=None,
                ),
            ]
        )

    pref = db.scalar(select(AlertPreference).where(AlertPreference.org_id == "111"))
    if pref is None:
        db.add(
            AlertPreference(
                id=str(uuid.uuid4()),
                org_id="111",
                critical_alerts=True,
                high_priority=True,
            )
        )

    policy = db.scalar(select(CompliancePolicy).where(CompliancePolicy.org_id == "111"))
    if policy is None:
        db.add(
            CompliancePolicy(
                id=str(uuid.uuid4()),
                org_id="111",
                retention_days=90,
                mask_sensitive_data=True,
                updated_at=now_utc(),
            )
        )

    admin_email = "admin@demo.com"
    manager_email = "manager@demo.com"

    admin_user = db.scalar(select(User).where(User.email == admin_email))
    if admin_user is None:
        admin_user = User(
            id=str(uuid.uuid4()),
            email=admin_email,
            name="Demo Admin",
            password_hash=hash_password("Admin@123"),
            role="admin",
            created_at=now_utc(),
            last_login_at=None,
        )
        db.add(admin_user)
        db.flush()
        db.add(
            UserOrganization(
                id=str(uuid.uuid4()),
                user_id=admin_user.id,
                org_id="111",
                role_in_org="owner",
            )
        )

    manager_user = db.scalar(select(User).where(User.email == manager_email))
    if manager_user is None:
        manager_user = User(
            id=str(uuid.uuid4()),
            email=manager_email,
            name="Demo Manager",
            password_hash=hash_password("Manager@123"),
            role="manager",
            created_at=now_utc(),
            last_login_at=None,
        )
        db.add(manager_user)
        db.flush()
        db.add(
            UserOrganization(
                id=str(uuid.uuid4()),
                user_id=manager_user.id,
                org_id="111",
                role_in_org="manager",
            )
        )

    db.commit()


@asynccontextmanager
async def lifespan(_: FastAPI):
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        ensure_seed_data(db)
    yield


app = FastAPI(title="N-SCRRA Local Backend", version="1.0.0", lifespan=lifespan)
active_alert_connections: dict[WebSocket, str] = {}
notified_sla_breaches: set[str] = set()
rate_limit_store: dict[str, list[datetime]] = {}
manager_only_events = {
    "sla_breach",
    "alert_assigned",
    "approval_submitted",
    "approval_decided",
    "mitigation_applied",
}


def _can_receive_event(role: str, event: str) -> bool:
    if event not in manager_only_events:
        return True
    return role in {"manager", "admin"}


def _enforce_rate_limit(*, key: str, max_requests: int, window_seconds: int) -> None:
    now = now_utc()
    window_start = now - timedelta(seconds=window_seconds)
    hits = [hit for hit in rate_limit_store.get(key, []) if hit >= window_start]

    if len(hits) >= max_requests:
        retry_after_seconds = max(int((hits[0] + timedelta(seconds=window_seconds) - now).total_seconds()), 1)
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail="Too many requests. Please retry shortly.",
            headers={"Retry-After": str(retry_after_seconds)},
        )

    hits.append(now)
    rate_limit_store[key] = hits


def _active_rate_limit_counts() -> list[dict]:
    now = now_utc()
    max_window_seconds = max(
        REGISTER_RATE_LIMIT_WINDOW_SECONDS,
        LOGIN_IP_RATE_LIMIT_WINDOW_SECONDS,
        LOGIN_EMAIL_RATE_LIMIT_WINDOW_SECONDS,
        REPORT_GEN_USER_RATE_LIMIT_WINDOW_SECONDS,
        REPORT_GEN_IP_RATE_LIMIT_WINDOW_SECONDS,
    )
    window_start = now - timedelta(seconds=max_window_seconds)

    snapshot: list[dict] = []
    stale_keys: list[str] = []
    for key, hits in rate_limit_store.items():
        active_hits = [hit for hit in hits if hit >= window_start]
        if not active_hits:
            stale_keys.append(key)
            continue

        rate_limit_store[key] = active_hits
        snapshot.append(
            {
                "key": key,
                "active_requests": len(active_hits),
                "oldest_request_at": as_utc(active_hits[0]).isoformat(),
                "latest_request_at": as_utc(active_hits[-1]).isoformat(),
            }
        )

    for key in stale_keys:
        rate_limit_store.pop(key, None)

    snapshot.sort(key=lambda item: item["active_requests"], reverse=True)
    return snapshot


async def _broadcast_alert_event(event: str, payload: dict) -> None:
    if not active_alert_connections:
        return

    message = {
        "event": event,
        "alert": payload,
        "emitted_at": now_utc().isoformat(),
    }
    stale_connections: list[WebSocket] = []
    for websocket, role in list(active_alert_connections.items()):
        if not _can_receive_event(role, event):
            continue
        try:
            await websocket.send_json(message)
        except Exception:
            stale_connections.append(websocket)

    for websocket in stale_connections:
        active_alert_connections.pop(websocket, None)


async def _broadcast_realtime_event(event: str, payload: dict) -> None:
    if not active_alert_connections:
        return

    message = {
        "event": event,
        "data": payload,
        "emitted_at": now_utc().isoformat(),
    }
    stale_connections: list[WebSocket] = []
    for websocket, role in list(active_alert_connections.items()):
        if not _can_receive_event(role, event):
            continue
        try:
            await websocket.send_json(message)
        except Exception:
            stale_connections.append(websocket)

    for websocket in stale_connections:
        active_alert_connections.pop(websocket, None)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def _error_payload(*, code: str, message: str, details: object | None = None) -> dict:
    return {
        "message": message,
        "error": {
            "code": code,
            "message": message,
            "details": details,
        },
    }


@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    detail = exc.detail
    message = detail if isinstance(detail, str) else "Request failed"
    return JSONResponse(
        status_code=exc.status_code,
        content=_error_payload(
            code=f"HTTP_{exc.status_code}",
            message=message,
            details=detail if not isinstance(detail, str) else None,
        ),
    )


@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content=_error_payload(
            code="VALIDATION_ERROR",
            message="Validation failed",
            details=exc.errors(),
        ),
    )


@app.exception_handler(Exception)
async def unhandled_exception_handler(request: Request, exc: Exception):
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=_error_payload(
            code="INTERNAL_SERVER_ERROR",
            message="Internal server error",
        ),
    )


@app.get("/api/v1/health")
def health():
    return {"status": "ok", "service": "local-backend", "time": now_utc().isoformat()}


@app.post("/api/v1/auth/register", status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest, request: Request, db: Session = Depends(get_db)):
    client_ip = request.client.host if request.client else "unknown"
    _enforce_rate_limit(
        key=f"auth:register:ip:{client_ip}",
        max_requests=REGISTER_RATE_LIMIT_MAX,
        window_seconds=REGISTER_RATE_LIMIT_WINDOW_SECONDS,
    )

    existing = db.scalar(select(User).where(User.email == payload.email.lower().strip()))
    if existing:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")

    org = db.get(Organization, payload.org_id)
    if org is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Organization not found")

    user = User(
        id=str(uuid.uuid4()),
        email=payload.email.lower().strip(),
        name=payload.name.strip(),
        password_hash=hash_password(payload.password),
        role="analyst",
        created_at=now_utc(),
        last_login_at=None,
    )
    db.add(user)
    db.flush()

    membership = UserOrganization(
        id=str(uuid.uuid4()),
        user_id=user.id,
        org_id=org.id,
        role_in_org="member",
    )
    db.add(membership)
    db.commit()

    return {
        "id": user.id,
        "email": user.email,
        "name": user.name,
        "org_id": org.id,
        "message": "Registered successfully",
    }


@app.post("/api/v1/auth/login")
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    client_ip = request.client.host if request.client else "unknown"
    email_key = payload.email.lower().strip()
    _enforce_rate_limit(
        key=f"auth:login:ip:{client_ip}",
        max_requests=LOGIN_IP_RATE_LIMIT_MAX,
        window_seconds=LOGIN_IP_RATE_LIMIT_WINDOW_SECONDS,
    )
    _enforce_rate_limit(
        key=f"auth:login:email:{email_key}",
        max_requests=LOGIN_EMAIL_RATE_LIMIT_MAX,
        window_seconds=LOGIN_EMAIL_RATE_LIMIT_WINDOW_SECONDS,
    )

    user = db.scalar(select(User).where(User.email == payload.email.lower().strip()))
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")

    membership = db.scalar(
        select(UserOrganization).where(
            UserOrganization.user_id == user.id,
            UserOrganization.org_id == payload.org_id,
        )
    )
    if membership is None:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Org access denied")

    access_token, expires_in = create_access_token(user.id, user.email)
    refresh_token, refresh_expires_at = create_refresh_token(user.id)

    db.add(
        RefreshToken(
            id=str(uuid.uuid4()),
            user_id=user.id,
            token=refresh_token,
            expires_at=refresh_expires_at,
            revoked=False,
        )
    )

    user.last_login_at = now_utc()
    db.commit()

    permissions_by_role = {
        "analyst": ["read:dashboard", "write:alerts", "read:profile"],
        "manager": [
            "read:dashboard",
            "write:alerts",
            "read:profile",
            "read:manager",
            "write:approvals",
        ],
        "admin": [
            "read:dashboard",
            "write:alerts",
            "read:profile",
            "read:manager",
            "write:approvals",
            "read:admin",
            "write:admin",
        ],
    }
    role_permissions = permissions_by_role.get(user.role, permissions_by_role["analyst"])

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "expires_in": expires_in,
        "token_type": "Bearer",
        "user_profile": {
            "id": user.id,
            "email": user.email,
            "name": user.name,
            "role": user.role,
            "permissions": role_permissions,
            "selected_org_id": membership.org_id,
            "created_at": user.created_at.isoformat(),
            "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
        },
        "permissions": role_permissions,
    }


@app.post("/api/v1/auth/refresh")
def refresh_token(payload: RefreshRequest, db: Session = Depends(get_db)):
    decoded = decode_token(payload.refresh_token)
    if decoded.get("type") != "refresh":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

    token_row = db.scalar(select(RefreshToken).where(RefreshToken.token == payload.refresh_token))
    if token_row is None or token_row.revoked or token_row.expires_at < now_utc():
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Refresh token invalid/expired")

    user = db.get(User, token_row.user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    access_token, expires_in = create_access_token(user.id, user.email)
    return {
        "access_token": access_token,
        "refresh_token": payload.refresh_token,
        "expires_in": expires_in,
    }


@app.post("/api/v1/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(payload: dict, db: Session = Depends(get_db)):
    refresh_token_value = payload.get("refresh_token")
    if refresh_token_value:
        token_row = db.scalar(select(RefreshToken).where(RefreshToken.token == refresh_token_value))
        if token_row:
            token_row.revoked = True
            db.commit()
    return None


@app.get("/api/v1/auth/organizations")
def organizations(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    if authorization:
        require_user(authorization, db)

    rows = db.scalars(select(Organization)).all()
    return [
        {
            "id": row.id,
            "name": row.name,
            "logo_url": row.logo_url,
            "sector": row.sector,
            "role_in_org": "member",
        }
        for row in rows
    ]


@app.get("/api/v1/alerts")
def get_alerts(db: Session = Depends(get_db)):
    current_time = now_utc()
    rows = db.scalars(select(Alert).order_by(Alert.created_at.desc())).all()
    assignment_by_alert = {
        assignment.alert_id: assignment.owner_email
        for assignment in db.scalars(select(AlertAssignment)).all()
    }

    visible = [
        row
        for row in rows
        if row.status == "active"
        and (as_utc(row.snoozed_until) is None or as_utc(row.snoozed_until) <= current_time)
    ]

    return [_alert_payload(row, assignment_by_alert.get(row.id)) for row in visible]


@app.websocket("/api/v1/ws/alerts")
async def alerts_ws(websocket: WebSocket):
    token = websocket.query_params.get("token")
    if not token:
        auth_header = websocket.headers.get("authorization")
        if auth_header and auth_header.startswith("Bearer "):
            token = auth_header.split(" ", 1)[1]

    if not token:
        await websocket.close(code=1008, reason="Unauthorized")
        return

    try:
        user_role = "analyst"
        with SessionLocal() as db:
            user = user_from_access_token(token, db)
            user_role = user.role
    except HTTPException:
        await websocket.close(code=1008, reason="Unauthorized")
        return

    await websocket.accept()
    active_alert_connections[websocket] = user_role
    try:
        await websocket.send_json(
            {
                "event": "connected",
                "role": user_role,
                "emitted_at": now_utc().isoformat(),
            }
        )
        while True:
            message_text = await websocket.receive_text()
            if not message_text:
                continue

            try:
                message = json.loads(message_text)
            except json.JSONDecodeError:
                continue

            if isinstance(message, dict) and message.get("type") == "ping":
                await websocket.send_json(
                    {
                        "event": "pong",
                        "emitted_at": now_utc().isoformat(),
                    }
                )
    except WebSocketDisconnect:
        active_alert_connections.pop(websocket, None)
    except Exception:
        active_alert_connections.pop(websocket, None)


@app.post("/api/v1/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(alert_id: str, db: Session = Depends(get_db)):
    alert = db.get(Alert, alert_id)
    if alert is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")

    alert.status = "acknowledged"
    db.commit()
    await _broadcast_alert_event("alert_acknowledged", _alert_payload(alert))
    return {"id": alert.id, "status": alert.status}


@app.post("/api/v1/alerts/{alert_id}/snooze")
async def snooze_alert(alert_id: str, payload: AlertSnoozeRequest, db: Session = Depends(get_db)):
    alert = db.get(Alert, alert_id)
    if alert is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")

    alert.snoozed_until = now_utc() + timedelta(minutes=payload.duration_minutes)
    db.commit()
    await _broadcast_alert_event("alert_snoozed", _alert_payload(alert))
    return {"id": alert.id, "snoozed_until": as_utc(alert.snoozed_until).isoformat()}


@app.post("/api/v1/alerts/seed")
async def seed_alerts(payload: AlertSeedRequest, db: Session = Depends(get_db)):
    severities = ["critical", "high", "medium"]
    templates = {
        "critical": (
            "Critical supplier concentration detected",
            "Single-source dependency exceeded safe threshold.",
        ),
        "high": (
            "Port congestion risk increased",
            "Expected dwell-time volatility in western corridor.",
        ),
        "medium": (
            "Route delay early warning",
            "Weather-linked variability may impact shipment SLAs.",
        ),
    }

    now = now_utc()
    created_ids: list[str] = []
    for index in range(payload.count):
        severity = random.choice(severities)
        title, body = templates[severity]
        alert = Alert(
            id=str(uuid.uuid4()),
            severity=severity,
            title=title,
            body=body,
            supplier_id=f"supplier_{(index % 3) + 1:03d}",
            status="active",
            created_at=now - timedelta(minutes=index * 5),
            snoozed_until=None,
        )
        db.add(alert)
        created_ids.append(alert.id)

    db.commit()
    if created_ids:
        latest = db.get(Alert, created_ids[0])
        if latest is not None:
            await _broadcast_alert_event("alert_seeded", _alert_payload(latest))
    return {
        "seeded": len(created_ids),
        "alert_ids": created_ids,
    }


@app.put("/api/v1/alerts/preferences")
def update_alert_preferences(payload: AlertPreferenceRequest, db: Session = Depends(get_db)):
    pref = db.scalar(select(AlertPreference).where(AlertPreference.org_id == "111"))
    if pref is None:
        pref = AlertPreference(id=str(uuid.uuid4()), org_id="111")
        db.add(pref)

    pref.critical_alerts = payload.critical_alerts
    pref.high_priority = payload.high_priority
    db.commit()
    return {
        "org_id": pref.org_id,
        "critical_alerts": pref.critical_alerts,
        "high_priority": pref.high_priority,
    }


@app.get("/api/v1/dashboard/summary")
def dashboard_summary(db: Session = Depends(get_db)):
    alerts = db.scalars(select(Alert).order_by(Alert.created_at.desc())).all()
    active_alerts = [alert for alert in alerts if alert.status == "active"]

    nri_score = 45.0 + min(len(active_alerts) * 2.5, 20.0)
    nri_delta = -2.1 if len(active_alerts) <= 2 else 1.7

    sectors = [
        {
            "sector": "Pharmaceuticals",
            "icon": "medical",
            "risk_score": 58.0,
            "delta_7d": 3.4,
            "sparkline_data": [49, 51, 54, 53, 55, 57, 58],
        },
        {
            "sector": "Automotive",
            "icon": "directions_car",
            "risk_score": 42.0,
            "delta_7d": -1.3,
            "sparkline_data": [45, 44, 43, 43, 42, 42, 42],
        },
        {
            "sector": "Electronics",
            "icon": "memory",
            "risk_score": 65.0,
            "delta_7d": 4.9,
            "sparkline_data": [53, 56, 58, 61, 62, 64, 65],
        },
    ]

    return {
        "nri_score": nri_score,
        "nri_delta": nri_delta,
        "sectors": sectors,
        "active_alerts": [
            {
                "id": row.id,
                "severity": row.severity,
                "title": row.title,
                "body": row.body,
                "supplier_id": row.supplier_id,
                "timestamp": row.created_at.isoformat(),
                "status": row.status,
            }
            for row in active_alerts[:5]
        ],
        "trend_metrics": {
            "avg_supplier_risk_score": 52.4,
            "active_disruptions_count": len(active_alerts),
            "prediction_confidence": 0.87,
            "risk_score_bars": [38, 45, 52, 56, 61],
        },
        "last_updated": now_utc().isoformat(),
    }


@app.get("/api/v1/network/graph")
def network_graph():
    return {
        "nodes": [
            {"id": "org_111", "label": "Demo Organization", "type": "org", "risk": 38},
            {"id": "supplier_001", "label": "ChemCorp", "type": "supplier", "risk": 72},
            {"id": "supplier_002", "label": "Port Logistics", "type": "supplier", "risk": 61},
            {"id": "supplier_003", "label": "Route Hub", "type": "supplier", "risk": 44},
        ],
        "edges": [
            {"source": "org_111", "target": "supplier_001", "weight": 0.8},
            {"source": "org_111", "target": "supplier_002", "weight": 0.6},
            {"source": "supplier_002", "target": "supplier_003", "weight": 0.4},
        ],
    }


@app.get("/api/v1/risk/breakdown")
def risk_breakdown():
    return {
        "overall_score": 57.2,
        "factors": [
            {"name": "Financial", "score": 52.0, "delta": 1.8},
            {"name": "Operational", "score": 63.0, "delta": 3.5},
            {"name": "Geopolitical", "score": 59.0, "delta": 2.2},
            {"name": "Environmental", "score": 49.0, "delta": -0.9},
        ],
        "signals": [
            "Supplier concentration increased in pharma tier-1 cluster",
            "Port dwell-time variance up 12% week-over-week",
            "Route resilience improved after alternate lane activation",
        ],
    }


@app.post("/api/v1/simulation/run")
def run_simulation(payload: SimulationRunRequest, db: Session = Depends(get_db)):
    active_alerts_count = len(db.scalars(select(Alert).where(Alert.status == "active")).all())
    disruption_factor = {
        "supplier_failure": 1.0,
        "port_congestion": 0.8,
        "geopolitical": 1.2,
        "weather": 0.7,
    }.get(payload.disruption_type, 0.9)

    affected_suppliers = min(12 + int(active_alerts_count * disruption_factor * 2), 80)
    revenue_impact = round(3.2 + active_alerts_count * disruption_factor * 1.4, 2)
    duration_days = min(5 + int(disruption_factor * 9), 30)

    return {
        "simulation_id": str(uuid.uuid4()),
        "iterations": payload.iterations,
        "disruption_type": payload.disruption_type,
        "region": payload.region,
        "suppliers_affected": affected_suppliers,
        "revenue_impact_cr": revenue_impact,
        "duration_days": duration_days,
        "confidence": round(0.78 + min(payload.iterations / 20000, 0.17), 2),
        "generated_at": now_utc().isoformat(),
    }


@app.get("/api/v1/recommendations/optimize")
async def get_recommendations(db: Session = Depends(get_db)):
    rows = db.scalars(select(MitigationAction).order_by(MitigationAction.created_at.desc())).all()

    if not rows:
        seed_actions = [
            MitigationAction(
                id=str(uuid.uuid4()),
                title="Switch to Supplier B",
                category="alternative_supplier",
                description="Shift 25% load from Supplier A to Supplier B for tier-1 APIs.",
                estimated_risk_reduction=18.0,
                cost_impact_percent=3.4,
                service_impact_percent=6.1,
                status="proposed",
                requires_approval=False,
                created_at=now_utc(),
                applied_at=None,
                approved_by=None,
                approved_at=None,
                rejected_reason=None,
            ),
            MitigationAction(
                id=str(uuid.uuid4()),
                title="Reroute via Chennai Port",
                category="route_optimization",
                description="Redirect western corridor volume to alternate eastern route.",
                estimated_risk_reduction=26.0,
                cost_impact_percent=4.8,
                service_impact_percent=4.0,
                status="proposed",
                requires_approval=True,
                created_at=now_utc() - timedelta(minutes=10),
                applied_at=None,
                approved_by=None,
                approved_at=None,
                rejected_reason=None,
            ),
            MitigationAction(
                id=str(uuid.uuid4()),
                title="Increase safety stock for SKU-A",
                category="safety_stock",
                description="Raise cover from 12 days to 18 days for top-demand SKU.",
                estimated_risk_reduction=10.0,
                cost_impact_percent=1.9,
                service_impact_percent=8.5,
                status="proposed",
                requires_approval=False,
                created_at=now_utc() - timedelta(minutes=20),
                applied_at=None,
                approved_by=None,
                approved_at=None,
                rejected_reason=None,
            ),
        ]
        db.add_all(seed_actions)
        db.commit()
        for action in seed_actions:
            if action.requires_approval:
                await _broadcast_realtime_event("approval_submitted", _mitigation_payload(action))
        rows = seed_actions

    return {
        "recommendations": [
            {
                "id": row.id,
                "title": row.title,
                "category": row.category,
                "description": row.description,
                "estimated_risk_reduction": row.estimated_risk_reduction,
                "cost_impact_percent": row.cost_impact_percent,
                "service_impact_percent": row.service_impact_percent,
                "status": row.status,
                "requires_approval": row.requires_approval,
                "created_at": as_utc(row.created_at).isoformat(),
            }
            for row in rows
        ]
    }


@app.post("/api/v1/mitigations/{mitigation_id}/apply")
async def apply_mitigation(
    mitigation_id: str,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    actor = require_user(authorization, db)
    mitigation = db.get(MitigationAction, mitigation_id)
    if mitigation is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mitigation not found")

    if mitigation.requires_approval and mitigation.status != "approved":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Mitigation requires manager approval before apply",
        )

    mitigation.status = "applied"
    mitigation.applied_at = now_utc()
    write_audit_log(
        db,
        actor_email=actor.email,
        action="mitigation_applied",
        entity_type="mitigation",
        entity_id=mitigation.id,
        details=mitigation.title,
    )
    db.commit()
    await _broadcast_realtime_event("mitigation_applied", _mitigation_payload(mitigation))

    return {
        "id": mitigation.id,
        "status": mitigation.status,
        "applied_at": as_utc(mitigation.applied_at).isoformat(),
    }


@app.get("/api/v1/manager/queue")
async def manager_queue(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"manager", "admin"})
    alerts = db.scalars(select(Alert).order_by(Alert.created_at.desc())).all()
    assignments = {
        assignment.alert_id: assignment
        for assignment in db.scalars(select(AlertAssignment)).all()
    }

    now = now_utc()
    queue_items: list[dict] = []
    breached = 0
    breach_events: list[dict] = []
    for alert in alerts:
        created = as_utc(alert.created_at) or now
        elapsed_minutes = max(int((now - created).total_seconds() / 60), 0)
        target_minutes = _severity_sla_minutes(alert.severity)
        is_breached = alert.status == "active" and elapsed_minutes > target_minutes
        if is_breached:
            breached += 1

        owner = assignments.get(alert.id)
        if is_breached and alert.id not in notified_sla_breaches:
            payload = _alert_payload(alert, owner.owner_email if owner else None)
            payload["elapsed_minutes"] = elapsed_minutes
            payload["sla_target_minutes"] = target_minutes
            breach_events.append(payload)
            notified_sla_breaches.add(alert.id)
        if not is_breached and alert.id in notified_sla_breaches:
            notified_sla_breaches.discard(alert.id)

        queue_items.append(
            {
                "id": alert.id,
                "title": alert.title,
                "severity": alert.severity,
                "status": alert.status,
                "owner_email": owner.owner_email if owner else None,
                "elapsed_minutes": elapsed_minutes,
                "sla_target_minutes": target_minutes,
                "sla_breached": is_breached,
                "created_at": created.isoformat(),
            }
        )

    for breach_payload in breach_events:
        await _broadcast_alert_event("sla_breach", breach_payload)

    return {
        "summary": {
            "active": len([item for item in queue_items if item["status"] == "active"]),
            "acknowledged": len([item for item in queue_items if item["status"] == "acknowledged"]),
            "resolved": len([item for item in queue_items if item["status"] == "resolved"]),
            "sla_breaches": breached,
        },
        "queue": queue_items,
    }


@app.post("/api/v1/manager/alerts/{alert_id}/assign")
async def assign_alert(
    alert_id: str,
    payload: AssignAlertRequest,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    actor = require_role(authorization, db, {"manager", "admin"})
    alert = db.get(Alert, alert_id)
    if alert is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")

    assignment = db.scalar(select(AlertAssignment).where(AlertAssignment.alert_id == alert_id))
    if assignment is None:
        assignment = AlertAssignment(
            id=str(uuid.uuid4()),
            alert_id=alert_id,
            owner_email=payload.owner_email,
            assigned_by=actor.email,
            assigned_at=now_utc(),
        )
        db.add(assignment)
    else:
        assignment.owner_email = payload.owner_email
        assignment.assigned_by = actor.email
        assignment.assigned_at = now_utc()

    write_audit_log(
        db,
        actor_email=actor.email,
        action="alert_assigned",
        entity_type="alert",
        entity_id=alert_id,
        details=f"owner={payload.owner_email}",
    )
    db.commit()
    await _broadcast_alert_event("alert_assigned", _alert_payload(alert, assignment.owner_email))

    return {
        "alert_id": alert_id,
        "owner_email": assignment.owner_email,
        "assigned_by": assignment.assigned_by,
        "assigned_at": as_utc(assignment.assigned_at).isoformat(),
    }


@app.get("/api/v1/manager/sla")
def manager_sla(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"manager", "admin"})
    alerts = db.scalars(select(Alert).order_by(Alert.created_at.desc())).all()
    now = now_utc()

    active = [alert for alert in alerts if alert.status == "active"]
    acknowledged = [alert for alert in alerts if alert.status == "acknowledged"]

    active_elapsed = [
        max(int((now - (as_utc(alert.created_at) or now)).total_seconds() / 60), 0)
        for alert in active
    ]
    ack_elapsed = [
        max(int((now - (as_utc(alert.created_at) or now)).total_seconds() / 60), 0)
        for alert in acknowledged
    ]

    mtta = round(sum(ack_elapsed) / len(ack_elapsed), 1) if ack_elapsed else 0.0
    mttr = round(sum(active_elapsed) / len(active_elapsed), 1) if active_elapsed else 0.0

    breached = 0
    for alert in active:
        elapsed = max(int((now - (as_utc(alert.created_at) or now)).total_seconds() / 60), 0)
        if elapsed > _severity_sla_minutes(alert.severity):
            breached += 1

    return {
        "mtta_minutes": mtta,
        "mttr_minutes": mttr,
        "active_alerts": len(active),
        "sla_breaches": breached,
        "sla_compliance_percent": 0 if not active else round((1 - breached / len(active)) * 100, 2),
    }


@app.get("/api/v1/manager/approvals")
def manager_approvals(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"manager", "admin"})
    rows = db.scalars(
        select(MitigationAction).where(
            MitigationAction.requires_approval == True,
            MitigationAction.status == "proposed",
        )
    ).all()
    return {
        "pending": [
            {
                "id": row.id,
                "title": row.title,
                "category": row.category,
                "description": row.description,
                "estimated_risk_reduction": row.estimated_risk_reduction,
                "cost_impact_percent": row.cost_impact_percent,
                "service_impact_percent": row.service_impact_percent,
                "created_at": as_utc(row.created_at).isoformat(),
            }
            for row in rows
        ]
    }


@app.post("/api/v1/manager/approvals/{mitigation_id}/decision")
async def manager_approval_decision(
    mitigation_id: str,
    payload: MitigationDecisionRequest,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    actor = require_role(authorization, db, {"manager", "admin"})
    row = db.get(MitigationAction, mitigation_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Mitigation not found")

    if not row.requires_approval:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Mitigation does not require approval")

    if payload.approved:
        row.status = "approved"
        row.approved_by = actor.email
        row.approved_at = now_utc()
        row.rejected_reason = None
        action = "mitigation_approved"
    else:
        row.status = "rejected"
        row.approved_by = actor.email
        row.approved_at = now_utc()
        row.rejected_reason = payload.reason or "Rejected by manager"
        action = "mitigation_rejected"

    write_audit_log(
        db,
        actor_email=actor.email,
        action=action,
        entity_type="mitigation",
        entity_id=row.id,
        details=payload.reason,
    )
    db.commit()
    await _broadcast_realtime_event("approval_decided", _mitigation_payload(row))
    return {
        "id": row.id,
        "status": row.status,
        "approved_by": row.approved_by,
        "approved_at": as_utc(row.approved_at).isoformat() if row.approved_at else None,
        "rejected_reason": row.rejected_reason,
    }


@app.get("/api/v1/admin/users")
def admin_users(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"admin"})
    users = db.scalars(select(User).order_by(User.created_at.desc())).all()
    return {
        "users": [
            {
                "id": user.id,
                "email": user.email,
                "name": user.name,
                "role": user.role,
                "created_at": as_utc(user.created_at).isoformat(),
                "last_login_at": as_utc(user.last_login_at).isoformat() if user.last_login_at else None,
            }
            for user in users
        ]
    }


@app.put("/api/v1/admin/users/{user_id}/role")
def admin_update_role(
    user_id: str,
    payload: UpdateUserRoleRequest,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    actor = require_role(authorization, db, {"admin"})
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    previous_role = user.role
    user.role = payload.role
    write_audit_log(
        db,
        actor_email=actor.email,
        action="role_updated",
        entity_type="user",
        entity_id=user.id,
        details=f"from={previous_role},to={payload.role}",
    )
    db.commit()
    return {
        "id": user.id,
        "role": user.role,
    }


@app.get("/api/v1/admin/audit-logs")
def admin_audit_logs(
    authorization: Optional[str] = Header(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"admin"})
    all_logs = db.scalars(select(AuditLog).order_by(AuditLog.created_at.desc())).all()
    total = len(all_logs)
    start = (page - 1) * page_size
    end = start + page_size
    logs = all_logs[start:end]
    return {
        "logs": [
            {
                "id": log.id,
                "actor_email": log.actor_email,
                "action": log.action,
                "entity_type": log.entity_type,
                "entity_id": log.entity_id,
                "details": log.details,
                "created_at": as_utc(log.created_at).isoformat(),
            }
            for log in logs
        ],
        "pagination": {
            "page": page,
            "page_size": page_size,
            "total": total,
            "has_next": end < total,
        },
    }


@app.get("/api/v1/admin/integrations/health")
def admin_integrations_health(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"admin"})
    return {
        "sources": [
            {"name": "Port Feed", "status": "healthy", "last_sync_minutes": 4, "error_rate": 0.0},
            {"name": "Supplier ERP", "status": "degraded", "last_sync_minutes": 21, "error_rate": 1.2},
            {"name": "Weather API", "status": "healthy", "last_sync_minutes": 2, "error_rate": 0.0},
        ],
        "generated_at": now_utc().isoformat(),
    }


@app.get("/api/v1/admin/rate-limits")
def admin_rate_limit_stats(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"admin"})
    active_keys = _active_rate_limit_counts()
    return {
        "limits": {
            "register": {
                "max_requests": REGISTER_RATE_LIMIT_MAX,
                "window_seconds": REGISTER_RATE_LIMIT_WINDOW_SECONDS,
            },
            "login_ip": {
                "max_requests": LOGIN_IP_RATE_LIMIT_MAX,
                "window_seconds": LOGIN_IP_RATE_LIMIT_WINDOW_SECONDS,
            },
            "login_email": {
                "max_requests": LOGIN_EMAIL_RATE_LIMIT_MAX,
                "window_seconds": LOGIN_EMAIL_RATE_LIMIT_WINDOW_SECONDS,
            },
            "report_generate_user": {
                "max_requests": REPORT_GEN_USER_RATE_LIMIT_MAX,
                "window_seconds": REPORT_GEN_USER_RATE_LIMIT_WINDOW_SECONDS,
            },
            "report_generate_ip": {
                "max_requests": REPORT_GEN_IP_RATE_LIMIT_MAX,
                "window_seconds": REPORT_GEN_IP_RATE_LIMIT_WINDOW_SECONDS,
            },
        },
        "active_keys": active_keys[:50],
        "generated_at": now_utc().isoformat(),
    }


@app.get("/api/v1/admin/policies/compliance")
def admin_get_compliance_policy(
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"admin"})
    policy = db.scalar(select(CompliancePolicy).where(CompliancePolicy.org_id == "111"))
    if policy is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Compliance policy not found")
    return {
        "org_id": policy.org_id,
        "retention_days": policy.retention_days,
        "mask_sensitive_data": policy.mask_sensitive_data,
        "updated_at": as_utc(policy.updated_at).isoformat(),
    }


@app.put("/api/v1/admin/policies/compliance")
def admin_update_compliance_policy(
    payload: CompliancePolicyRequest,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    actor = require_role(authorization, db, {"admin"})
    policy = db.scalar(select(CompliancePolicy).where(CompliancePolicy.org_id == "111"))
    if policy is None:
        policy = CompliancePolicy(
            id=str(uuid.uuid4()),
            org_id="111",
            retention_days=payload.retention_days,
            mask_sensitive_data=payload.mask_sensitive_data,
            updated_at=now_utc(),
        )
        db.add(policy)
    else:
        policy.retention_days = payload.retention_days
        policy.mask_sensitive_data = payload.mask_sensitive_data
        policy.updated_at = now_utc()

    write_audit_log(
        db,
        actor_email=actor.email,
        action="compliance_policy_updated",
        entity_type="policy",
        entity_id=policy.id,
        details=f"retention_days={payload.retention_days},mask_sensitive_data={payload.mask_sensitive_data}",
    )
    db.commit()
    return {
        "org_id": policy.org_id,
        "retention_days": policy.retention_days,
        "mask_sensitive_data": policy.mask_sensitive_data,
        "updated_at": as_utc(policy.updated_at).isoformat(),
    }


@app.post("/api/v1/reports/generate")
def generate_report(
    payload: ReportGenerateRequest,
    request: Request,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    actor = require_user(authorization, db)
    client_ip = request.client.host if request and request.client else "unknown"
    _enforce_rate_limit(
        key=f"reports:generate:user:{actor.id}",
        max_requests=REPORT_GEN_USER_RATE_LIMIT_MAX,
        window_seconds=REPORT_GEN_USER_RATE_LIMIT_WINDOW_SECONDS,
    )
    _enforce_rate_limit(
        key=f"reports:generate:ip:{client_ip}",
        max_requests=REPORT_GEN_IP_RATE_LIMIT_MAX,
        window_seconds=REPORT_GEN_IP_RATE_LIMIT_WINDOW_SECONDS,
    )

    days = 7 if payload.period == "weekly" else 30
    snapshot = _build_kpi_snapshot(db, days)

    report_id = str(uuid.uuid4())
    download_path = f"/api/v1/reports/{report_id}/download"
    report_job = ReportJob(
        id=report_id,
        report_type="kpi",
        period=payload.period,
        output_format=payload.output_format,
        status="ready",
        generated_by=actor.email,
        created_at=now_utc(),
        completed_at=now_utc(),
        download_path=download_path,
        payload_json=json.dumps(snapshot),
    )
    db.add(report_job)
    write_audit_log(
        db,
        actor_email=actor.email,
        action="report_generated",
        entity_type="report",
        entity_id=report_job.id,
        details=f"period={payload.period},format={payload.output_format}",
    )
    db.commit()

    return {
        "report_id": report_job.id,
        "report_type": report_job.report_type,
        "period": report_job.period,
        "status": report_job.status,
        "generated_at": as_utc(report_job.created_at).isoformat(),
        "download_url": report_job.download_path,
    }


@app.get("/api/v1/reports")
def list_reports(
    authorization: Optional[str] = Header(default=None),
    page: int = Query(default=1, ge=1),
    page_size: int = Query(default=10, ge=1, le=100),
    db: Session = Depends(get_db),
):
    require_user(authorization, db)
    all_rows = db.scalars(select(ReportJob).order_by(ReportJob.created_at.desc())).all()
    total = len(all_rows)
    start = (page - 1) * page_size
    end = start + page_size
    rows = all_rows[start:end]
    return {
        "reports": [
            {
                "id": row.id,
                "report_type": row.report_type,
                "period": row.period,
                "output_format": row.output_format,
                "status": row.status,
                "generated_by": row.generated_by,
                "created_at": as_utc(row.created_at).isoformat(),
                "download_url": row.download_path,
            }
            for row in rows
        ],
        "pagination": {
            "page": page,
            "page_size": page_size,
            "total": total,
            "has_next": end < total,
        },
    }


@app.get("/api/v1/reports/{report_id}/status")
def report_status(
    report_id: str,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_user(authorization, db)
    row = db.get(ReportJob, report_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    return {
        "report_id": row.id,
        "status": row.status,
        "report_type": row.report_type,
        "period": row.period,
        "output_format": row.output_format,
        "generated_at": as_utc(row.created_at).isoformat(),
        "completed_at": as_utc(row.completed_at).isoformat() if row.completed_at else None,
        "download_url": row.download_path,
    }


@app.get("/api/v1/reports/{report_id}/download")
def report_download(
    report_id: str,
    authorization: Optional[str] = Header(default=None),
    db: Session = Depends(get_db),
):
    require_user(authorization, db)
    row = db.get(ReportJob, report_id)
    if row is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Report not found")

    snapshot = json.loads(row.payload_json)
    if row.output_format == "csv":
        csv_data = _snapshot_to_csv(row.id, row.report_type, row.period, snapshot)
        return JSONResponse(
            status_code=status.HTTP_200_OK,
            content={
                "file_name": f"kpi-{row.period}-{row.id}.csv",
                "mime_type": "text/csv",
                "content": csv_data,
            },
        )

    return {
        "file_name": f"kpi-{row.period}-{row.id}.pdf",
        "mime_type": "application/json",
        "content": snapshot,
    }
