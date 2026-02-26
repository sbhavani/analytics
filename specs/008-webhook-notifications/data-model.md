# Data Model: Webhook Notifications

**Feature**: 008-webhook-notifications
**Date**: 2026-02-26

## Entities

### 1. Webhook Configuration

Stores webhook endpoint configuration per site.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| site_id | UUID | Foreign Key, Required | Associated site |
| url | String | Required, URL format | Webhook endpoint URL |
| secret | String | Required | HMAC secret for signature |
| enabled_events | Array[Enum] | Required | Events to send: spike, drop, goal |
| threshold | Integer | Optional | Visitor threshold for spike/drop |
| last_sent | DateTime | Nullable | Last successful delivery |
| inserted_at | DateTime | Required | Creation timestamp |
| updated_at | DateTime | Required | Last update timestamp |

**Validation Rules**:
- URL must be valid HTTP/HTTPS URL
- URL must not exceed 500 characters
- Secret must be at least 16 characters
- At least one event must be enabled
- Threshold must be >= 1 if set

**Relationships**:
- Belongs to Site (one-to-many)

---

### 2. Webhook Event

Represents a triggered notification event to be delivered.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key | Parent webhook config |
| event_type | Enum | Required | spike, drop, goal |
| payload | JSON | Required | Event-specific data |
| status | Enum | Default: pending | pending, delivered, failed |
| attempts | Integer | Default: 0 | Delivery attempt count |
| last_attempt_at | DateTime | Nullable | Last attempt timestamp |
| inserted_at | DateTime | Required | Creation timestamp |

**Payload Structure**:

*Traffic Spike/Drop*:
```json
{
  "event_type": "spike",
  "site_id": "uuid",
  "site_domain": "example.com",
  "timestamp": "ISO8601",
  "current_visitors": 150,
  "threshold": 100,
  "change_type": "spike"
}
```

*Goal Completion*:
```json
{
  "event_type": "goal",
  "site_id": "uuid",
  "site_domain": "example.com",
  "timestamp": "ISO8601",
  "goal_id": "uuid",
  "goal_name": "Signup",
  "count": 1
}
```

---

### 3. Webhook Delivery Log

Records delivery attempts for debugging.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_event_id | UUID | Foreign Key | Associated event |
| status_code | Integer | Nullable | HTTP response code |
| response_body | Text | Nullable | Response body (truncated) |
| error_message | Text | Nullable | Error if failed |
| delivered_at | DateTime | Nullable | Successful delivery time |
| inserted_at | DateTime | Required | Creation timestamp |

---

## State Transitions

### Webhook Event Status

```
pending → delivering → delivered
                  → failed (after max retries)
```

### Delivery Retry Logic

- Initial attempt: Immediate
- Retry 1: 1 minute after failure
- Retry 2: 5 minutes after failure
- Retry 3: 30 minutes after failure
- After 3 failures: Mark as failed, no further auto-retries
