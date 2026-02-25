# Research: Webhook Notifications

**Feature**: Webhook Notifications for Plausible Analytics
**Date**: 2026-02-25
**Phase**: 0 - Research

## Existing Patterns in Codebase

### 1. Traffic Change Notifications

The existing `TrafficChangeNotification` system provides the foundational pattern:

**Schema** (`lib/plausible/site/traffic_change_notification.ex`):
- Stores configuration per site (site_id)
- Tracks threshold values
- Records last_sent timestamp for rate limiting

**Worker** (`lib/workers/traffic_change_notifier.ex`):
- Runs on schedule via Oban
- Queries for sites needing notifications
- Sends email notifications
- Updates last_sent on success

**Key Insight**: Webhooks will follow this same pattern but:
- Send HTTP POST instead of email
- Support multiple webhook configs per site (vs single notification config)
- Include delivery status tracking
- Support multiple event types

### 2. HTTP Client Usage

**Pattern Found** (`lib/plausible/http_client.ex`):
- Uses HTTPoison for HTTP requests
- Follows Elixir conventions for request/response

### 3. Site-scoped Features

**Pattern from Goals** (`lib/plausible/goals/goals.ex`):
- Context module for business logic
- CRUD operations scoped to site
- Authorization via site ownership

## Decision: Webhook Delivery Architecture

### Approach: Oban Worker with Immediate Dispatch

1. **Trigger Events**: When analytics events occur (goal completion, visitor spike detected), enqueue webhook delivery job
2. **Async Delivery**: Oban worker processes delivery in background
3. **Retry Logic**: Exponential backoff for failed deliveries (up to 3 retries)
4. **Status Tracking**: Log each delivery attempt in database

### Why This Approach?

- **Simplicity**: Leverages existing Oban infrastructure (same as TrafficChangeNotifier)
- **Reliability**: Failed deliveries can be retried automatically
- **Performance**: Non-blocking - webhook delivery doesn't slow down main analytics ingestion
- **Observability**: Delivery status stored for debugging

### Alternatives Considered

| Alternative | Why Rejected |
|-------------|--------------|
| Immediate HTTP call in request | Blocks main thread, risk of timeouts |
| External message queue | Adds unnecessary complexity - Oban sufficient |
| Database polling | Less efficient than event-driven approach |

## Decision: Event Types

### Supported Events (from spec FR-006)

1. **Goal Completions**: When a configured goal is completed
2. **Visitor Spike**: When current visitors exceed threshold
3. **Custom Events**: When specific custom events occur
4. **Error Conditions**: When analytics errors detected

### Implementation Note

The spike detection already exists in `TrafficChangeNotifier`. Webhooks will:
- Reuse spike detection logic
- Add new triggers for goals and custom events

## Decision: Payload Format

### Webhook Payload Structure

```json
{
  "event": "goal_completion",
  "site_id": "example.com",
  "timestamp": "2026-02-25T12:00:00Z",
  "data": {
    "goal_name": "Signup",
    "visitor_count": 1,
    "path": "/signup"
  }
}
```

### Security: HMAC Signatures

Each payload includes `X-Webhook-Signature` header:
- HMAC-SHA256 of payload using user's configured secret
- Allows recipient to verify authenticity

**Decision**: Use HMAC-SHA256 (industry standard, supported by most webhook receivers)

## Privacy Considerations

Per constitutional requirement "Privacy-First Development":

- **No PII**: Payloads contain only aggregate data (counts, names, timestamps)
- **No IP Addresses**: Not included in any webhook payload
- **User Control**: Users choose which events trigger webhooks

## Next Steps

1. Create data-model.md with schema definitions
2. Define API contracts for webhook payloads
3. Proceed to Phase 1 implementation planning
