# Implementation Plan: Time Period Comparison

**Branch**: `001-time-period-comparison` | **Date**: 2026-02-25 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-time-period-comparison/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Enable users to compare analytics metrics between two date ranges (e.g., this week vs. last week) with percentage change display. This feature extends the existing analytics dashboard with period comparison capabilities, allowing users to select predefined period pairs or custom date ranges for comparison.

## Technical Context

**Language/Version**: Elixir 1.15+ (Phoenix Framework)
**Primary Dependencies**: Phoenix 1.7+, Ecto, ClickHouse, React, TypeScript, TailwindCSS
**Storage**: PostgreSQL (transactions), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (web application)
**Project Type**: web-service with React frontend
**Performance Goals**: Real-time analytics queries (<200ms p95)
**Constraints**: Must maintain GDPR compliance, no personal data collection
**Scale/Scope**: Multi-tenant analytics platform with historical data storage

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Privacy-First Development
- **PASS**: Feature compares aggregate metrics between time periods without collecting personal data
- No new data collection - uses existing timestamped analytics data
- No cookies or personal identifiers involved in period comparison

### Test-Driven Development
- **GATE**: Tests MUST be written before implementation
- Unit tests required for percentage change calculation logic
- Integration tests for database queries with period filters

### Performance as a Feature
- **GATE**: Query optimization required for period comparisons
- ClickHouse queries must be optimized for date range filtering
- Consider pre-computed aggregations for predefined period pairs
- Benchmark required for query performance with large date ranges

### Observability
- **Required**: Structured logging for period comparison operations
- Track: comparison period selected, metrics compared, query execution time

## Project Structure

### Documentation (this feature)

```text
specs/001-time-period-comparison/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (skipped - no clarifications needed)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

Based on the existing Plausible Analytics codebase structure:

```text
priv/
├── gettext/             # Internationalization
└── repo/                # Database migrations

lib/
├── plausible/
│   ├── application.ex   # Application config
│   ├── repo.ex          # Ecto repository
│   └── web/
│       ├── endpoint.ex  # Phoenix endpoint
│       ├── router.ex    # Phoenix router
│       ├── channels/    # Phoenix channels
│       ├── controllers/# Phoenix controllers
│       ├── views/       # Phoenix views
│       └── plugs/       # Phoenix plugs

assets/
├── js/
│   ├── components/      # React components
│   ├── pages/           # Page components
│   └── lib/             # Utilities
└── css/                 # Stylesheets

test/
├── plausible/
│   └── web/             # Controller tests
│   └── repo/            # Repository tests
└── support/
    └── fixtures/       # Test fixtures
```

**Structure Decision**: Web application with Phoenix backend and React frontend. Uses Ecto for database operations and ClickHouse for analytics queries. Follows existing Plausible Analytics project structure.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | No violations | N/A |

---

## Phase 0: Outline & Research

**Status**: SKIPPED - No [NEEDS CLARIFICATION] markers in spec

The feature specification contains no ambiguous requirements needing clarification. All technical decisions can be made based on existing project patterns and the constitution.

---

## Phase 1: Design & Contracts

### 1.1 Data Model

See [data-model.md](./data-model.md)

### 1.2 Interface Contracts

See [contracts/](./contracts/)

### 1.3 Quickstart Guide

See [quickstart.md](./quickstart.md)

### 1.4 Agent Context Update

✓ Agent context updated successfully via `.specify/scripts/bash/update-agent-context.sh claude`
