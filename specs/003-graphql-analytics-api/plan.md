# Implementation Plan: GraphQL Analytics API

**Branch**: `003-graphql-analytics-api` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-graphql-analytics-api/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Implement a GraphQL API endpoint that exposes analytics data (pageviews, events, custom metrics) with filtering and aggregation capabilities. The API will use Absinthe (Elixir's GraphQL library) to provide a flexible query interface on top of the existing ClickHouse analytics backend, following Phoenix conventions for controllers and contexts.

## Technical Context

**Language/Version**: Elixir 1.18+
**Primary Dependencies**: Phoenix 1.7+, Ecto, ClickHouse (analytics queries), PostgreSQL (transactional), Absinthe (GraphQL)
**Storage**: PostgreSQL for transactional data, ClickHouse for analytics queries
**Testing**: ExUnit for Elixir, Jest for JavaScript
**Target Platform**: Linux server
**Project Type**: web-service/api
**Performance Goals**: <5s response time, 1000 queries/minute capacity
**Constraints**: Privacy-first (GDPR/CCPA compliant), no personal data collection
**Scale**: Analytics platform serving multiple sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Gates from Constitution

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | ✅ PASS | GraphQL API exposes aggregated analytics only, no personal data |
| Test-Driven Development | ✅ PASS | Tests required for GraphQL schema and resolvers |
| Performance as a Feature | ✅ PASS | Performance goals defined (5s, 1000 req/min) |
| Observability Required | ✅ PASS | Structured logging and metrics for API queries |
| Simplicity and YAGNI | ✅ PASS | Starting with core queries, avoiding over-engineering |

### Technology Standards Check

| Standard | Compliance | Notes |
|----------|------------|-------|
| Elixir/Phoenix | ✅ COMPLIANT | Using Phoenix conventions |
| PostgreSQL + ClickHouse | ✅ COMPLIANT | Uses existing data stores |
| ExUnit for testing | ✅ COMPLIANT | All new code tested |
| Credo linting | ✅ COMPLIANT | Code follows Credo |
| Input validation | ✅ COMPLIANT | GraphQL schema validation |
| Rate limiting | ✅ COMPLIANT | Required for public endpoints |

## Project Structure

### Documentation (this feature)

```text
specs/003-graphql-analytics-api/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

**Structure Decision**: Single web service project - following Phoenix conventions

```text
lib/
├── plausible_web/
│   ├── controllers/
│   │   └── api/
│   │       └── graphql_controller.ex    # NEW - GraphQL endpoint
│   ├── graphql/
│   │   ├── schema.ex                    # GraphQL schema
│   │   ├── resolvers/
│   │   │   ├── pageview.ex
│   │   │   ├── event.ex
│   │   │   └── metric.ex
│   │   └── types/
│   │       ├── pageview_type.ex
│   │       ├── event_type.ex
│   │       └── metric_type.ex
│   └── plugs/
│       └── graphql_plug.ex              # Optional: rate limiting
├── plausible/
│   └── stats/
│       └── query.ex                     # Existing query builder
test/
├── plausible_web/
│   └── graphql_test.exs                 # NEW - GraphQL tests
└── contract/
    └── graphql_contract_test.exs        # NEW - API contract tests
```

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
