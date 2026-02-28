from __future__ import annotations

import uuid
import os
import base64
import hashlib
import hmac
import random
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, Request, status
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
JWT_SECRET = "dev-secret-change-me"
JWT_ALGORITHM = "HS256"
ACCESS_TOKEN_MINUTES = 15
REFRESH_TOKEN_DAYS = 7


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
    role: Mapped[str] = mapped_column(String, nullable=False, default="analyst")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)


class UserOrganization(Base):
    __tablename__ = "user_organizations"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    org_id: Mapped[str] = mapped_column(String, ForeignKey("organizations.id"), nullable=False)
    role_in_org: Mapped[str] = mapped_column(String, nullable=False, default="member")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), nullable=False)
    token: Mapped[str] = mapped_column(String, unique=True, index=True, nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    revoked: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    severity: Mapped[str] = mapped_column(String, nullable=False)
    title: Mapped[str] = mapped_column(String, nullable=False)
    body: Mapped[str] = mapped_column(Text, nullable=False)
    supplier_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    status: Mapped[str] = mapped_column(String, nullable=False, default="active")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
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
    alert_id: Mapped[str] = mapped_column(String, ForeignKey("alerts.id"), nullable=False, unique=True)
    owner_email: Mapped[str] = mapped_column(String, nullable=False)
    assigned_by: Mapped[str] = mapped_column(String, nullable=False)
    assigned_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class MitigationAction(Base):
    __tablename__ = "mitigation_actions"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    title: Mapped[str] = mapped_column(String, nullable=False)
    category: Mapped[str] = mapped_column(String, nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    estimated_risk_reduction: Mapped[float] = mapped_column(nullable=False, default=0.0)
    cost_impact_percent: Mapped[float] = mapped_column(nullable=False, default=0.0)
    service_impact_percent: Mapped[float] = mapped_column(nullable=False, default=0.0)
    status: Mapped[str] = mapped_column(String, nullable=False, default="proposed")
    requires_approval: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    applied_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    approved_by: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    approved_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True), nullable=True)
    rejected_reason: Mapped[Optional[str]] = mapped_column(Text, nullable=True)


class CompliancePolicy(Base):
    __tablename__ = "compliance_policies"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    org_id: Mapped[str] = mapped_column(String, nullable=False)
    retention_days: Mapped[int] = mapped_column(Integer, nullable=False, default=90)
    mask_sensitive_data: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    actor_email: Mapped[str] = mapped_column(String, nullable=False)
    action: Mapped[str] = mapped_column(String, nullable=False)
    entity_type: Mapped[str] = mapped_column(String, nullable=False)
    entity_id: Mapped[str] = mapped_column(String, nullable=False)
    details: Mapped[Optional[str]] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


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


def require_user(authorization: Optional[str], db: Session) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Unauthorized")

    token = authorization.split(" ", 1)[1]
    payload = decode_token(token)
    if payload.get("type") != "access":
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token type")

    user_id = payload.get("sub")
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="User not found")

    return user


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


app = FastAPI(title="N-SCRRA Local Backend", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def on_startup():
    Base.metadata.create_all(bind=engine)
    with SessionLocal() as db:
        ensure_seed_data(db)


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
def register(payload: RegisterRequest, db: Session = Depends(get_db)):
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
def login(payload: LoginRequest, db: Session = Depends(get_db)):
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

    visible = [
        row
        for row in rows
        if row.status == "active"
        and (as_utc(row.snoozed_until) is None or as_utc(row.snoozed_until) <= current_time)
    ]

    return [
        {
            "id": row.id,
            "severity": row.severity,
            "title": row.title,
            "body": row.body,
            "supplier_id": row.supplier_id,
            "timestamp": as_utc(row.created_at).isoformat(),
            "status": row.status,
        }
        for row in visible
    ]


@app.post("/api/v1/alerts/{alert_id}/acknowledge")
def acknowledge_alert(alert_id: str, db: Session = Depends(get_db)):
    alert = db.get(Alert, alert_id)
    if alert is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")

    alert.status = "acknowledged"
    db.commit()
    return {"id": alert.id, "status": alert.status}


@app.post("/api/v1/alerts/{alert_id}/snooze")
def snooze_alert(alert_id: str, payload: AlertSnoozeRequest, db: Session = Depends(get_db)):
    alert = db.get(Alert, alert_id)
    if alert is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Alert not found")

    alert.snoozed_until = now_utc() + timedelta(minutes=payload.duration_minutes)
    db.commit()
    return {"id": alert.id, "snoozed_until": as_utc(alert.snoozed_until).isoformat()}


@app.post("/api/v1/alerts/seed")
def seed_alerts(payload: AlertSeedRequest, db: Session = Depends(get_db)):
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
def get_recommendations(db: Session = Depends(get_db)):
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
def apply_mitigation(
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

    return {
        "id": mitigation.id,
        "status": mitigation.status,
        "applied_at": as_utc(mitigation.applied_at).isoformat(),
    }


@app.get("/api/v1/manager/queue")
def manager_queue(
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
    for alert in alerts:
        created = as_utc(alert.created_at) or now
        elapsed_minutes = max(int((now - created).total_seconds() / 60), 0)
        target_minutes = _severity_sla_minutes(alert.severity)
        is_breached = alert.status == "active" and elapsed_minutes > target_minutes
        if is_breached:
            breached += 1

        owner = assignments.get(alert.id)
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
def assign_alert(
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
def manager_approval_decision(
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
    db: Session = Depends(get_db),
):
    require_role(authorization, db, {"admin"})
    logs = db.scalars(select(AuditLog).order_by(AuditLog.created_at.desc())).all()
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
        ]
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
