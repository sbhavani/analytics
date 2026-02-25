# Quickstart: Webhook Notifications

## Implementation Overview

This document provides a high-level guide for implementing webhook notifications. See `data-model.md` for entity details and `contracts/webhook-payload.md` for payload format.

## Key Components

### 1. Database Schema

Create three new tables:
- `webhooks` - Webhook configurations
- `webhook_triggers` - Trigger types per webhook
- `webhook_deliveries` - Delivery attempt log

Reference: `lib/plausible/site/traffic_change_notification.ex` for existing pattern.

### 2. Background Worker

Create Oban worker at `lib/workers/deliver_webhook.ex`:

```elixir
# Queue: :webhooks
# Retry: 3 attempts with exponential backoff
```

Reference: `lib/workers/traffic_change_notifier.ex` for existing pattern.

### 3. Site Controller Actions

Add to `lib/plausible_web/controllers/site_controller.ex`:
- `create_webhook` - POST /sites/:domain/webhooks
- `list_webhooks` - GET /sites/:domain/webhooks
- `update_webhook` - PUT /sites/:domain/webhooks/:id
- `delete_webhook` - DELETE /sites/:domain/webhooks/:id
- `test_webhook` - POST /sites/:domain/webhooks/:id/test

Reference: Existing `enable_traffic_change_notification` actions.

### 4. HTTP Delivery

Use existing HTTP client pattern:
- `Req` library (modern Elixir)
- Follow redirects (max 3)
- Set reasonable timeout (10s)
- Capture response code and body

### 5. UI Components

Add to site settings UI:
- Webhook list view
- Create/edit webhook form
- Trigger configuration (goal selection, threshold)
- Test button
- Delivery status log

Reference: `lib/plausible_web/templates/site/settings_email_reports.html.heex`

## Trigger Integration Points

### Goal Completion

Hook into goal completion flow:
- Find all webhooks with `goal_completion` trigger enabled
- Queue delivery job for each

### Visitor Spike

Extend existing `TrafficChangeNotifier`:
- Add webhook delivery alongside email notification
- Or create separate worker for webhook-specific spike detection

## Testing Checklist

- [ ] Create webhook with valid HTTPS URL
- [ ] Create webhook with invalid URL (validation error)
- [ ] Enable/disable triggers
- [ ] Goal completion triggers webhook
- [ ] Visitor spike triggers webhook
- [ ] Test webhook sends successfully
- [ ] Failed delivery retries correctly
- [ ] Signature verification works
- [ ] Delete webhook stops deliveries

## Performance Considerations

- Webhook delivery is async (Oban queue)
- Batch deliveries if high volume
- Consider delivery timeout (10s default)
- Log all delivery attempts for debugging
