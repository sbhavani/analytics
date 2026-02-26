# Quickstart: Webhook Notifications

**Feature**: Webhook Notifications (010-webhook-notifications)

## Overview

The webhook notifications feature allows site owners to receive HTTP POST notifications when specific events occur (visitor spikes, goal completions).

## Setup Steps

### 1. Database Migrations

Run the new migrations:

```bash
mix ecto.migrate
```

This creates:
- `webhooks` - Webhook endpoint configurations
- `webhook_triggers` - Trigger conditions for each webhook
- `webhook_deliveries` - Delivery attempt logs

### 2. Start Background Workers

Oban workers are automatically started with the application:
- `Plausible.Workers.CheckWebhookTriggers` - Runs every minute to check trigger conditions
- `Plausible.Workers.DeliverWebhook` - Delivers webhook payloads with retry logic

### 3. Configure Webhooks

Navigate to Site Settings > Webhooks in the Plausible UI to:
- Add a new webhook (URL, name, secret)
- Configure triggers (visitor spike threshold or goal completion)
- Test the webhook configuration
- View delivery history

## Configuration

### Environment Variables

No new environment variables required. Uses existing infrastructure:
- `DATABASE_URL` - PostgreSQL connection
- `FINCH_POOL_SIZE` - HTTP client pool (default: 10)

### Oban Queues

The webhook system uses the `webhooks` queue:

```elixir
# config/runtime.exs
config :plausible, Oban,
  queues: [
    default: 10,
    spike_notifications: 5,
    webhooks: 20  # Dedicated queue for webhook delivery
  ]
```

## Testing

### Run Tests

```bash
# Backend tests
mix test test/plausible/site/webhook_test.exs
mix test test/workers/deliver_webhook_test.exs

# Frontend tests
npm test -- --testPathPattern=Webhooks
```

### Manual Testing

1. Create a webhook in the UI pointing to a test endpoint (e.g., https://webhook.site)
2. Add a trigger (e.g., visitor_spike with threshold of 10)
3. Generate traffic to trigger the condition
4. Verify webhook delivery in the webhook logs

### Test Webhook

Use the "Send Test Webhook" button in the UI to verify:
- Connectivity to the endpoint
- Proper payload format
- HMAC signature validation

## Verification Checklist

- [ ] Migrations run successfully
- [ ] Webhook can be created via UI
- [ ] Trigger conditions are evaluated
- [ ] Webhook payloads are delivered
- [ ] Retry logic works for failures
- [ ] Delivery logs are recorded
- [ ] Test webhook function works
- [ ] HTTPS validation enforced
- [ ] HMAC signature included in headers
