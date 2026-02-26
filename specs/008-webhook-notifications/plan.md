# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add webhook notification capabilities to Plausible Analytics, enabling websites to receive HTTP POST notifications for traffic spikes, traffic drops, and goal completions. The feature extends the existing TrafficChangeNotification pattern with webhook delivery, includes configuration UI, test functionality, and retry logic for reliable delivery.

## Technical Context

<!--
  ACTION REQUIRED: Replace the content in this section with the technical details
  for the project. The structure here is presented in advisory capacity to guide
  the iteration process.
-->

**Language/Version**: Elixir ~> 1.18
**Primary Dependencies**: Phoenix framework, Oban (background jobs), Finch (HTTP client), Jason (JSON), PostgreSQL, ClickHouse
**Storage**: PostgreSQL (webhook configs, delivery logs), ClickHouse (analytics data)
**Testing**: ExUnit
**Target Platform**: Linux server
**Project Type**: Web service (multi-tenant SaaS analytics)
**Performance Goals**: Sub-30-second webhook delivery latency, 95% first-attempt success rate
**Constraints**: Privacy-first (no personal data in webhooks), must maintain existing notification patterns
**Scale/Scope**: Multi-tenant SaaS supporting many sites per installation

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| **TDD Required** | PASS | ExUnit tests will be written for all new modules following Red-Green-Refactor cycle |
| **Privacy Impact** | PASS | Webhook payloads contain only aggregate metrics (visitor counts, goal names), no personal data |
| **Performance Consideration** | PASS | Async delivery via Oban ensures webhook calls don't block user requests |
| **Observability** | PASS | Structured logging for all webhook operations, delivery logs for debugging |
| **Simplicity** | PASS | Reuses existing TrafficChangeNotification schema pattern, minimal new components |

**Constitution Alignment**: This feature aligns with the constitution by:
- Following existing notification patterns (TrafficChangeNotification)
- Using Oban for async delivery (same as email notifications)
- Logging all delivery attempts for debuggability
- Keeping webhook payloads minimal (aggregate data only)

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
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
│   ├── site/
│   │   └── webhook.ex              # NEW: Webhook configuration schema
│   ├── workers/
│   │   └── webhook_delivery.ex     # NEW: Oban worker for webhook delivery
│   └── http_client.ex              # EXISTING: Reused for webhook POSTs

priv/repo/migrations/
└── [timestamp]_create_webhooks.exs  # NEW: Migration for webhook tables

test/
├── plausible/
│   └── site/
│       └── webhook_test.exs         # NEW: Tests for webhook schema
└── workers/
    └── webhook_delivery_test.exs    # NEW: Tests for delivery worker

assets/js/
└── [Frontend webhook UI components] # NEW: React components for settings page
```

**Structure Decision**: This is an Elixir/Phoenix web service. New code follows existing patterns:
- Ecto schema in `lib/plausible/site/` (like TrafficChangeNotification)
- Oban worker in `lib/workers/` (like TrafficChangeNotifier)
- Reuses existing `Plausible.HTTPClient` for POST requests

## Complexity Tracking

*No complexity violations - feature reuses existing patterns.*
