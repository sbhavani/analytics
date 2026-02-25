# Implementation Plan: GraphQL Analytics API

**Branch**: `001-graphql-analytics` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

## Summary

Implement a GraphQL API endpoint that exposes analytics data (pageviews, events, custom metrics) with filtering and aggregation capabilities. The API will use Absinthe (Elixir GraphQL library) and integrate with the existing API authentication and rate limiting infrastructure. Queries will execute against ClickHouse analytics data.

## Technical Context

**Language/Version**: Elixir 1.15+ (Phoenix Framework)
**Primary Dependencies**: Absinthe (GraphQL), Phoenix (HTTP), ClickHouse (analytics data)
**Storage**: PostgreSQL (metadata), ClickHouse (analytics data)
**Testing**: ExUnit (backend), Jest (if frontend changes)
**Target Platform**: Linux server (Elixir/Phoenix)
**Project Type**: web-service (GraphQL API)
**Performance Goals**: API responses < 5 seconds for typical queries (single metric, 30-day range)
**Constraints**: Rate limited (600 req/hour), max date range 366 days
**Scale/Scope**: Multi-tenant SaaS (multiple sites per API key)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First (no PII collection) | PASS | Analytics API provides aggregated data only |
| Test-Driven (tests first) | PASS | Implementation must follow Red-Green-Refactor |
| Performance considered | PASS | 5-second response target specified |
| Observability | PASS | Structured logging and OpenTelemetry already in project |
| Simplicity/YAGNI | PASS | Using existing auth/rate-limit infrastructure |

## Project Structure

### Documentation (this feature)

```text
specs/001-graphql-analytics/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
│   └── graphql-api.md
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── plausible/
│   ├── graphql/              # NEW: GraphQL schema and resolvers
│   │   ├── schema.ex
│   │   ├── resolvers/
│   │   └── types/
│   └── stats/                # Existing: Stats queries for ClickHouse
└── plausible_web/
    ├── controllers/
    │   └── api/
    │       └── graphql_controller.ex   # NEW: GraphQL endpoint
    ├── router.ex               # Add /api/graphql route
    └── plugs/
        └── authorize_public_api.ex     # Existing: API auth (reuse)

test/
├── plausible/
│   └── graphql/               # NEW: GraphQL tests
│       ├── schema_test.exs
│       └── resolvers_test.exs
└── plausible_web/
    └── controllers/
        └── api/
            └── graphql_controller_test.exs  # NEW
```

**Structure Decision**: GraphQL schema and types under `lib/plausible/graphql/` (following Phoenix convention of contexts), controller in `lib/plausible_web/controllers/api/`, reusing existing authentication and rate limiting plugs.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| GraphQL library (Absinthe) | Required for GraphQL schema/introspection | GraphQL requires schema definition; REST not requested by user |
| New directory (graphql) | Absinthe conventions require separate module | Could inline in controller but would be harder to maintain |

## Implementation Notes

1. **Authentication**: Reuse existing `AuthorizePublicAPI` plug with `stats:read:*` scope
2. **Rate Limiting**: Existing rate limit infrastructure (600/hour, 60/10s burst)
3. **Data Source**: Query existing ClickHouse data via `Plausible.Stats` context
4. **Schema**: Define with Absinthe, support introspection
5. **Testing**: Write ExUnit tests first per constitution
