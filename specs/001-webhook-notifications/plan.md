# Implementation Plan: Webhook Notifications

**Branch**: `001-webhook-notifications` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-webhook-notifications/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement a webhook notification system that allows users to configure HTTP POST endpoints to receive real-time notifications when specific analytics events occur (visitor spikes, goal completions). The system uses background jobs (Oban) for reliable delivery with exponential backoff retry logic, and PostgreSQL for storing webhook configurations and delivery history.

## Technical Context

**Language/Version**: Elixir 1.16+ (Phoenix Framework)
**Primary Dependencies**: Phoenix, Ecto, HTTPoison (HTTP client), Oban (background jobs), PostgreSQL, ClickHouse
**Storage**: PostgreSQL (webhook configs, delivery records), ClickHouse (analytics data for trigger evaluation)
**Testing**: ExUnit (unit/integration), Wallaby (E2E)
**Target Platform**: Linux server (cloud deployment)
**Project Type**: web-service (Phoenix + React)
**Performance Goals**: Webhook delivery within 30 seconds, 95% success rate
**Constraints**: <30s delivery latency, max 10 webhooks per account
**Scale/Scope**: Multi-tenant SaaS with 10k+ sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gate Evaluation

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First Development | PASS | Webhooks notify about aggregate analytics events only (visitor counts, goal completions). No personal data collected. |
| II. Test-Driven Development | PASS | ExUnit tests required before implementation - will write tests first following Red-Green-Refactor. |
| III. Performance as a Feature | PASS | Success criteria specify <30s delivery latency and 95% success rate. Background jobs ensure non-blocking operation. |
| IV. Observability and Debuggability | PASS | Structured logging for webhook operations, delivery history tracking for debugging. |
| V. Simplicity and YAGNI | PASS | Starting with basic triggers (visitor spike, goal completion). Can add more trigger types later. |

### Additional Standards

| Standard | Status | Notes |
|----------|--------|-------|
| Technology: Elixir/Phoenix | PASS | Follows Phoenix conventions for controllers, contexts, and schemas. |
| Databases: PostgreSQL + ClickHouse | PASS | PostgreSQL for webhook configs, ClickHouse for analytics queries (trigger evaluation). |
| Testing: ExUnit | PASS | Will follow ExUnit patterns used in existing codebase. |
| Code Quality: Credo | PASS | Will run Credo before commit. |
| Security: Input validation | PASS | URL validation, HTTPS requirement, secret encryption. |

## Project Structure

### Documentation (this feature)

```text
specs/001-webhook-notifications/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/
│   └── api.md           # API contract
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

This is a Phoenix web application with React frontend.

```text
lib/plausible/
├── webhooks/
│   ├── webhook.ex           # Webhook schema (Ecto)
│   ├── trigger.ex            # Trigger schema (Ecto)
│   ├── delivery.ex           # Delivery record schema (Ecto)
│   └── webhooks.ex           # Context module (business logic)
├── workers/
│   └── deliver_webhook.ex    # Oban worker for async delivery
└── ...                       # (other existing modules)

lib/plausible_web/
├── controllers/
│   └── api/
│       └── webhook_controller.ex  # API for CRUD operations
└── live/
    └── webhook_live.ex       # LiveView for UI management

assets/js/dashboard/
├── components/
│   └── webhook-settings.tsx  # Webhook configuration UI
└── pages/
    └── ...

test/plausible/
├── webhooks/
│   ├── webhook_test.exs
│   └── delivery_test.exs
└── workers/
    └── deliver_webhook_test.exs
```

**Structure Decision**: Webhook modules follow existing patterns in the codebase:
- Ecto schemas in `lib/plausible/` (not under web/)
- Context modules in `lib/plausible/` for business logic
- Controllers in `lib/plausible_web/controllers/`
- Workers in `lib/workers/` (following existing Oban pattern)
- React components in `assets/js/dashboard/`

## Phase 1 Complete

All Phase 1 tasks completed:

- [x] Technical Context filled
- [x] Constitution Check passed
- [x] Research documented (no unknowns)
- [x] Data Model created
- [x] API Contracts defined
- [x] Quickstart guide created
- [x] Agent context updated

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
