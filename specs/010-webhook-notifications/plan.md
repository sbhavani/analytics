# Implementation Plan: Webhook Notifications

**Branch**: `010-webhook-notifications` | **Date**: 2026-02-26 | **Spec**: `specs/010-webhook-notifications/spec.md`
**Input**: Feature specification from `/specs/010-webhook-notifications/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement a webhook notification system for Plausible Analytics that sends HTTP POST events when configured triggers occur (e.g., visitor spike, goal completion). The system will extend the existing `TrafficChangeNotification` pattern to support webhook deliveries alongside email notifications, with a React-based configuration UI and background job processing via Oban.

## Technical Context

**Language/Version**: Elixir 1.15+ / Phoenix Framework
**Primary Dependencies**: Ecto (PostgreSQL), Oban (background jobs), Finch (HTTP client), React (frontend)
**Storage**: PostgreSQL (webhook configs, delivery logs) - ClickHouse not needed as triggers are evaluated in real-time
**Testing**: ExUnit for Elixir, Jest for JavaScript
**Target Platform**: Linux server (self-hosted) / Cloud SaaS
**Project Type**: Web analytics SaaS with Elixir backend + React frontend
**Performance Goals**: 100 concurrent webhook deliveries (from SC-006), 10-second test webhook feedback (from SC-004)
**Constraints**: HTTPS required for webhook URLs, 30-second max timeout per delivery
**Scale/Scope**: Multi-tenant SaaS with per-site webhook configurations

## Constitution Check

| Gate | Status | Notes |
|------|--------|-------|
| TDD Required | ✅ PASS | Tests will be written before implementation per Constitution II |
| Privacy-First | ✅ PASS | Webhooks only send event metadata (no PII), aligns with privacy principle |
| Performance Considered | ✅ PASS | Concurrent delivery target of 100 matches SC-006 |
| No Over-Engineering | ✅ PASS | Uses existing patterns (TrafficChangeNotification, Oban, HTTPClient) |
| Quality Gates | ✅ PASS | Will follow Credo, ESLint, TypeScript compilation requirements |

## Project Structure

### Documentation (this feature)

```text
specs/010-webhook-notifications/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── webhook-api.md   # Webhook payload contract
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
# Backend - Elixir/Phoenix
lib/
├── plausible/
│   ├── site/
│   │   ├── webhook.ex              # Webhook configuration schema
│   │   ├── webhook_trigger.ex      # Trigger configuration schema
│   │   └── webhook_delivery.ex     # Delivery log schema
│   └── webhooks/
│       └──.ex                      # Webhook context module
├── workers/
│   ├── check_webhook_triggers.ex   # Periodic trigger checking
│   └── deliver_webhook.ex          # Deliver webhook payload
└── plausible_web/
    ├── controllers/
    │   └── webhook_controller.ex   # UI/API controllers
    └── live/
        └── webhook_settings/
            ├── list.ex             # Webhook list LiveView
            └── form.ex             # Add/Edit webhook LiveView

priv/repo/migrations/
├── 20260226100000_create_webhooks.ex
├── 20260226100001_create_webhook_triggers.ex
└── 20260226100002_create_webhook_deliveries.ex

# Frontend - React/TypeScript
assets/
└── js/
    └── plausible/
        └── components/
            └── Settings/
                └── Webhooks/
                    ├── WebhookList.tsx
                    ├── WebhookForm.tsx
                    └── WebhookDeliveryLog.tsx

# Tests
test/
├── plausible/
│   ├── site/
│   │   ├── webhook_test.exs
│   │   └── webhook_trigger_test.exs
│   └── webhooks_test.exs
├── workers/
│   ├── check_webhook_triggers_test.exs
│   └── deliver_webhook_test.exs
└── plausible_web/
    └── webhook_settings_test.exs

assets/
└── js/
    └── components/
        └── Settings/
            └── Webhooks/
                └── WebhookList.test.tsx
```

**Structure Decision**: Uses existing Plausible project structure - backend in `lib/plausible/` and `lib/plausible_web/`, frontend in `assets/js/`. New modules follow established patterns (similar to TrafficChangeNotification, goal settings, email reports).

## Complexity Tracking

> N/A - No complexity violations. Feature uses existing patterns (TrafficChangeNotification, Oban workers, HTTPClient) without over-engineering.

---

## Phase 0: Research (Complete)

This feature leverages existing infrastructure and patterns already established in the codebase:

- **TrafficChangeNotification pattern**: Already handles site-specific notification configurations with threshold-based triggers
- **Oban workers**: Existing `TrafficChangeNotifier` demonstrates periodic checking pattern
- **HTTPClient**: Existing `Finch`-based client handles HTTP POST requests with proper error handling
- **Frontend patterns**: Similar to existing Settings > Email Reports UI

**No additional research needed** - all technical decisions are based on existing proven patterns.
