# Implementation Plan: Time Period Comparison

**Branch**: `001-time-period-compare` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-time-period-compare/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The Time Period Comparison feature enables users to compare key performance metrics between two different date ranges (e.g., this week vs last week) with visual percentage change display. This is a dashboard analytics feature that extends the existing metrics query system to support dual-period queries and comparison calculations.

## Technical Context

**Language/Version**: Elixir 1.15+ (Backend), Node.js 18+ (Frontend), TypeScript 5.x
**Primary Dependencies**: Phoenix Framework 1.7+, React 18+, TailwindCSS 3.x, Ecto, ClickHouse HTTP API
**Storage**: PostgreSQL (transactional data), ClickHouse (analytics events data)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (Linux server)
**Performance Goals**: Sub-second query response for comparison queries (< 2s for complex date ranges)
**Constraints**: Must maintain existing query performance; cannot significantly increase database load
**Scale**: Multi-tenant analytics platform with thousands of sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | PASS | Feature compares aggregate metrics, no personal data involved |
| Test-Driven Development | PASS | Tests required before implementation per constitution |
| Performance as a Feature | PASS | Query optimization considerations included |
| Observability and Debuggability | PASS | Logging for query execution and comparison calculations |
| Simplicity and YAGNI | PASS | Starting with simplest comparison model |

## Project Structure

### Documentation (this feature)

```text
specs/001-time-period-compare/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Plausible Analytics structure
lib/
├── plausible/
│   ├── repo.ex
│   ├── application.ex
│   └── ...
└── ...

priv/
└── repo/
    └── migrations/

assets/
├── js/
│   ├── components/
│   └── ...
└── css/

test/
├── plausible/
│   └── ...
└── support/
```

**Structure Decision**: This is an existing Elixir/Phoenix web application. The feature will extend:
- Backend: ClickHouse query module for dual-period queries
- Frontend: React components for comparison UI
- Shared: Date range utilities and percentage calculation logic

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No violations - all gates pass.

---

## Phase 0: Research

### Research Tasks

Based on the feature requirements, the following research areas were identified:

1. **ClickHouse Date Comparison Queries**: How to efficiently query the same metric for two different date ranges in a single request
2. **React State Management**: Best patterns for managing dual-period comparison state
3. **Percentage Change Calculations**: Edge cases for zero values and missing data

### Research Findings

*See [research.md](./research.md) for detailed findings.*

---

## Phase 1: Design

### Data Model

*See [data-model.md](./data-model.md) for detailed entity definitions.*

Key entities:
- **DateRange**: start_date, end_date
- **PeriodComparison**: current_period, comparison_period, metrics map
- **MetricChange**: metric_name, current_value, comparison_value, percentage_change

### Interface Contracts

*See [contracts/](./contracts/) for detailed API contracts.*

- **GET /api/stats**: Extended to support comparison query parameters
- **Internal Query Interface**: Dual-period query builder for ClickHouse

### Quickstart Guide

*See [quickstart.md](./quickstart.md) for development setup instructions.*

---

## Constitution Check (Post-Design)

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | PASS | Feature compares aggregate metrics, no personal data involved |
| Test-Driven Development | PASS | Tests required before implementation per constitution |
| Performance as a Feature | PASS | Query optimization considerations included |
| Observability and Debuggability | PASS | Logging for query execution and comparison calculations |
| Simplicity and YAGNI | PASS | Starting with simplest comparison model |

**Result**: All gates pass post-design. Feature is ready for implementation.
