# Webhook Delivery Contract

## Outbound: HTTP POST to Configured Endpoint

### Headers

| Header | Value | Required |
|--------|-------|----------|
| Content-Type | application/json | Yes |
| X-Signature | sha256=<hmac_signature> | Yes |
| X-Webhook-Event | goal_completion \| visitor_spike | Yes |
| User-Agent | Plausible/Analytics | Yes |

### Payload Schema

```json
{
  "event_id": "uuid",
  "event_type": "goal_completion | visitor_spike",
  "site_id": "uuid",
  "site_name": "string",
  "timestamp": "ISO8601 datetime",
  "data": {
    // Event-specific payload
  }
}
```

### Event Types

#### goal_completion

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_type": "goal_completion",
  "site_id": "660e8400-e29b-41d4-a716-446655440001",
  "site_name": "Example Site",
  "timestamp": "2026-02-25T14:30:00Z",
  "data": {
    "goal_id": "770e8400-e29b-41d4-a716-446655440002",
    "goal_name": "Sign up",
    "goal_type": "page | custom_event",
    "path": "/signup",
    "visitor_id": "880e8400-e29b-41d4-a716-446655440003"
  }
}
```

#### visitor_spike

```json
{
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "event_type": "visitor_spike",
  "site_id": "660e8400-e29b-41d4-a716-446655440001",
  "site_name": "Example Site",
  "timestamp": "2026-02-25T14:30:00Z",
  "data": {
    "current_visitors": 150,
    "previous_visitors": 80,
    "percentage_increase": 87.5,
    "threshold_configured": 50,
    "triggered": true
  }
}
```

### Signature Calculation

HMAC-SHA256 of the JSON payload using the shared secret:

```
signature = HMAC-SHA256(payload_json, secret)
```

Example:
```
secret = "mysecret123"
payload = {"event_id":"550e8400-..."}
signature = "a1b2c3d4e5f6..."
header = "X-Signature: sha256=a1b2c3d4e5f6..."
```

---

## Inbound: Webhook Configuration API

### Create Webhook

**Endpoint**: `POST /api/sites/:site_id/webhooks`

```json
{
  "url": "https://example.com/webhook",
  "secret": "your_shared_secret_min_16_chars",
  "enabled": true,
  "triggers": ["goal_completion", "visitor_spike"],
  "thresholds": {
    "visitor_spike": 50
  }
}
```

### Update Webhook

**Endpoint**: `PATCH /api/sites/:site_id/webhooks/:id`

Same payload as create (all fields optional).

### Delete Webhook

**Endpoint**: `DELETE /api/sites/:site_id/webhooks/:id`

No body.

### List Webhooks

**Endpoint**: `GET /api/sites/:site_id/webhooks`

Response:
```json
{
  "webhooks": [
    {
      "id": "uuid",
      "url": "https://example.com/webhook",
      "enabled": true,
      "triggers": ["goal_completion"],
      "thresholds": {},
      "created_at": "2026-02-25T14:00:00Z"
    }
  ]
}
```

### Get Delivery History

**Endpoint**: `GET /api/sites/:site_id/webhooks/:id/deliveries`

Response:
```json
{
  "deliveries": [
    {
      "id": "uuid",
      "event_type": "goal_completion",
      "status": "success",
      "response_code": 200,
      "attempt_number": 1,
      "timestamp": "2026-02-25T14:30:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 100
  }
}
```
