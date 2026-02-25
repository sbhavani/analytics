# Implementation Plan: Webhook Notifications

**Branch**: `002-webhook-notifications` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-webhook-notifications/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add a webhook notification system that sends HTTP POST events when configured triggers occur (e.g., spike in visitors, goal completions). The system will allow users to configure webhook endpoints, select event types to monitor, and receive authenticated payloads with retry logic for failed deliveries.

## Technical Context

**Language/Version**: Elixir (Phoenix framework - per project constitution)
**Primary Dependencies**: Phoenix, PostgreSQL, ClickHouse, Oban (background jobs), HTTPoison (HTTP requests)
**Storage**: PostgreSQL for webhook configurations and delivery logs; ClickHouse for analytics queries
**Testing**: ExUnit (as per constitution)
**Target Platform**: Linux server (web service)
**Project Type**: web-service (Phoenix web application)
**Performance Goals**: 95% webhook delivery within 30 seconds of triggering event; support 10 webhooks per site
**Constraints**: Privacy-first - no PII in webhook payloads; must use existing authentication system for permissions
**Scale/Scope**: 10 webhooks per site; up to multiple concurrent users configuring webhooks

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gate 1: Privacy-First Development
**Status**: PASS (with constraints)
- Webhook payloads will contain only aggregate analytics data (visitor counts, goal names, timestamps)
- No personally identifiable information (PII) will be included in payloads
- Users configure which events trigger webhooks, controlling what data leaves their system

### Gate 2: Test-Driven Development (NON-NEGOTIABLE)
**Status**: PASS
- All new modules require ExUnit tests written before implementation
- Integration tests required for database operations
- Contract tests required for API boundaries (webhook payloads)

### Gate 3: Performance as a Feature
**Status**: PASS
- Target: 95% delivery within 30 seconds (from spec SC-002)
- Async delivery via Oban worker prevents blocking main request flow
- Retry with exponential backoff handles transient failures

### Gate 4: Observability and Debuggability
**Status**: PASS
- Structured logging required for all webhook operations
- Delivery status tracked in database for debugging
- Error tracking with context for failed deliveries

### Gate 5: Simplicity and YAGNI
**Status**: PASS
- Start with basic HTTP POST delivery (no message queues initially)
- Use existing TrafficChangeNotification pattern as foundation
- Reuse existing authentication/authorization system

## Project Structure

### Documentation (this feature)

```text
specs/002-webhook-notifications/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── plausible/
│   ├── webhooks/              # NEW: Webhook business logic
│   │   └── webhooks.ex        # Context module for CRUD operations
│   ├── site/
│   │   ├── webhook.ex         # NEW: Webhook schema (similar to TrafficChangeNotification)
│   │   └── webhook_delivery.ex # NEW: Delivery log schema
│   └── ...
├── workers/
│   ├── deliver_webhook.ex     # NEW: Oban worker for async delivery
│   └── ...
└── plausible_web/
    ├── controllers/
    │   └── webhook_controller.ex  # NEW: UI for webhook management
    └── live/
        └── webhook_settings.ex   # NEW: LiveView for webhook configuration

priv/repo/migrations/
├── 20260225_create_webhooks.exs           # NEW: Webhook configs table
└── 20260225_create_webhook_deliveries.exs # NEW: Delivery log table

test/
├── plausible/
│   └── webhooks_test.exs        # NEW: Unit tests
├── workers/
│   └── deliver_webhook_test.exs # NEW: Worker tests
└── plausible_web/
    └── controllers/
        └── webhook_controller_test.exs # NEW: Controller tests
```

**Structure Decision**: Webhooks follow existing Plausible patterns:
- Schema in `lib/plausible/site/` (similar to `TrafficChangeNotification`)
- Business logic context in new `lib/plausible/webhooks.ex`
- Background delivery via Oban worker in `lib/workers/`
- UI via LiveView in `lib/plausible_web/live/`
- Tests colocated with implementation following project conventions

## Complexity Tracking

**Status**: No complexity violations

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | No additional complexity beyond core feature requirements | N/A |

All constitutional gates pass without requiring additional complexity.
