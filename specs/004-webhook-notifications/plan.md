# Implementation Plan: Webhook Notifications

**Branch**: `004-webhook-notifications` | **Date**: 2026-02-25 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/004-webhook-notifications/spec.md`

## Summary

Add webhook notifications to Plausible Analytics: implement a webhook system that sends HTTP POST events when configured triggers occur (e.g., spike in visitors, goal completions). This feature extends the existing notification infrastructure (similar to TrafficChangeNotification) to support HTTP-based webhooks with configurable triggers.

## Technical Context

**Language/Version**: Elixir 1.16+
**Primary Dependencies**: Phoenix, Ecto, Oban, Req (HTTP client)
**Storage**: PostgreSQL (webhook configs, delivery logs)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (self-hosted)
**Project Type**: Web service / Analytics platform
**Performance Goals**: 95% webhook delivery within 30 seconds
**Constraints**: HTTPS required for webhook URLs, retry with exponential backoff (3 retries: 1s, 2s, 4s)
**Scale/Scope**: Per-site webhook configuration, supports multiple webhooks per site

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| TDD Required | PASS | Tests written before implementation per constitution |
| Privacy Impact | PASS | No personal data in webhooks (visitor data already anonymized) |
| Performance Review | PASS | Async delivery via Oban, no blocking |
| Security Review | PASS | HTTPS only, HMAC signing, no secrets in logs |

## Project Structure

### Documentation (this feature)

```
specs/004-webhook-notifications/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md       # Phase 1 output
├── contracts/          # Phase 1 output
│   └── webhook-payload.md
└── tasks.md            # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```
lib/
├── plausible/
│   ├── site/
│   │   ├── webhook.ex           # New: Webhook schema
│   │   ├── webhook_trigger.ex   # New: Trigger config
│   │   └── webhook_delivery.ex  # New: Delivery log
│   └── webhook.ex               # New: Context module
├── workers/
│   └── deliver_webhook.ex       # New: Oban worker
├── plausible_web/
│   ├── controllers/
│   │   └── site_controller.ex   # Modify: Add webhook actions
│   └── templates/
│       └── site/
│           └── settings_webhooks.html.heex  # New: UI
priv/
└── repo/
    └── migrations/
        └── * _create_webhooks.exs  # New: Migrations
test/
├── plausible/
│   └── webhook_test.ex        # New: Unit tests
└── plausible_web/
    └── controllers/
        └── webhook_controller_test.ex  # New: Controller tests
```

**Structure Decision**: Follow existing Plausible patterns:
- Schema in `lib/plausible/site/` (matching `traffic_change_notification.ex`)
- Context functions in `lib/plausible/webhook.ex` (new module)
- Controller modifications in existing site controller
- Oban worker in `lib/workers/` (matching existing workers)
- Migrations in `priv/repo/migrations/`

## Complexity Tracking

No complexity violations. Using established patterns:
- Site-level configuration (matches existing TrafficChangeNotification)
- Oban background jobs (matches existing workers)
- Ecto schemas (matches existing patterns)

## Research Summary

See [research.md](research.md) for detailed decisions:
- Retry: 3 attempts with exponential backoff (1s, 2s, 4s)
- Scope: Per-site (matches existing notification patterns)
- HTTP Client: Req (modern Elixir HTTP)
- Queue: Separate Oban queue `:webhooks`
- Signing: HMAC-SHA256 in `X-Webhook-Signature` header

## Phase 1 Artifacts Created

- [x] `research.md` - Research findings and decisions
- [x] `data-model.md` - Entity definitions and relationships
- [x] `contracts/webhook-payload.md` - External API contract
- [x] `quickstart.md` - Implementation guide
- [x] Agent context updated

## Next Steps

Run `/speckit.tasks` to generate actionable tasks from this plan.
