# Webhook API Contract

**Feature**: Webhook Notifications
**Date**: 2026-02-25

## API Endpoints

All endpoints require authentication via session cookie. Site ownership is verified via the `site_id` parameter.

### Base Path
`/api/sites/:site_id/webhooks`

---

## Endpoints

### 1. List Webhooks

**GET** `/api/sites/:site_id/webhooks`

Returns all webhooks for a site.

**Response** (200 OK):
```json
{
  "webhooks": [
    {
      "id": "uuid",
      "url": "https://example.com/webhook",
      "name": "Production Webhook",
      "active": true,
      "triggers": [
        {
          "id": "uuid",
          "type": "visitor_spike",
          "threshold": 50
        },
        {
          "id": "uuid",
          "type": "goal_completion",
          "goal_id": "uuid"
        }
      ],
      "inserted_at": "2026-02-25T10:00:00Z",
      "updated_at": "2026-02-25T10:00:00Z"
    }
  ]
}
```

---

### 2. Create Webhook

**POST** `/api/sites/:site_id/webhooks`

Creates a new webhook with triggers.

**Request Body**:
```json
{
  "url": "https://example.com/webhook",
  "name": "Production Webhook",
  "secret": "optional-secret-key",
  "triggers": [
    {
      "type": "visitor_spike",
      "threshold": 50
    },
    {
      "type": "goal_completion",
      "goal_id": "uuid (optional)"
    }
  ]
}
```

**Validation**:
- `url`: Required, HTTPS only, max 2048 chars
- `name`: Required, max 255 chars
- `secret`: Optional, min 16 chars if provided
- `triggers`: Required, at least one trigger

**Response** (201 Created):
```json
{
  "webhook": {
    "id": "uuid",
    "url": "https://example.com/webhook",
    "name": "Production Webhook",
    "active": true,
    "triggers": [...],
    "inserted_at": "2026-02-25T10:00:00Z",
    "updated_at": "2026-02-25T10:00:00Z"
  }
}
```

**Error Responses**:
- 400: Invalid request body
- 403: User does not own site
- 422: Validation error (invalid URL, max webhooks exceeded)

---

### 3. Get Webhook

**GET** `/api/sites/:site_id/webhooks/:id`

Returns a single webhook with its triggers.

**Response** (200 OK):
```json
{
  "webhook": {
    "id": "uuid",
    "url": "https://example.com/webhook",
    "name": "Production Webhook",
    "active": true,
    "secret": false,
    "triggers": [...],
    "inserted_at": "2026-02-25T10:00:00Z",
    "updated_at": "2026-02-25T10:00:00Z"
  }
}
```

---

### 4. Update Webhook

**PUT** `/api/sites/:site_id/webhooks/:id`

Updates webhook configuration. Partial updates supported.

**Request Body** (any subset):
```json
{
  "url": "https://example.com/new-webhook",
  "name": "Updated Name",
  "active": false,
  "secret": "new-secret-key"
}
```

**Response** (200 OK):
```json
{
  "webhook": {
    "id": "uuid",
    "url": "https://example.com/new-webhook",
    "name": "Updated Name",
    "active": false,
    ...
  }
}
```

---

### 5. Delete Webhook

**DELETE** `/api/sites/:site_id/webhooks/:id`

Deletes a webhook and all associated triggers and delivery records.

**Response** (204 No Content)

---

### 6. Add Trigger

**POST** `/api/sites/:site_id/webhooks/:id/triggers`

Adds a new trigger to an existing webhook.

**Request Body**:
```json
{
  "type": "goal_completion",
  "goal_id": "uuid (optional)"
}
```

**Response** (201 Created):
```json
{
  "trigger": {
    "id": "uuid",
    "type": "goal_completion",
    "goal_id": "uuid",
    "inserted_at": "2026-02-25T10:00:00Z"
  }
}
```

---

### 7. Remove Trigger

**DELETE** `/api/sites/:site_id/webhooks/:id/triggers/:trigger_id`

Removes a trigger from a webhook.

**Response** (204 No Content)

---

### 8. List Delivery History

**GET** `/api/sites/:site_id/webhooks/:id/deliveries`

Returns delivery history for a webhook.

**Query Parameters**:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 20, max: 100)

**Response** (200 OK):
```json
{
  "deliveries": [
    {
      "id": "uuid",
      "event_id": "uuid",
      "status": "success",
      "response_code": 200,
      "response_body": "OK",
      "attempt": 1,
      "trigger_type": "goal_completion",
      "inserted_at": "2026-02-25T10:00:00Z"
    },
    {
      "id": "uuid",
      "event_id": "uuid",
      "status": "failed",
      "response_code": 500,
      "error_message": "Internal Server Error",
      "attempt": 3,
      "trigger_type": "visitor_spike",
      "inserted_at": "2026-02-25T09:00:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total_pages": 5,
    "total_count": 100
  }
}
```

---

## Webhook Payload (Outbound)

When a trigger fires, the system sends an HTTP POST to the configured URL.

### Headers

```
Content-Type: application/json
X-Webhook-Event-ID: uuid
X-Webhook-Event-Type: visitor_spike | goal_completion
X-Webhook-Signature: sha256=hex-digest (if secret configured)
```

### Payload Examples

**visitor_spike**:
```json
{
  "event_id": "uuid",
  "event_type": "visitor_spike",
  "site_id": "uuid",
  "site_domain": "example.com",
  "timestamp": "2026-02-25T10:00:00Z",
  "data": {
    "current_visitors": 150,
    "previous_visitors": 100,
    "change_percent": 50,
    "threshold": 50
  }
}
```

**goal_completion**:
```json
{
  "event_id": "uuid",
  "event_type": "goal_completion",
  "site_id": "uuid",
  "site_domain": "example.com",
  "timestamp": "2026-02-25T10:00:00Z",
  "data": {
    "goal_id": "uuid",
    "goal_name": "Sign up",
    "count": 5
  }
}
```

### Signature Verification

If a secret is configured, the payload is signed with HMAC-SHA256:

```
X-Webhook-Signature: sha256=<hex-digest>
```

The receiving endpoint should compute:
```
hmac_sha256(secret, payload_body)
```

And compare the hex digest with the signature header.
