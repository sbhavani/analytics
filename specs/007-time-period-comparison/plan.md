# Implementation Plan: Time Period Comparison

**Branch**: `007-time-period-comparison` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/007-time-period-comparison/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature adds the ability to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display. The codebase already has substantial comparison functionality implemented in both backend (Elixir) and frontend (React).

**Key Finding**: The time period comparison feature ALREADY EXISTS in the codebase with:
- Backend comparison logic (`lib/plausible/stats/comparisons.ex`)
- Frontend comparison menu (`assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx`)
- Percentage change calculation and display

This plan will document the existing implementation and identify any gaps or improvements needed.

## Technical Context

**Language/Version**: Elixir 1.15+ (Phoenix framework), TypeScript/JavaScript (React frontend)
**Primary Dependencies**: Phoenix, React, React Router, React Query, ClickHouse, PostgreSQL, Ecto
**Storage**: PostgreSQL (transactional), ClickHouse (analytics queries)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web browser (responsive)
**Project Type**: Web service (Elixir/Phoenix) + Single Page Application (React)
**Performance Goals**: Real-time analytics queries with <200ms p95 response time
**Constraints**: Multi-tenant SaaS, GDPR compliant
**Scale/Scope**: Multi-tenant analytics platform serving thousands of sites

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | PASS | Time period comparison does not collect new personal data; uses existing date range logic |
| Test-Driven Development | PASS | Existing comparison functionality has test coverage in ExUnit |
| Performance as a Feature | PASS | Existing implementation follows query optimization patterns; no new performance concerns |
| Observability and Debuggability | PASS | Uses existing logging and error tracking infrastructure |
| Simplicity and YAGNI | PASS | Leverages existing comparison system rather than building new complexity |

**Conclusion**: All gates pass. The feature leverages existing infrastructure.

## Project Structure

### Documentation (this feature)

```text
specs/007-time-period-comparison/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Backend (Elixir/Phoenix)
lib/
├── plausible/
│   ├── stats/
│   │   ├── query.ex              # Query struct with comparison_utc_time_range
│   │   ├── comparisons.ex        # Core comparison logic
│   │   ├── aggregate.ex           # Returns value, comparison_value, change
│   │   ├── query_runner.ex       # Executes main + comparison queries
│   │   ├── metrics.ex            # Available metrics definitions
│   │   └── dashboard/
│   │       └── query_parser.ex    # Parses comparison params
│   └── plausible_web/
│       └── controllers/
│           └── api/
│               └── stats_controller.ex  # API endpoints
test/
├── plausible/
│   └── stats/
│       └── comparisons_test.exs   # Comparison tests

# Frontend (React/TypeScript)
assets/
├── js/
│   └── dashboard/
│       ├── dashboard-time-periods.ts  # Period and comparison enums
│       ├── dashboard-state.ts         # State management
│       ├── api.ts                    # API query params
│       ├── stats/
│       │   ├── graph/
│       │   │   └── top-stats.js      # Main metric display
│       │   └── reports/
│       │       ├── metric-value.tsx  # Shows comparison values
│       │       └── change-arrow.tsx  # Color-coded change indicator
│       └── nav-menu/
│           └── query-periods/
│               ├── dashboard-period-picker.tsx
│               ├── comparison-period-menu.tsx
│               └── date-range-calendar.tsx
└── css/
    └── dashboard/
        └── main.css
test/
├── dashboard/
│   └── [Jest tests]
```

**Structure Decision**: Web application with Elixir/Phoenix backend and React SPA frontend. Time period comparison is implemented across both layers using existing query parsing, ClickHouse comparison queries, and React component display.

## Complexity Tracking

No complexity violations - the feature leverages existing comparison infrastructure.

---

## Phase 0: Research & Clarifications

### Research Summary

The time period comparison feature already exists in the codebase with the following components:

**Backend (Elixir)**:
- `lib/plausible/stats/comparisons.ex` - Core comparison logic supporting:
  - `:previous_period` - shifts back by same number of days
  - `:year_over_year` - shifts back by 1 year
  - `{:date_range, from, to}` - custom date range
  - `compare_match_day_of_week` option for day-of-week matching
- `lib/plausible/stats/query.ex` - Query struct with `comparison_utc_time_range` field
- `lib/plausible/stats/query_runner.ex` - Executes main and comparison queries
- `lib/plausible/stats/aggregate.ex` - Returns `value`, `comparison_value`, and `change`

**Frontend (React/TypeScript)**:
- `assets/js/dashboard/dashboard-time-periods.ts` - `ComparisonMode` enum
- `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` - Comparison selector UI
- `assets/js/dashboard/stats/reports/metric-value.tsx` - Displays comparison values
- `assets/js/dashboard/stats/reports/change-arrow.tsx` - Color-coded change indicators

### Key Entities (from existing implementation)

- **Query**: Contains `utc_time_range` and `comparison_utc_time_range`
- **ComparisonMode**: `:off`, `:previous_period`, `:year_over_year`, `:custom`
- **AggregateResult**: Contains `value`, `comparison_value`, `change`

### Implementation Details

The implementation follows these patterns:
1. User selects comparison mode via UI
2. Query parser extracts comparison params from request
3. Query runner executes both main and comparison queries against ClickHouse
4. Results are combined with percentage change calculated
5. Frontend displays both values with color-coded indicators

No additional research needed - the feature is fully implemented.
