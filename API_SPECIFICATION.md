# N-SCRRA API Specification & Contracts

## Base Configuration
- **Base URL**: Configurable in `AppConfig` (dev/staging/prod)
  - Development: `http://localhost:8000/api/v1`
  - Staging: `https://staging-api.ncsrra.com/api/v1`
  - Production: `https://api.ncsrra.com/api/v1`

## Authentication Headers
All requests (except `/auth/login` and `/auth/refresh`) require:
```
Authorization: Bearer {access_token}
X-Org-ID: {organization_id}
Content-Type: application/json
```

## Endpoints Mapping

### 1. Authentication Endpoints

#### 1.1 Login
```
POST /auth/login
Request Body:
{
  "email": "user@example.com",
  "password": "securePassword123",
  "org_id": "org_12345",
  "device_id": "device_uuid",
  "fcm_token": "firebase_messaging_token"
}

Response (200 OK):
{
  "access_token": "eyJhbGc...",
  "refresh_token": "refresh_eyJhbGc...",
  "expires_in": 900,
  "token_type": "Bearer",
  "user_profile": {
    "id": "user_123",
    "email": "user@example.com",
    "name": "John Doe",
    "role": "analyst",
    "organization": {
      "id": "org_12345",
      "name": "Supply Corp",
      "plan": "enterprise"
    }
  },
  "permissions": ["read:dashboard", "write:alerts", "admin:users"]
}

Errors:
- 400: Bad Request (missing fields)
- 401: Invalid credentials
- 423: Account locked (too many attempts)
- 403: Org access denied (user not member)
- 500: Server error
```

#### 1.2 Refresh Token
```
POST /auth/refresh
Request Body:
{
  "refresh_token": "refresh_eyJhbGc..."
}

Response (200 OK):
{
  "access_token": "eyJhbGc...",
  "expires_in": 900,
  "token_type": "Bearer"
}

Errors:
- 401: Invalid or expired refresh token
- 410: Refresh token revoked
```

#### 1.3 Logout
```
POST /auth/logout
Request Body:
{
  "device_id": "device_uuid"
}

Response (204 No Content):
(empty body)

Errors:
- 401: Unauthorized
```

#### 1.4 Get Organizations
```
GET /auth/organizations
Authorization: Bearer {access_token}

Response (200 OK):
[
  {
    "id": "org_12345",
    "name": "Supply Corp",
    "plan": "enterprise",
    "logo_url": "https://...",
    "members_count": 15,
    "is_active": true
  },
  {
    "id": "org_67890",
    "name": "Logistics Inc",
    "plan": "pro",
    "logo_url": "https://...",
    "members_count": 8,
    "is_active": true
  }
]

Errors:
- 401: Unauthorized
```

### 2. Dashboard Endpoints

#### 2.1 Get Dashboard Summary
```
GET /dashboard/summary?org_id={org_id}
Authorization: Bearer {access_token}
X-Org-ID: {org_id}

Query Parameters:
- org_id (required): Organization ID
- include_trends (optional): boolean, default true

Response (200 OK):
{
  "nri": {
    "score": 45,
    "zone": "moderate",
    "delta": -2.5,
    "updated_at": "2026-02-28T14:30:00Z"
  },
  "sector_risks": [
    {
      "sector": "Pharmaceuticals",
      "risk_score": 25,
      "suppliers_count": 12,
      "critical_suppliers": 2,
      "trend": "improving"
    },
    {
      "sector": "Automotive",
      "risk_score": 45,
      "suppliers_count": 23,
      "critical_suppliers": 5,
      "trend": "stable"
    }
  ],
  "alerts_summary": {
    "total": 8,
    "critical": 1,
    "high": 3,
    "medium": 2,
    "low": 2
  },
  "trend_metrics": {
    "period": "30d",
    "nri_trend": [
      {"date": "2026-02-28", "value": 45},
      {"date": "2026-02-27", "value": 44}
    ]
  }
}

Cache: 1 minute
Errors:
- 401: Unauthorized
- 403: Org access denied
- 500: Server error
```

#### 2.2 Get Sector Details
```
GET /dashboard/sectors/{sector_id}?org_id={org_id}
Authorization: Bearer {access_token}

Path Parameters:
- sector_id: Sector identifier

Query Parameters:
- org_id (required): Organization ID

Response (200 OK):
{
  "id": "sector_pharma",
  "name": "Pharmaceuticals",
  "risk_score": 25,
  "risk_zone": "low",
  "suppliers": [
    {
      "id": "supplier_001",
      "name": "ChemCorp",
      "risk_score": 35,
      "location": "Germany",
      "criticality": "high"
    }
  ],
  "risk_factors": [
    {
      "name": "Geographic concentration",
      "impact": "medium",
      "trend": "improving"
    }
  ]
}

Cache: 5 minutes
Errors:
- 401: Unauthorized
- 404: Sector not found
```

### 3. Supplier Endpoints

