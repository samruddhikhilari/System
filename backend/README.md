# Local Backend (Real API)

This backend is a real, database-backed FastAPI service for your Flutter app.
It implements:
- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/organizations`
- `GET /api/v1/health`

Data is persisted in `backend/app.db` (SQLite).

## 1) Setup

From project root:

```powershell
cd backend
python -m venv .venv
.\.venv\Scripts\python -m pip install --upgrade pip
.\.venv\Scripts\python -m pip install -r requirements.txt
```

## 2) Start backend

```powershell
cd backend
.\.venv\Scripts\python -m uvicorn main:app --host 127.0.0.1 --port 8000
```

When running, health check:

```powershell
Invoke-WebRequest http://127.0.0.1:8000/api/v1/health
```

## 3) Start Flutter frontend

Open another terminal in project root:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

## Notes

- Default seeded organizations:
  - `111` (Demo Organization)
  - `222` (Supply Ops Group)
- For registration form, use Organization ID `111`.
