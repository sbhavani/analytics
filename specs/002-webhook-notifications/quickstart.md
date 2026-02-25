# Quickstart: Webhook Notifications

**Feature**: Webhook Notifications for Plausible Analytics
**Date**: 2026-02-25
**Phase**: 1 - Quickstart Guide

---

## Overview

This guide helps developers get started with implementing webhook notifications in Plausible Analytics.

## Prerequisites

- Elixir/Erlang environment set up
- Access to Plausible codebase
- Understanding of:
  - Phoenix framework
  - Ecto (database)
  - Oban (background jobs)

---

## Architecture Overview

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Event Occurs  │────▶│  Enqueue Job    │────▶│  Oban Worker    │
│ (Goal/Spike)   │     │  (immediate)    │     │  (async)        │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                                         │
                                                         ▼
                                              ┌─────────────────────┐
                                              │  HTTP POST Delivery │
                                              │  + Status Logging   │
                                              └─────────────────────┘
```

---

## Key Components

### 1. Schema: `Plausible.Site.Webhook`

- Located: `lib/plausible/site/webhook.ex`
- Purpose: Store webhook configurations

```elixir
# Example usage
%Plausible.Site.Webhook{
  site_id: site.id,
  url: "https://example.com/webhook",
  secret: "my-secret-key",
  name: "Production Webhook",
  events: ["goal_completion", "visitor_spike"],
  enabled: true
}
```

### 2. Context: `Plausible.Webhooks`

- Located: `lib/plausible/webhooks.ex`
- Purpose: CRUD operations for webhooks

```elixir
# Create webhook
Plausible.Webhooks.create(site, %{
  url: "https://example.com/webhook",
  events: ["goal_completion"]
})

# List webhooks for site
Plausible.Webhooks.list(site)

# Delete webhook
Plausible.Webhooks.delete(webhook)
```

### 3. Worker: `Plausible.Workers.DeliverWebhook`

- Located: `lib/workers/deliver_webhook.ex`
- Purpose: Async HTTP delivery with retry

```elixir
# Enqueue delivery
Plausible.Workers.DeliverWebhook.new(%{
  webhook_id: webhook.id,
  event_type: "goal_completion",
  payload: %{...}
})
|> Oban.insert!()
```

---

## Database Schema

Two tables needed:

1. **webhooks** - Webhook configurations
2. **webhook_deliveries** - Delivery log

```sql
-- webhooks table
CREATE TABLE webhooks (
  id UUID PRIMARY KEY,
  site_id UUID REFERENCES sites(id),
  url VARCHAR(500) NOT NULL,
  secret VARCHAR(64),
  name VARCHAR(100),
  events JSONB NOT NULL,
  enabled BOOLEAN DEFAULT true,
  failure_threshold INTEGER DEFAULT 3,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);

-- webhook_deliveries table
CREATE TABLE webhook_deliveries (
  id UUID PRIMARY KEY,
  webhook_id UUID REFERENCES webhooks(id),
  event_type VARCHAR(50) NOT NULL,
  payload JSONB NOT NULL,
  status VARCHAR(20) NOT NULL,
  response_code INTEGER,
  attempts INTEGER DEFAULT 0,
  next_retry_at TIMESTAMP,
  inserted_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

---

## Testing Webhooks

### Manual Test

```bash
# Send test webhook via curl
curl -X POST https://your-endpoint.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"event":"test","site_id":"test.com","timestamp":"2026-01-01T00:00:00Z","data":{}}'
```

### Unit Tests

```elixir
# test/plausible/webhooks_test.exs
defmodule Plausible.WebhooksTest do
  use Plausible.DataCase

  test "creates webhook for site" do
    site = insert(:site)
    {:ok, webhook} = Plausible.Webhooks.create(site, %{
      url: "https://example.com/hook",
      events: ["goal_completion"]
    })
    assert webhook.url == "https://example.com/hook"
  end
end
```

---

## Common Tasks

### Add New Event Type

1. Update `events` validation in `Webhook` schema
2. Add payload builder in `Webhooks` context
3. Update contract documentation
4. Add event trigger in relevant module

### Modify Payload Format

1. Update contract in `contracts/webhook-payload.md`
2. Modify payload builder in `Webhooks` context
3. Add tests for new format

---

## Configuration

Webhooks can be configured via application config:

```elixir
# config/runtime.exs
config :plausible, :webhooks,
  max_per_site: 10,
  retry_backoff: [1, 5, 15],  # minutes
  timeout: 30_000  # milliseconds
```

---

## Troubleshooting

### Webhook Not Sending

1. Check webhook is enabled
2. Verify URL is valid
3. Check delivery logs for errors
4. Ensure events are configured

### Signature Verification Fails

1. Confirm secret matches in config
2. Verify HMAC computation
3. Check for URL encoding issues

### Deliveries Always Failing

1. Check endpoint is reachable
2. Verify SSL certificate
3. Review response codes in delivery log

---

## Next Steps

1. Run migrations to create tables
2. Implement context module
3. worker
 Create background4. Add UI for webhook management
5. Integrate event triggers
