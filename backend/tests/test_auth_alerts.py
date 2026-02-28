import importlib
import os
import sys
import uuid
from pathlib import Path

from fastapi.testclient import TestClient

TEST_DB_PATH = Path(__file__).parent / "test_app.db"
BACKEND_ROOT = Path(__file__).resolve().parent.parent
if str(BACKEND_ROOT) not in sys.path:
    sys.path.insert(0, str(BACKEND_ROOT))

os.environ["DATABASE_URL"] = f"sqlite:///{TEST_DB_PATH.as_posix()}"

backend_main = importlib.import_module("main")
app = backend_main.app


def _register_and_login(client: TestClient) -> dict:
    email = f"qa_{uuid.uuid4().hex[:8]}@example.com"
    password = "Password@123"

    register_response = client.post(
        "/api/v1/auth/register",
        json={
            "name": "QA User",
            "email": email,
            "password": password,
            "org_id": "111",
        },
    )
    assert register_response.status_code == 201

    login_response = client.post(
        "/api/v1/auth/login",
        json={
            "email": email,
            "password": password,
            "org_id": "111",
        },
    )
    assert login_response.status_code == 200
    return login_response.json()


def test_health_endpoint():
    with TestClient(app) as client:
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"


def test_auth_register_login_and_alert_flow():
    with TestClient(app) as client:
        login_payload = _register_and_login(client)
        assert "access_token" in login_payload

        seeded = client.post("/api/v1/alerts/seed", json={"count": 3})
        assert seeded.status_code == 200
        assert seeded.json()["seeded"] == 3

        alerts_response = client.get("/api/v1/alerts")
        assert alerts_response.status_code == 200
        alerts = alerts_response.json()
        assert len(alerts) >= 1

        alert_id = alerts[0]["id"]
        ack_response = client.post(f"/api/v1/alerts/{alert_id}/acknowledge")
        assert ack_response.status_code == 200

        alerts_after_ack = client.get("/api/v1/alerts").json()
        assert all(alert["id"] != alert_id for alert in alerts_after_ack)

        if alerts_after_ack:
            snooze_id = alerts_after_ack[0]["id"]
            snooze_response = client.post(
                f"/api/v1/alerts/{snooze_id}/snooze",
                json={"duration_minutes": 30},
            )
            assert snooze_response.status_code == 200

            alerts_after_snooze = client.get("/api/v1/alerts").json()
            assert all(alert["id"] != snooze_id for alert in alerts_after_snooze)


def _login_seeded(client: TestClient, email: str, password: str, org_id: str = "111") -> str:
    response = client.post(
        "/api/v1/auth/login",
        json={
            "email": email,
            "password": password,
            "org_id": org_id,
        },
    )
    assert response.status_code == 200
    return response.json()["access_token"]


def test_simulation_recommendations_manager_admin_flow():
    with TestClient(app) as client:
        manager_token = _login_seeded(client, "manager@demo.com", "Manager@123")
        admin_token = _login_seeded(client, "admin@demo.com", "Admin@123")

        sim = client.post(
            "/api/v1/simulation/run",
            json={"iterations": 1500, "disruption_type": "supplier_failure", "region": "west"},
        )
        assert sim.status_code == 200
        assert "simulation_id" in sim.json()

        rec = client.get("/api/v1/recommendations/optimize")
        assert rec.status_code == 200
        recommendations = rec.json().get("recommendations", [])
        assert len(recommendations) >= 1

        approval_required = next(
            (item for item in recommendations if item.get("requires_approval") is True),
            None,
        )
        assert approval_required is not None

        pending = client.get(
            "/api/v1/manager/approvals",
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert pending.status_code == 200

        mitigation_id = approval_required["id"]
        approve = client.post(
            f"/api/v1/manager/approvals/{mitigation_id}/decision",
            json={"approved": True, "reason": None},
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert approve.status_code == 200
        assert approve.json()["status"] == "approved"

        apply = client.post(
            f"/api/v1/mitigations/{mitigation_id}/apply",
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert apply.status_code == 200
        assert apply.json()["status"] == "applied"

        users = client.get(
            "/api/v1/admin/users",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert users.status_code == 200
        assert len(users.json().get("users", [])) >= 1

        limiter_stats = client.get(
            "/api/v1/admin/rate-limits",
            headers={"Authorization": f"Bearer {admin_token}"},
        )
        assert limiter_stats.status_code == 200
        assert "limits" in limiter_stats.json()

        unauthorized = client.get(
            "/api/v1/admin/users",
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert unauthorized.status_code == 403

        report = client.post(
            "/api/v1/reports/generate",
            json={"period": "weekly", "output_format": "csv"},
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert report.status_code == 200
        report_id = report.json()["report_id"]

        reports = client.get(
            "/api/v1/reports",
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert reports.status_code == 200
        assert any(item["id"] == report_id for item in reports.json().get("reports", []))

        report_status = client.get(
            f"/api/v1/reports/{report_id}/status",
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert report_status.status_code == 200
        assert report_status.json()["status"] == "ready"

        report_download = client.get(
            f"/api/v1/reports/{report_id}/download",
            headers={"Authorization": f"Bearer {manager_token}"},
        )
        assert report_download.status_code == 200
        assert report_download.json()["mime_type"] in {"text/csv", "application/json"}
