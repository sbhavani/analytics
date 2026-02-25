# Data Model: Webhook Notifications

## Entities

### WebhookConfiguration

Represents a user's configured webhook endpoint.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| site_id | UUID | Foreign Key (sites), Not Null | Owner site |
| url | String | Not Null, URL Format | Endpoint URL |
| secret | String | Not Null | Shared secret for HMAC signing |
| enabled | Boolean | Default: true | Whether webhook is active |
| triggers | JSON | Not Null | Array of enabled trigger types |
| thresholds | JSON | Nullable | Per-trigger threshold settings |
| inserted_at | DateTime | Not Null | Creation timestamp |
| updated_at | DateTime | Not Null | Last modification timestamp |

**Triggers Enum**: `["goal_completion", "visitor_spike"]`

---

### WebhookDelivery

Tracks each webhook delivery attempt.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_config_id | UUID | Foreign Key, Not Null | Reference to configuration |
| event_type | String | Not Null | Type of trigger event |
| payload | JSON | Not Null | Event data sent |
| status | Enum | Not Null | `pending`, `success`, `failed` |
| response_code | Integer | Nullable | HTTP response code |
| error_message | String | Nullable | Error details if failed |
| attempt_number | Integer | Not Null, Default: 1 | Retry attempt count |
| inserted_at | DateTime | Not Null | Delivery timestamp |

---

### TriggerEvent

Represents an event that could fire a webhook (logical entity, not persisted).

| Field | Type | Description |
|-------|------|-------------|
| event_id | UUID | Unique event identifier |
| event_type | String | Type (goal_completion, visitor_spike) |
| site_id | UUID | Associated site |
| timestamp | DateTime | When event occurred |
| data | JSON | Event-specific payload |

---

## Relationships

```
Site (1) ──< (N) WebhookConfiguration
WebhookConfiguration (1) ──< (N) WebhookDelivery
```

---

## Validation Rules

1. **URL**: Must be valid HTTP/HTTPS URL, max 2048 characters
2. **Secret**: Must be minimum 16 characters, alphanumeric + special chars
3. **Triggers**: Must contain at least one valid trigger type when enabled
4. **Thresholds**: For visitor_spike, must be positive integer (percentage)

---

## State Transitions

### WebhookConfiguration

```
Draft → Active (enabled = true)
Active → Disabled (enabled = false)
Disabled → Active
Any → Deleted (soft delete via deleted_at)
```

### WebhookDelivery

```
pending → success (2xx response)
pending → failed (non-2xx or timeout after all retries)
```