#### 3.1 Get Supplier Detail
```
GET /suppliers/{supplier_id}?org_id={org_id}
Authorization: Bearer {access_token}

Path Parameters:
- supplier_id: Supplier UUID

Query Parameters:
- org_id (required): Organization ID
- include_dependencies (optional): boolean, default true
- include_financials (optional): boolean, default true

Response (200 OK):
{
  "id": "supplier_001",
  "name": "ChemCorp GmbH",
  "sector": "Pharmaceuticals",
  "headquarters": {
    "country": "Germany",
    "city": "Munich",
    "latitude": 48.1351,
    "longitude": 11.5820
  },
  "risk": {
    "score": 35,
    "zone": "low",
    "factors": {
      "financial": 40,
      "geopolitical": 30,
      "environmental": 25,
      "operational": 35
    }
  },
  "criticality": "high",
  "annual_spend": 2500000,
  "lead_time_days": 45,
  "dependencies": {
    "upstream": 3,
    "downstream": 8
  },
  "financials": {
    "revenue_growth_3y": 12.5,
    "debt_to_equity": 0.45,
    "interest_coverage": 4.2,
    "credit_rating": "A-"
  },
  "created_at": "2024-01-15T00:00:00Z",
  "updated_at": "2026-02-28T14:30:00Z"
}

Cache: 5 minutes
Errors:
- 401: Unauthorized
- 404: Supplier not found
```

#### 3.2 Get Supplier Dependencies
```
GET /suppliers/{supplier_id}/dependencies?org_id={org_id}
Authorization: Bearer {access_token}

Response (200 OK):
{
  "upstream": [
    {
      "id": "supplier_002",
      "name": "RawMaterials Inc",
      "relation": "primary_source",
      "criticality": "critical",
      "risk_score": 45
    }
  ],
  "downstream": [
    {
      "id": "supplier_003",
      "name": "MediPack Ltd",
      "relation": "distribution",
      "criticality": "high",
      "risk_score": 30
    }
  ]
}

Cache: 5 minutes
Errors:
- 401: Unauthorized
- 404: Supplier not found
```

### 4. Alert Endpoints

#### 4.1 Get Alerts List
```
GET /alerts?org_id={org_id}&severity={severity}&offset={offset}&limit={limit}
Authorization: Bearer {access_token}

Query Parameters:
- org_id (required): Organization ID
- severity (optional): critical|high|medium|low|info (comma-separated)
- status (optional): active|acknowledged|resolved
- offset (optional): default 0
- limit (optional): default 20, max 100

Response (200 OK):
{
  "total": 45,
  "offset": 0,
  "limit": 20,
  "items": [
    {
      "id": "alert_001",
      "title": "Supplier financial distress detected",
      "description": "ChemCorp credit rating downgraded to B+",
      "severity": "critical",
      "supplier_id": "supplier_001",
      "supplier_name": "ChemCorp",
      "type": "financial_risk",
      "status": "active",
      "action_required": true,
      "created_at": "2026-02-28T10:00:00Z",
      "updated_at": "2026-02-28T14:00:00Z",
      "acknowledged_by": null,
      "acknowledged_at": null
    }
  ]
}

Cache: 5 minutes
Errors:
- 401: Unauthorized
```

#### 4.2 Acknowledge Alert
```
PATCH /alerts/{alert_id}/acknowledge
Authorization: Bearer {access_token}
Content-Type: application/json

Request Body:
{
  "notes": "Monitoring situation closely"
}

Response (200 OK):
{
  "id": "alert_001",
  "status": "acknowledged",
  "acknowledged_at": "2026-02-28T15:00:00Z",
  "acknowledged_by": "user_123"
}

Errors:
- 401: Unauthorized
- 404: Alert not found
```

#### 4.3 Snooze Alert
```
PATCH /alerts/{alert_id}/snooze
Authorization: Bearer {access_token}

Request Body:
{
  "duration_minutes": 60,
  "reason": "Scheduled for review"
}

Response (200 OK):
{
  "id": "alert_001",
  "status": "snoozed",
  "snooze_until": "2026-02-28T16:00:00Z"
}

Errors:
- 401: Unauthorized
- 404: Alert not found
```

### 5. Risk Intelligence Endpoints

#### 5.1 Get Risk Factors
```
GET /risk/factors?org_id={org_id}&supplier_id={supplier_id}
Authorization: Bearer {access_token}

Response (200 OK):
{
  "supplier_id": "supplier_001",
  "supplier_name": "ChemCorp",
  "factors": [
    {
      "id": "factor_geographic",
      "name": "Geographic Concentration",
      "impact_score": 30,
      "category": "structural",
      "description": "70% sourcing from single country",
      "recommendations": [
        {
          "id": "rec_001",
          "text": "Diversify to EU suppliers",
          "implementation_effort": "medium",
          "roi_estimate": "high"
        }
      ]
    }
  ]
}

Cache: 10 minutes
Errors:
- 401: Unauthorized
```

