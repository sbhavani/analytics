# Data Model: Webhook Notifications

**Feature**: Webhook Notifications
**Date**: 2026-02-25

## Entities

### 1. Webhook

Represents a webhook endpoint configuration owned by a site.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| site_id | UUID | Foreign Key (sites), Not Null | Owner site |
| url | String | Not Null, HTTPS only, Max 2048 chars | Webhook endpoint URL |
| secret | String | Encrypted, Max 255 chars | HMAC secret for signing |
| name | String | Not Null, Max 255 chars | User-friendly name |
| active | Boolean | Default: true | Whether webhook is enabled |
| inserted_at | DateTime | Not Null | Creation timestamp |
| updated_at | DateTime | Not Null | Last update timestamp |

**Relationships**:
- Belongs to: Site (one-to-many)
- Has many: Triggers (one-to-many)
- Has many: Deliveries (one-to-many)

---

### 2. Trigger

Defines the condition that causes a webhook to fire.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key (webhooks), Not Null | Parent webhook |
| type | Enum | Not Null | Trigger type: `:visitor_spike`, `:goal_completion` |
| threshold | Integer | Required for :visitor_spike, Min 1, Max 10000 | Percentage for spike or count for goal |
| goal_id | UUID | Optional, Foreign Key (goals) | Specific goal for :goal_completion |
| inserted_at | DateTime | Not Null | Creation timestamp |
| updated_at | DateTime | Not Null | Last update timestamp |

**Relationships**:
- Belongs to: Webhook (many-to-one)
- Belongs to: Goal (optional, many-to-one)

**State Transitions**: N/A - trigger is immutable once created

---

### 3. Delivery

Tracks individual webhook dispatch attempts.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key (webhooks), Not Null | Parent webhook |
| event_id | UUID | Not Null | Unique ID for this event (for deduplication) |
| url | String | Not Null | URL that was called |
| status | Enum | Not Null | Status: `:pending`, `:success`, `:failed`, `:retrying` |
| response_code | Integer | Nullable | HTTP response code |
| response_body | String | Nullable, Max 4096 chars | Response body (truncated) |
| error_message | String | Nullable, Max 1024 chars | Error details if failed |
| attempt | Integer | Default: 1, Max: 3 | Current retry attempt |
| payload | JSONB | Not Null | The payload that was sent |
| inserted_at | DateTime | Not Null | Creation timestamp |
| updated_at | DateTime | Not Null | Last update timestamp |

**Relationships**:
- Belongs to: Webhook (many-to-one)

**State Transitions**:
```
pending -> success (HTTP 2xx)
pending -> retrying (timeout/5xx, attempt < 3)
retrying -> success (HTTP 2xx)
retrying -> failed (timeout/5xx, attempt >= 3)
pending -> failed (4xx response)
```

---

### 4. Event Payload (JSON Structure)

The JSON payload sent in the HTTP POST request.

```json
{
  "event_id": "uuid",
  "event_type": "visitor_spike | goal_completion",
  "site_id": "uuid",
  "timestamp": "ISO8601",
  "data": {
    // For visitor_spike:
    "current_visitors": 150,
    "previous_visitors": 100,
    "change_percent": 50,
    " threshold": 50

    // For goal_completion:
    "goal_id": "uuid",
    "goal_name": "Sign up",
    "count": 5
  }
}
```

---

## Validation Rules

### Webhook
- URL must be valid HTTPS URL
- URL maximum 2048 characters
- Maximum 10 webhooks per site
- Secret (if provided) must be at least 16 characters

### Trigger
- Threshold required for :visitor_spike (1-10000 percent)
- For :goal_completion, goal_id is optional (fires for all goals if not specified)
- Cannot create duplicate triggers of same type on same webhook

### Delivery
- Only one delivery per event_id per webhook (idempotency)
- Payload must be valid JSON

---

## Database Migrations Required

1. `create_webhooks_table` - Create webhooks table
2. `create_triggers_table` - Create triggers table
3. `create_deliveries_table` - Create deliveries table
4. `add_webhook_id_to_deliveries` - Foreign key (if not in create)
5. `add_site_id_to_webhooks` - Foreign key to sites

---

## Indexes

- `webhooks_site_id_idx` - For listing webhooks by site
- `triggers_webhook_id_idx` - For listing triggers by webhook
- `deliveries_webhook_id_idx` - For listing deliveries by webhook
- `deliveries_event_id_idx` - For deduplication lookup
- `deliveries_status_idx` - For retry job queries
