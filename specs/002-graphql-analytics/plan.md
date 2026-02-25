# Implementation Plan: GraphQL Analytics API

**Branch**: `002-graphql-analytics` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/002-graphql-analytics/spec.md`

## Summary

Implement a GraphQL API endpoint that exposes analytics data (pageviews, events, custom metrics) with filtering and aggregation capabilities. The API will leverage existing Plausible stats modules and query infrastructure to provide a modern, flexible query interface for analytics data.

## Technical Context

**Language/Version**: Elixir 1.15+ (Phoenix framework)
**Primary Dependencies**: Absinthe (GraphQL), existing Plausible stats modules
**Storage**: ClickHouse (analytics queries), PostgreSQL (metadata)
**Testing**: ExUnit (Elixir), existing test patterns in test/plausible_web/controllers/
**Target Platform**: Linux server (Phoenix web service)
**Project Type**: Web service / API endpoint
**Performance Goals**: Sub-5 second queries for 30-day periods (per SC-001), handle 10,000+ record pagination
**Constraints**: Must maintain privacy-first principles, follow existing Phoenix patterns
**Scale/Scope**: Multi-tenant analytics serving multiple sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First Development | ✅ PASS | GraphQL API only exposes aggregate analytics data; no personal data collection |
| II. Test-Driven Development | ✅ PASS | Will write ExUnit tests before implementation per constitution |
| III. Performance as a Feature | ✅ PASS | Reuses existing optimized ClickHouse queries; pagination required |
| IV. Observability and Debuggability | ✅ PASS | Will add structured logging for all GraphQL operations |
| V. Simplicity and YAGNI | ✅ PASS | Using existing stats modules rather than building from scratch |

## Project Structure

### Documentation (this feature)

```text
specs/002-graphql-analytics/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (GraphQL/Elixir best practices)
├── data-model.md        # Phase 1 output (GraphQL schema and types)
├── quickstart.md        # Phase 1 output (API usage guide)
├── contracts/           # Phase 1 output (GraphQL schema definition)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/plausible_web/
├── graphql/
│   ├── schema.ex                # Main GraphQL schema
│   ├── resolvers/
│   │   ├── pageviews.ex         # Pageview queries
│   │   ├── events.ex            # Event queries
│   │   └── metrics.ex           # Custom metrics queries
│   └── types/
│       ├── pageview.ex          # Pageview type definitions
│       ├── event.ex             # Event type definitions
│       └── metric.ex            # Custom metric type definitions
└── controllers/
    └── graphQL_controller.ex    # HTTP endpoint (or use Absinthe.Plug)

test/plausible_web/
└── graphql/
    ├── schema_test.exs          # Schema validation tests
    ├── resolvers/
    │   ├── pageviews_test.exs
    │   ├── events_test.exs
    │   └── metrics_test.exs
    └── integration/
        └── graphql_api_test.exs
```

**Structure Decision**: New `lib/plausible_web/graphql/` directory following Phoenix conventions, reusing existing stats modules in `lib/plausible/stats/`. GraphQL endpoint added to existing API routes.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No complexity violations. Simple structure using:
- Absinthe for GraphQL (standard Elixir GraphQL library)
- Existing stats modules (no duplication)
- Standard Phoenix controller/router patterns

---

# Phase 0: Research ✅ COMPLETE

Research completed and documented in [research.md](./research.md).

## Key Findings

- **GraphQL Library**: Use Absinthe (de facto standard for Elixir)
- **Integration Pattern**: Resolvers act as thin translation layer to existing Stats modules
- **Performance**: Use cursor-based pagination via Absinthe connections
- **Error Handling**: Return empty arrays for no-data (not errors)

---

# Phase 1: Design ✅ COMPLETE

Design artifacts created:

- [data-model.md](./data-model.md) - GraphQL type definitions
- [contracts/schema.graphql](./contracts/schema.graphql) - Public API contract
- [quickstart.md](./quickstart.md) - API usage guide

## Constitution Check (Re-evaluated)

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First Development | ✅ PASS | GraphQL API only exposes aggregate analytics data |
| II. Test-Driven Development | ✅ PASS | Will write ExUnit tests before implementation |
| III. Performance as a Feature | ✅ PASS | Cursor pagination, query complexity analysis |
| IV. Observability and Debuggability | ✅ PASS | Structured logging for GraphQL operations |
| V. Simplicity and YAGNI | ✅ PASS | Reuses existing stats modules |

---

# Phase 2: Implementation

*(To be triggered by /speckit.tasks command)*
