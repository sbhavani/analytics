# Implementation Plan: GraphQL Analytics API

**Branch**: `010-graphql-analytics-api` | **Date**: 2026-02-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/010-graphql-analytics-api/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Add a GraphQL API endpoint to expose analytics data (pageviews, events, custom metrics) with filtering and aggregation capabilities. The API will leverage existing ClickHouse-based stats queries and provide a unified interface for programmatic access to analytics data. This extends the existing REST stats API with GraphQL's flexible query capabilities.

## Technical Context

**Language/Version**: Elixir 1.18
**Primary Dependencies**: Absinthe (GraphQL), Phoenix, Ecto, ClickHouse (already in use)
**Storage**: PostgreSQL (transactions), ClickHouse (analytics queries)
**Testing**: ExUnit
**Target Platform**: Linux server
**Project Type**: web-service
**Performance Goals**: 5s response for 30-day queries, 100 concurrent requests, 95% success rate
**Constraints**: Must maintain privacy-first principles (no personal data), existing auth system must be reused
**Scale/Scope**: Multi-tenant analytics platform serving multiple sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gate 1: Test-Driven Development
- [x] Feature requires tests written before implementation
- [x] Unit tests for GraphQL schema/resolvers
- [x] Integration tests for API boundaries
- **Status**: PASS

### Gate 2: Performance as a Feature
- [x] Query optimization considered (reuse existing ClickHouse queries)
- [x] Caching strategies evaluated
- [x] Benchmarks required for query performance
- **Status**: PASS

### Gate 3: Privacy-First Development
- [x] No personal data collection in new API
- [x] Authorization checks required (users can only access their own data)
- [x] Existing privacy controls maintained
- **Status**: PASS

### Gate 4: Observability
- [x] Structured logging for GraphQL operations
- [x] Metrics for query execution times
- [x] Error tracking with context
- **Status**: PASS

## Project Structure

### Documentation (this feature)

```
specs/010-graphql-analytics-api/
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
│   ├── stats/           # Existing stats queries (reused)
│   └── graphql/         # NEW: GraphQL schema and resolvers
│       ├── schema.ex
│       ├── resolvers/
│       └── types/
├── plausible_web/
│   ├── router.ex        # Add GraphQL route
│   └── controllers/
│       └── graphql_controller.ex  # NEW: HTTP handler

test/
├── plausible/
│   └── graphql/         # NEW: GraphQL tests
└── contract/
    └── graphql/         # Contract tests for API
```

**Structure Decision**: GraphQL will be added as a new module under `plausible/graphql` following Phoenix conventions. The existing stats module will be reused for data retrieval. Router will mount GraphQL endpoint at `/api/graphql`.
