# Implementation Plan: GraphQL Analytics API

**Branch**: `004-graphql-analytics-api` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/004-graphql-analytics-api/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add a GraphQL API endpoint to expose analytics data (pageviews, events, custom metrics) with filtering and aggregation capabilities. The API will allow authenticated users to query their analytics data via GraphQL queries, supporting date range filters, URL/event type/metric name filters, and aggregation functions (count, sum, average) grouped by time period or category.

## Technical Context

**Language/Version**: Elixir ~1.18
**Primary Dependencies**: Phoenix ~1.7, Absinthe (GraphQL), ClickHouse via ecto_ch
**Storage**: ClickHouse for analytics data, PostgreSQL for user/site metadata
**Testing**: ExUnit (Elixir), integration tests required
**Target Platform**: Linux server (self-hosted or cloud)
**Project Type**: Web service / API
**Performance Goals**: Query response within 5 seconds for 90-day ranges, aggregation within 10 seconds
**Constraints**: Must maintain privacy-first principles (no personal data), GDPR/CCPA compliant
**Scale/Scope**: Multi-tenant SaaS analytics platform

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First (Core Principle I) | **PASS** | GraphQL API only exposes aggregate analytics data already collected; no new data collection |
| TDD Required (Core Principle II) | **PASS** | Tests will be written before implementation |
| Performance as Feature (Core Principle III) | **PASS** | Performance targets defined in spec (5s query, 10s aggregation) |
| Observability (Core Principle IV) | **PASS** | Will include structured logging and metrics |
| Simplicity/YAGNI (Core Principle V) | **PASS** | Starting with essential features only |

## Project Structure

### Documentation (this feature)

```
specs/004-graphql-analytics-api/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
│   └── graphql-api.md
└── tasks.md             # Phase 2 output (/speckit.tasks)
```

### Source Code (repository root)

```
lib/
├── plausible/
│   ├── graphqla/        # NEW: GraphQL schema and resolvers
│   │   ├── schema.ex
│   │   ├── resolvers/
│   │   └── types/
│   └── ...
└── plausible_web/
    ├── router.ex        # Add GraphQL endpoint
    └── graphqla/
        └── endpoint.ex  # NEW: GraphQL HTTP handler

test/
├── graphqla/            # NEW: GraphQL tests
└── ...
```

**Structure Decision**: GraphQL schema organized under `lib/plausible/graphqla/` following Phoenix context patterns, with HTTP handling in `plausible_web`. Uses Absinthe library for GraphQL implementation in Elixir.
