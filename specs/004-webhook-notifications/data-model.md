# Data Model: Webhook Notifications

## Entities

### Webhook

Represents a configured webhook endpoint for a site.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| site_id | UUID | Foreign Key → sites | Associated site |
| url | String | Required, HTTPS only, valid URL format | Webhook endpoint URL |
| secret | String | Required, min 32 chars | Secret for HMAC-SHA256 signing |
| enabled | Boolean | Default: true | Whether webhook is active |
| created_at | NaiveDateTime | Auto | Creation timestamp |
| updated_at | NaiveDateTime | Auto | Last update timestamp |

**Relationships**:
- Belongs to Site (one-to-many: one site can have multiple webhooks)

---

### WebhookTrigger

Represents the trigger types enabled for a webhook.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key → webhooks | Parent webhook |
| trigger_type | Enum | Required: goal_completion, visitor_spike | Type of trigger |
| enabled | Boolean | Default: true | Whether this trigger is active |
| threshold | Integer | Optional, min 1 | For visitor_spike: minimum visitor count |
| created_at | NaiveDateTime | Auto | Creation timestamp |
| updated_at | NaiveDateTime | Auto | Last update timestamp |

**Relationships**:
- Belongs to Webhook (one-to-many: one webhook can have multiple triggers)

---

### WebhookDelivery

Records each attempt to deliver a webhook event.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key → webhooks | Target webhook |
| trigger_type | Enum | Required | Type of trigger that fired |
| payload | JSON | Required | Event payload sent |
| status | Enum | Required: pending, success, failed | Delivery status |
| response_code | Integer | Nullable | HTTP response code |
| response_body | String | Nullable (truncated) | Response body snippet |
| attempts | Integer | Default: 0 | Number of delivery attempts |
| next_retry_at | NaiveDateTime | Nullable | Next scheduled retry |
| delivered_at | NaiveDateTime | Nullable | When delivery succeeded |
| created_at | NaiveDateTime | Auto | Creation timestamp |

**Relationships**:
- Belongs to Webhook

---

## State Transitions

### Webhook State Machine

```
Draft → Active → Disabled → Active
                ↓
              Deleted
```

1. **Draft**: Initial creation (URL validated)
2. **Active**: Enabled and receiving events
3. **Disabled**: Manually turned off, events not sent
4. **Deleted**: Soft-deleted, can be restored within retention period

### WebhookDelivery State Machine

```
Pending → Delivering → Success
              ↓
           Failed → Retrying → Pending
              ↓
           Exhausted
```

1. **Pending**: Queued for delivery
2. **Delivering**: Currently sending HTTP request
3. **Success**: 2xx response received
4. **Failed**: Non-2xx or network error
5. **Retrying**: Scheduled for retry
6. **Exhausted**: All retries exhausted, giving up

---

## Validation Rules

### Webhook URL
- Must be valid HTTPS URL (no HTTP)
- Must not exceed 2048 characters
- Must not be a private/localhost IP (security)
- Must pass reachability check on creation (optional, can skip for test URLs)

### Webhook Secret
- Minimum 32 characters
- Maximum 256 characters
- Generated using cryptographically secure random

### Threshold (visitor_spike trigger)
- Minimum: 1
- Maximum: 10,000,000
- Default: Based on historical traffic (optional)

---

## Database Schema Notes

- Use `webhooks` table for Webhook entity
- Use `webhook_triggers` table for WebhookTrigger entity
- Use `webhook_deliveries` table for WebhookDelivery entity
- Add foreign key indexes on `site_id`, `webhook_id`
- Consider partitioning `webhook_deliveries` by date for large volume
