# Data Model: Webhook Notifications

**Feature**: Webhook Notifications (010-webhook-notifications)

## Entities

### 1. Webhook (Plausible.Site.Webhook)

Represents a configured webhook endpoint for a site.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| site_id | UUID | Foreign Key → sites.id | Owner site |
| name | String | Required, max 255 chars | Display name for webhook |
| url | String | Required, HTTPS only, valid URL | Destination endpoint |
| secret | String | Required, max 255 chars | Shared secret for HMAC signing |
| enabled | Boolean | Default: true | Whether webhooks are sent |
| inserted_at | NaiveDateTime | Auto | Creation timestamp |
| updated_at | NaiveDateTime | Auto | Last modification timestamp |

**Relationships**:
- belongs_to :site, Plausible.Site
- has_many :triggers, Plausible.Site.WebhookTrigger
- has_many :deliveries, Plausible.Site.WebhookDelivery

### 2. WebhookTrigger (Plausible.Site.WebhookTrigger)

Defines conditions that trigger webhook delivery.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key → webhooks.id | Parent webhook |
| trigger_type | Enum | Required, values: :visitor_spike, :goal_completion | Type of event |
| threshold | Integer | Required for visitor_spike, > 0 | Trigger threshold |
| goal_id | UUID | Foreign Key → goals.id (optional) | Specific goal for goal_completion |
| enabled | Boolean | Default: true | Whether trigger is active |
| inserted_at | NaiveDateTime | Auto | Creation timestamp |

**Relationships**:
- belongs_to :webhook, Plausible.Site.Webhook
- belongs_to :goal, Plausible.Goal (optional)

**State Transitions**:
- Trigger is checked periodically by `CheckWebhookTriggers` worker
- When condition met, queues `DeliverWebhook` job for each trigger

### 3. WebhookDelivery (Plausible.Site.WebhookDelivery)

Records each webhook delivery attempt.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| webhook_id | UUID | Foreign Key → webhooks.id | Webhook config used |
| trigger_id | UUID | Foreign Key → webhook_triggers.id | Trigger that fired |
| payload | JSON | Required | Sent payload |
| status_code | Integer | Nullable | HTTP response status |
| response_body | String | Nullable | Response from endpoint |
| attempt | Integer | Default: 1 | Retry attempt number |
| success | Boolean | Required | Delivery success flag |
| error_message | String | Nullable | Error details if failed |
| inserted_at | NaiveDateTime | Auto | Delivery timestamp |

**Relationships**:
- belongs_to :webhook, Plausible.Site.Webhook
- belongs_to :trigger, Plausible.Site.WebhookTrigger

## Database Migrations

```sql
-- migrations/20260226100000_create_webhooks.ex
CREATE TABLE "webhooks" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "site_id" UUID REFERENCES "sites"("id") ON DELETE CASCADE,
  "name" VARCHAR(255) NOT NULL,
  "url" VARCHAR(2048) NOT NULL,
  "secret" VARCHAR(255) NOT NULL,
  "enabled" BOOLEAN DEFAULT true,
  "inserted_at" TIMESTAMP NOT NULL DEFAULT now(),
  "updated_at" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX "webhooks_site_id" ON "webhooks"("site_id");

-- migrations/20260226100001_create_webhook_triggers.ex
CREATE TABLE "webhook_triggers" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "webhook_id" UUID REFERENCES "webhooks"("id") ON DELETE CASCADE,
  "trigger_type" VARCHAR(50) NOT NULL,
  "threshold" INTEGER,
  "goal_id" UUID REFERENCES "goals"("id") ON DELETE SET NULL,
  "enabled" BOOLEAN DEFAULT true,
  "inserted_at" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX "webhook_triggers_webhook_id" ON "webhook_triggers"("webhook_id");
CREATE INDEX "webhook_triggers_goal_id" ON "webhook_triggers"("goal_id");

-- migrations/20260226100002_create_webhook_deliveries.ex
CREATE TABLE "webhook_deliveries" (
  "id" UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "webhook_id" UUID REFERENCES "webhooks"("id") ON DELETE CASCADE,
  "trigger_id" UUID REFERENCES "webhook_triggers"("id") ON DELETE CASCADE,
  "payload" JSONB NOT NULL,
  "status_code" INTEGER,
  "response_body" TEXT,
  "attempt" INTEGER DEFAULT 1,
  "success" BOOLEAN NOT NULL,
  "error_message" TEXT,
  "inserted_at" TIMESTAMP NOT NULL DEFAULT now()
);

CREATE INDEX "webhook_deliveries_webhook_id" ON "webhook_deliveries"("webhook_id");
CREATE INDEX "webhook_deliveries_trigger_id" ON "webhook_deliveries"("trigger_id");
CREATE INDEX "webhook_deliveries_inserted_at" ON "webhook_deliveries"("inserted_at");
```

## Validation Rules

| Entity | Rule |
|--------|------|
| Webhook.url | Must be valid HTTPS URL, max 2048 chars |
| Webhook.secret | Min 16 chars, max 255 chars |
| WebhookTrigger.threshold | Must be > 0 when trigger_type is visitor_spike |
| WebhookTrigger.goal_id | Required when trigger_type is goal_completion |
