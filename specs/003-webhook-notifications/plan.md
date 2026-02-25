# Implementation Plan: Webhook Notifications

**Branch**: `003-webhook-notifications` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Enable HTTP POST webhook notifications when configured triggers occur (goal completions, visitor spikes). Uses background job queue for reliable delivery with retry logic, HMAC-SHA256 payload signing for security, and provides delivery history for monitoring.

## Technical Context

**Language/Version**: Elixir 1.16+
**Primary Dependencies**: Phoenix, Ecto, Oban
**Storage**: PostgreSQL (webhook configs + delivery logs)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server
**Project Type**: Web service (Phoenix API + React frontend)
**Performance Goals**: 95% deliveries within 10 seconds, 99% availability
**Constraints**: <200ms p95 for webhook API endpoints, privacy-first (no PII in payloads)
**Scale/Scope**: Per-site webhook configs, async delivery via Oban workers

## Constitution Check

### GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.

| Principle | Status | Notes |
|-----------|--------|-------|
| Privacy-First (no PII) | PASS | Webhook payloads contain only aggregate analytics data (goal names, visitor counts) |
| Test-Driven (tests first) | GATE | All implementation tasks must include ExUnit tests |
| Performance as Feature | PASS | Async delivery via Oban, retry with backoff |
| Observability | GATE | Need structured logging for webhook deliveries |
| Simplicity | PASS | No over-engineering: standard retry pattern, simple HMAC auth |

**Post-Phase 1 Re-evaluation**: All gates remain PASS based on design.

## Project Structure

### Documentation (this feature)

```
specs/003-webhook-notifications/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── webhook-delivery.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```
lib/
├── plausible/
│   └── webhooks/           # New: Webhook context (business logic)
│       ├── webhook.ex       # Schema
│       ├── delivery.ex      # Schema
│       └── context.ex       # CRUD operations
├── plausible_web/
│   ├── controllers/
│   │   └── api/
│   │       └── webhook_controller.ex  # New: REST API
│   └── views/
│       └── webhook_view.ex  # New: JSON rendering
└── workers/
    └── deliver_webhook.ex   # New: Oban worker for async delivery

priv/repo/migrations/        # New: migration files
test/plausible/
    └── webhooks/           # New: Context tests
test/plausible_web/
    └── controllers/         # New: Controller tests
assets/js/
    └── dashboard/
        └── settings/
            └── webhooks/   # New: React components
```

**Structure Decision**: Follow Phoenix conventions - contexts in `lib/plausible/`, controllers in `lib/plausible_web/`, background jobs in existing `workers/` directory, React components in existing `assets/js/` structure.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | - | - |

No complexity violations. Feature uses existing patterns (Oban workers, Ecto schemas, Phoenix controllers).
