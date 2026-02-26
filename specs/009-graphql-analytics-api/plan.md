# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement a GraphQL API endpoint that exposes analytics data (pageviews, events, custom metrics) with filtering and aggregation capabilities. Using Absinthe (Elixir GraphQL library) to add a `/api/graphql` endpoint that mirrors the existing REST stats API functionality but with GraphQL's flexible query language. Authentication via existing API key infrastructure. Rate limiting enforced at 100 requests/minute.

## Technical Context

**Language/Version**: Elixir (latest in mix.lock) - Phoenix 1.8.2
**Primary Dependencies**: Phoenix 1.8, Ecto 3.13, Ecto_ch (ClickHouse), Absinthe (GraphQL - to be added)
**Storage**: PostgreSQL (transactional), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (Phoenix web application)
**Project Type**: Web service / API
**Performance Goals**: Response under 5 seconds per spec (SC-001), support 100 req/min per API key (SC-004)
**Constraints**: Rate limiting, input validation, data accuracy within 1% variance (SC-006)
**Scale/Scope**: Multi-tenant analytics serving multiple sites, existing stats API handles similar load

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Test-Driven Development | PASS | Tests will be written before implementation per Constitution II |
| Performance as a Feature | PASS | Performance goals defined in spec (SC-001, SC-004, SC-005, SC-006) |
| Observability | PASS | Logging/metrics already in place via OpenTelemetry; GraphQL will integrate |
| Security - Input Validation | PASS | All user input must be validated per Constitution Security Requirements |
| Security - Rate Limiting | PASS | Rate limiting required per FR-019 and spec SC-004 |
| Quality Gates | PASS | Will follow existing patterns: ExUnit tests + Credo + ESLint |

**Constitution Principles Alignment:**
- **Privacy-First**: GraphQL API exposes existing analytics data - no new data collection
- **YAGNI**: Starting with simple schema mirroring existing REST API capabilities
- **Simplicity**: Using Absinthe (standard Elixir GraphQL library) rather than custom solution

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
lib/plausible_web/
├── controllers/api/
│   └── graphql_controller.ex        # NEW - GraphQL endpoint
├── graphql/
│   ├── schema.ex                    # NEW - GraphQL schema definition
│   ├── resolvers/
│   │   ├── analytics.ex             # NEW - Query resolvers
│   │   └── metrics.ex               # NEW - Custom metrics resolvers
│   └── types/
│       ├── analytics_types.ex       # NEW - Object types for analytics
│       └── input_types.ex           # NEW - Input types for filters
│
test/plausible_web/graphql/          # NEW - GraphQL tests
```

**Structure Decision**: Adding GraphQL endpoint alongside existing REST APIs in `lib/plausible_web/controllers/api/`. Using standard Absinthe project structure with schema, resolvers, and types directories. Tests will mirror existing API test patterns in `test/plausible_web/controllers/api/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
