# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Time Period Comparison enables users to compare metrics between two date ranges (e.g., this week vs last week) with percentage change display. This feature is already implemented in the codebase with full support for:
- Comparison modes: previous_period, year_over_year, custom date ranges
- Percentage change calculation and display with visual indicators (up/down arrows)
- Both primary and comparison values displayed in tooltips and metric cards
- State persistence via URL query parameters

## Technical Context

**Language/Version**: Elixir 1.15+, Phoenix Framework
**Primary Dependencies**: Phoenix, Ecto, ClickHouse, React 18+, TypeScript, TailwindCSS
**Storage**: PostgreSQL (metadata), ClickHouse (analytics data)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (Linux server)
**Project Type**: web-service/analytics-dashboard
**Performance Goals**: Sub-second query response for comparison queries
**Constraints**: Privacy-first analytics (no personal data, GDPR compliant)
**Scale/Scope**: Multi-tenant SaaS analytics platform

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Privacy-First Development | ✅ PASS | No personal data collected; comparison operates on aggregate analytics data only |
| II. Test-Driven Development | ✅ PASS | Comparison module has existing tests; verify new tests for any changes |
| III. Performance as a Feature | ✅ PASS | Comparison queries use existing optimized query paths |
| IV. Observability and Debuggability | ✅ PASS | Comparison state logged via query params for debugging |
| V. Simplicity and YAGNI | ✅ PASS | Feature uses existing date range infrastructure; no over-engineering |

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
lib/
├── plausible/
│   ├── stats/
│   │   ├── comparisons.ex        # Backend comparison logic
│   │   ├── query.ex              # Query struct with comparison fields
│   │   ├── datetime_range.ex     # Date range handling
│   │   └── *.ex                  # Other stats modules
│   └── *.ex                      # Other Plausible modules

lib/plausible_web/
├── controllers/
│   ├── stats_controller.ex        # Main stats endpoints
│   └── api/stats_controller.ex   # API endpoints
├── live/
│   └── *.ex                      # LiveView components
└── templates/
    └── *.heex                    # Phoenix templates

assets/js/
├── dashboard/
│   ├── nav-menu/
│   │   └── query-periods/
│   │       ├── comparison-period-menu.tsx  # Comparison UI
│   │       ├── dashboard-period-picker.tsx # Period selection
│   │       └── date-range-calendar.tsx     # Custom date picker
│   ├── stats/
│   │   ├── reports/
│   │   │   ├── metric-value.tsx    # Displays % change with arrows
│   │   │   ├── change-arrow.tsx     # Arrow indicator component
│   │   │   └── list.tsx             # Report list
│   │   └── graph/
│   │       └── *.tsx               # Graph components
│   ├── dashboard-state.ts          # State management
│   └── dashboard-time-periods.ts   # Time period logic
└── *.tsx

test/
├── plausible/
│   └── stats/
│       └── comparisons_test.exx    # Comparison tests
└── *
```

**Structure Decision**: Web application with Phoenix backend and React/TypeScript frontend. The comparison feature is already fully implemented in both backend (`lib/plausible/stats/comparisons.ex`) and frontend (React components). No new source code directories required.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
