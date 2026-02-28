# N-SCRRA Demo (Flutter + FastAPI)

This repository contains:
- Flutter frontend app (web/desktop/mobile-ready)
- Local FastAPI backend with SQLite for authentication + dashboard/alerts/risk/network APIs

## Prerequisites

- Flutter SDK (stable)
- Python 3.10+
- Chrome (for web run) or Windows desktop toolchain

## Installation

### 1) Frontend dependencies

Run from repository root:

```powershell
flutter pub get
```

### 2) Backend dependencies

Run from repository root:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python -m pip install --upgrade pip
.\.venv\Scripts\python -m pip install -r requirements.txt
```

## Execution

### 1) Start backend (Terminal 1)

```powershell
cd backend
.\.venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

Backend health check:

```powershell
Invoke-WebRequest http://127.0.0.1:8000/api/v1/health
```

### 2) Start Flutter app (Terminal 2)

From repository root:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

For Windows desktop:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Seeded Test Data

- Organizations:
	- `111` → Demo Organization
	- `222` → Supply Ops Group

Use Organization ID `111` while registering a new user.

## Common Troubleshooting

### Port 8000 already in use

```powershell
Get-NetTCPConnection -LocalPort 8000 -State Listen
Stop-Process -Id <PID> -Force
```

### Backend not reachable

- Ensure backend terminal is running.
- Verify health endpoint returns `200 OK`.
- Ensure Flutter is started with correct `API_BASE_URL`.

### Clean rebuild

```powershell
flutter clean
flutter pub get
```

## Backend Details

Detailed backend notes are available in [backend/README.md](backend/README.md).



### System flow 
Role-wise Product Flow (One-page Deck Version)

1) Risk Analyst (Daily Operator)

Login and open Dashboard to review NRI, active alerts, and top-risk sectors/routes.
Open Alert Center, triage each alert: Ack if taking ownership, Snooze if waiting for more data.
Drill into Risk Intelligence + Network Map to find impacted suppliers/lanes and probable cause.
Run Simulation/Recommendations to choose mitigation (alternate supplier, reroute, safety stock).
Trigger action and monitor whether risk drops in next cycle.
2) Risk Manager (Decision Maker)

Review team queue: acknowledged vs pending alerts and SLA breaches.
Validate high-impact mitigations (cost vs service risk) from simulations.
Approve escalation for critical disruptions and assign owners.
Track weekly trend in risk reduction, response time, and recurring hotspots.
3) Admin (Governance & Control)

Configure organizations, user roles, and access permissions.
Set alert preferences/thresholds by severity and business criticality.
Ensure auditability: who acknowledged what, when, and outcome.
Maintain integrations/data health and policy compliance settings.



Start backend and login with seeded roles: admin@demo.com / Admin@123, manager@demo.com / Manager@123.
