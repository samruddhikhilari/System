from __future__ import annotations

import uuid
import os
import base64
import hashlib
import hmac
from datetime import datetime, timedelta, timezone
from typing import Optional

from fastapi import Depends, FastAPI, Header, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
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


DATABASE_URL = "sqlite:///./app.db"
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


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


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
            "permissions": ["read:dashboard", "write:alerts", "read:profile"],
            "selected_org_id": membership.org_id,
            "created_at": user.created_at.isoformat(),
            "last_login_at": user.last_login_at.isoformat() if user.last_login_at else None,
        },
        "permissions": ["read:dashboard", "write:alerts", "read:profile"],
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
        and (row.snoozed_until is None or row.snoozed_until <= current_time)
    ]

    return [
        {
            "id": row.id,
            "severity": row.severity,
            "title": row.title,
            "body": row.body,
            "supplier_id": row.supplier_id,
            "timestamp": row.created_at.isoformat(),
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
    return {"id": alert.id, "snoozed_until": alert.snoozed_until.isoformat()}


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
