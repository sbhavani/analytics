# Implementation Plan: GraphQL Analytics API

**Branch**: `007-graphql-analytics-api` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-graphql-analytics-api/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement a GraphQL API endpoint that exposes analytics data (pageviews, events, custom metrics) with filtering and aggregation capabilities. The GraphQL API will integrate with the existing Plausible Stats infrastructure, leveraging the existing Query, Filters, and QueryRunner modules. New GraphQL infrastructure using Absinthe will be added to the Phoenix application, reusing existing API key authentication and rate limiting patterns.

## Technical Context

**Language/Version**: Elixir 1.15+ (OTP 25+)
**Primary Dependencies**: Absinthe (GraphQL), Phoenix (HTTP), ClickHouse (analytics storage)
**Storage**: PostgreSQL (auth/metadata), ClickHouse (analytics data)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (Phoenix web application)
**Performance Goals**: 3 second response time for typical queries, 100 concurrent queries
**Constraints**: Rate limiting via existing API infrastructure, API key authentication required
**Scale/Scope**: Supports existing site-based analytics with pagination for large datasets

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| Privacy-First Development | PASS | No personal data exposed; query results aggregate visitor data |
| Test-Driven Development | PASS | ExUnit tests required for GraphQL schema and resolvers |
| Performance as a Feature | PASS | Leverages existing optimized ClickHouse queries |
| Observability and Debuggability | PASS | Use existing structured logging patterns |
| Simplicity and YAGNI | PASS | Reuses existing stats infrastructure rather than building new |

**Technology Standards Compliance**:

| Standard | Status | Notes |
|----------|--------|-------|
| Backend: Elixir/Phoenix | PASS | Using Phoenix controllers and Absinthe |
| Databases: PostgreSQL + ClickHouse | PASS | Existing infrastructure reused |
| Testing: ExUnit | PASS | Required for new code |
| Code Quality: Credo | PASS | Must pass for new modules |

## Project Structure

### Documentation (this feature)

```text
specs/007-graphql-analytics-api/
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
│   ├── stats/           # Existing analytics modules (Query, Filters, Aggregate, Breakdown)
│   └── auth/            # Existing auth (ApiKey)
├── plausible_web/
│   ├── router.ex        # Add GraphQL route
│   ├── plugs/          # Existing authorize_public_api plug
│   ├── controllers/     # Add GraphQL controller
│   └── graphql/         # NEW: GraphQL schema and resolvers
│       ├── schema.ex
│       ├── resolvers/
│       └── types/
test/
├── plausible_web/
│   └── graphql/         # NEW: GraphQL tests
└── plausible/
    └── stats/           # Existing (reuse)
```

**Structure Decision**: Adding new GraphQL infrastructure to the existing Phoenix application at `lib/plausible_web/graphql/`. Reuses existing Stats modules (`Plausible.Stats`, `Plausible.Stats.Query`, etc.) and authentication (`Plausible.Auth.ApiKey`).

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