#### 5.2 Run Risk Simulation (Monte Carlo)
```
POST /risk/simulate
Authorization: Bearer {access_token}
Content-Type: application/json

Request Body:
{
  "supplier_ids": ["supplier_001", "supplier_002"],
  "iterations": 1000,
  "disruption_probability": 0.15,
  "simulation_period_days": 90
}

Response (202 Accepted):
{
  "simulation_id": "sim_uuid_1234",
  "status": "queued",
  "results_url": "/risk/simulations/sim_uuid_1234/results",
  "polling_url": "/risk/simulations/sim_uuid_1234/status"
}

Errors:
- 400: Invalid parameters
- 401: Unauthorized
- 429: Too many simulations (rate limited)
```

#### 5.3 Get Simulation Results
```
GET /risk/simulations/{simulation_id}
Authorization: Bearer {access_token}

Response (200 OK):
{
  "simulation_id": "sim_uuid_1234",
  "status": "completed",
  "results": {
    "likelihood": 0.38,
    "average_impact": 450000,
    "median_impact": 350000,
    "max_impact": 2100000,
    "affected_suppliers": 1.4,
    "supply_chain_disruption_days": 23.5
  },
  "timestamp": "2026-02-28T15:30:00Z"
}

Errors:
- 401: Unauthorized
- 404: Simulation not found
- 202: Still processing
```

### 6. Reporting Endpoints

#### 6.1 Create Report
```
POST /reports
Authorization: Bearer {access_token}
Content-Type: application/json

Request Body:
{
  "title": "Q1 Supply Chain Risk Assessment",
  "report_type": "comprehensive",
  "include_sections": [
    "executive_summary",
    "nri_analysis",
    "sector_breakdown",
    "critical_suppliers",
    "risk_factors",
    "recommendations"
  ],
  "org_id": "org_12345",
  "date_range": {
    "start": "2026-01-01",
    "end": "2026-03-31"
  },
  "format": "pdf"
}

Response (201 Created):
{
  "report_id": "report_uuid_1234",
  "title": "Q1 Supply Chain Risk Assessment",
  "status": "generating",
  "created_at": "2026-02-28T15:35:00Z",
  "download_url": "/reports/report_uuid_1234/download"
}

Errors:
- 400: Invalid report type
- 401: Unauthorized
```

#### 6.2 Get Report Status
```
GET /reports/{report_id}/status
Authorization: Bearer {access_token}

Response (200 OK):
{
  "report_id": "report_uuid_1234",
  "status": "ready",
  "progress": 100,
  "file_size": 2500000,
  "file_format": "pdf",
  "expires_at": "2026-03-07T15:35:00Z",
  "download_url": "/reports/report_uuid_1234/download"
}

Errors:
- 401: Unauthorized
- 404: Report not found
```

### 7. WebSocket Events

#### 7.1 Real-time Alerts (Automatic on Connect)
```
Socket.IO Channel: /ws/alerts
Auth: Token in handshake

Events:
- "connect" → Connection established
- "alert" → New alert received
  {
    "id": "alert_001",
    "title": "...",
    "severity": "critical",
    "supplier_id": "supplier_001",
    "created_at": "2026-02-28T15:40:00Z"
  }
- "alert:acknowledged" → Alert acknowledged by another user
  {
    "alert_id": "alert_001",
    "acknowledged_by": "user_456"
  }
- "disconnect" → Connection closed
- "error" → Connection error
  {
    "message": "Authentication failed"
  }
```

## Error Response Format

All error responses follow this format:
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested supplier was not found",
    "status": 404,
    "details": {
      "supplier_id": "supplier_999",
      "org_id": "org_12345"
    },
    "timestamp": "2026-02-28T15:45:00Z"
  }
}
```

## Rate Limiting

- **Default**: 100 requests/minute per user
- **Dashboard**: 1 request/second per org
- **WebSocket**: No limit (persistent connection)
- **Reports**: 5 concurrent generations per org

Response headers:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1746028800
```

## Timeout Configuration

From `app_config.dart`:
```dart
connectTimeout: Duration(seconds: 30),
receiveTimeout: Duration(seconds: 30),
```

If exceeded, mapped to `TimeoutException` with specific type:
- Connection timeout → `TimeoutException.connectionTimeout()`
- Receive timeout → `TimeoutException.receiveTimeout()`
- Send timeout → `TimeoutException.sendTimeout()`

## Cache Durations

From `app_constants.dart`:
```dart
static const cacheDurationDashboard = Duration(minutes: 1);
static const cacheDurationAlerts = Duration(minutes: 5);
static const cacheDurationSuppliers = Duration(hours: 1);
static const cacheDurationSectors = Duration(minutes: 10);
```

Cached in Hive with keys:
- `dashboard_cache` - DashboardSummary
- `alerts_cache` - List<Alert>
- `suppliers_cache` - Map<supplierId, Supplier>
- `sector_cache` - Map<sectorId, Sector>

---
**API Version**: 1.0
**Last Updated**: February 28, 2026
**Stability**: Stable (breaking changes will increment version)
