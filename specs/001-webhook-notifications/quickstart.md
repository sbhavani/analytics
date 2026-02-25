# Quickstart: Webhook Notifications

**Feature**: Webhook Notifications
**Date**: 2026-02-25

## Overview

This guide helps developers get started with implementing webhook notifications for Plausible Analytics.

## Prerequisites

- Elixir 1.16+
- PostgreSQL (running)
- ClickHouse (running)
- Phoenix dev server running

## Implementation Steps

### 1. Database Migrations

Create migrations for webhook tables:

```bash
mix ecto.gen.migration create_webhooks
mix ecto.gen.migration create_triggers
mix ecto.gen.migration create_deliveries
```

Run migrations:
```bash
mix ecto.migrate
```

### 2. Create Ecto Schemas

Create the following schema files:
- `lib/plausible/webhooks/webhook.ex`
- `lib/plausible/webhooks/trigger.ex`
- `lib/plausible/webhooks/delivery.ex`

### 3. Create Context Module

Create `lib/plausible/webhooks/webhooks.ex` with business logic:
- CRUD operations for webhooks and triggers
- Trigger evaluation logic
- Delivery queueing

### 4. Create Oban Worker

Create `lib/workers/deliver_webhook.ex`:
- Handle async webhook delivery
- Implement retry logic with exponential backoff
- Update delivery status

### 5. Create API Controller

Create `lib/plausible_web/controllers/api/webhook_controller.ex`:
- REST endpoints for webhook management
- Input validation
- Authentication checks

### 6. Add Routes

Add routes in `lib/plausible_web/router.ex`:
```elixir
scope "/api/sites/:site_id/webhooks", PlausibleWeb.API do
  pipe_through :api

  get "/", WebhookController, :index
  post "/", WebhookController, :create
  get "/:id", WebhookController, :show
  put "/:id", WebhookController, :update
  delete "/:id", WebhookController, :delete

  post "/:id/triggers", WebhookController, :add_trigger
  delete "/:id/triggers/:trigger_id", WebhookController, :remove_trigger

  get "/:id/deliveries", WebhookController, :deliveries
end
```

### 7. Create React Components

Create UI components in `assets/js/dashboard/`:
- WebhookSettings component
- WebhookForm component
- DeliveryHistory component

### 8. Write Tests

Create test files:
- `test/plausible/webhooks/webhook_test.exs`
- `test/plausible/webhooks/delivery_test.exs`
- `test/workers/deliver_webhook_test.exs`
- `test/plausible_web/controllers/api/webhook_controller_test.exs`

## Configuration

No new configuration required. Uses existing:
- HTTPoison for HTTP requests
- Oban for background jobs
- PostgreSQL for storage
- ClickHouse for analytics queries

## Verification

Run tests:
```bash
mix test test/plausible/webhooks/
mix test test/workers/deliver_webhook_test.exs
```

Verify webhook delivery:
1. Create a webhook via API or UI
2. Trigger the condition (e.g., achieve goal, spike visitors)
3. Check delivery status in history
4. Verify HTTP POST received at endpoint

## Common Issues

### Webhook not firing
- Check webhook is active
- Verify trigger conditions are met
- Check Oban jobs are processing

### Delivery failures
- Verify endpoint URL is HTTPS
- Check secret is correct (if configured)
- Review delivery history for error messages

### Slow delivery
- Check Oban queue is processing
- Verify network connectivity to endpoint
- Review ClickHouse query performance

## Next Steps

After initial implementation:
1. Add more trigger types (e.g., pageview milestones)
2. Implement webhook payload customization
3. Add batch delivery for multiple webhooks
4. Implement dead letter queue for failed deliveries
