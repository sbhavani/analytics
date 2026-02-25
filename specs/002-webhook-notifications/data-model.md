# Data Model: Webhook Notifications

**Feature**: Webhook Notifications for Plausible Analytics
**Date**: 2026-02-25
**Phase**: 1 - Design

## Entities

### 1. Webhook

Represents a user's configured webhook endpoint.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| site_id | UUID | Foreign Key → Site, Required | Owner site |
| url | String | Required, URL format, max 500 chars | Endpoint URL |
| secret | String | Optional, max 64 chars | HMAC signing secret |
| name | String | Optional, max 100 chars | User-friendly name |
| events | JSON Array | Required | Enabled event types |
| enabled | Boolean | Default: true | Active status |
| failure_threshold | Integer | Default: 3 | Disable after N failures |
| created_at | DateTime | Auto | Creation timestamp |
| updated_at | DateTime | Auto | Last update timestamp |

**Valid Event Types**:
- `goal_completion`
- `visitor_spike`
- `custom_event`
- `error_condition`

**Relationships**:
- Belongs to Site (one-to-many)
- Has many WebhookDeliveries (one-to-many)

---

### 2. WebhookDelivery

Tracks delivery attempts for webhook notifications.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key → Webhook, Required | Parent webhook |
| event_type | String | Required | Which event triggered |
| event_id | String | Optional | Reference to triggering event |
| payload | JSON | Required | Sent payload data |
| status | Enum | Required | delivery status |
| response_code | Integer | Optional | HTTP response code |
| response_body | String | Optional (truncated) | Response preview |
| attempts | Integer | Default: 0 | Delivery attempts |
| last_attempt_at | DateTime | Optional | Last attempt time |
| next_retry_at | DateTime | Optional | Scheduled retry |
| created_at | DateTime | Auto | Creation timestamp |

**Status Values**:
- `pending` - Awaiting delivery
- `success` - Delivered successfully
- `failed` - All retries exhausted
- `retrying` - Currently retrying

---

### 3. WebhookEvent (Reference Data)

Defines the event that triggered webhook delivery (not stored - used for payload construction).

| Field | Type | Description |
|-------|------|-------------|
| type | String | Event type (goal_completion, visitor_spike, etc.) |
| site_id | String | Site identifier |
| timestamp | DateTime | When event occurred |
| data | Map | Event-specific data |

---

## State Transitions

### Webhook State Machine

```
[Active] ----> [Disabled (by user)]
    ^
    |
[Paused (auto after failures)] ----> [Active (after manual re-enable)]
```

### Delivery State Machine

```
[Pending] --> [Retrying] --> [Success]
    |            |
    v            v
  [Failed] <----|
```

---

## Validation Rules

### Webhook Validation

1. **URL Validation**:
   - Must be valid HTTP/HTTPS URL
   - Max length: 500 characters
   - No localhost/private IPs (security)

2. **Secret Validation**:
   - Optional, but if provided: 8-64 characters
   - Alphanumeric + basic symbols only

3. **Events Validation**:
   - Must have at least 1 event type
   - All event types must be valid

### Delivery Retry Logic

- **Max Attempts**: 3
- **Backoff Schedule**: 1min, 5min, 15min (exponential)
- **Failure Threshold**: Configurable (default 3 consecutive failures → auto-disable)

---

## Database Indexes

```sql
-- Index for querying active webhooks by site
CREATE INDEX idx_webhooks_site ON webhooks (site_id) WHERE enabled = true;

-- Index for delivery status queries
CREATE INDEX idx_deliveries_webhook_status ON webhook_deliveries (webhook_id, status);

-- Index for retry queue
CREATE INDEX idx_deliveries_next_retry ON webhook_deliveries (next_retry_at)
  WHERE status = 'retrying';
```

---

## Migration Strategy

1. **Create webhooks table** - Core configuration storage
2. **Create webhook_deliveries table** - Delivery logging
3. **Add webhook association to Site schema** - ORM integration
4. **Add Oban worker** - Background delivery processing

---

## Privacy Impact

Per constitutional requirements:
- No PII in stored webhook configurations
- No IP addresses in payload data
- Payload contains only aggregate analytics data
- Secret stored encrypted at rest (use existing encryption pattern)
