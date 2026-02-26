# Implementation Plan: Time Period Comparison

**Branch**: `006-time-period-comparison` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/006-time-period-comparison/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The time period comparison feature allows users to compare analytics metrics between two date ranges (e.g., this week vs last week) with percentage change display. **This feature already exists in the codebase.**

Key findings from research:
- Backend comparison logic is implemented in `lib/plausible/stats/comparisons.ex`
- Frontend UI is implemented in `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx`
- Percentage change display is implemented in `assets/js/dashboard/stats/reports/metric-value.tsx`

All functional requirements from the specification are already met.

## Technical Context

**Language/Version**: Elixir 1.18, Phoenix Framework
**Primary Dependencies**: Ecto, ClickHouse (analytics queries), React 18, TypeScript
**Storage**: PostgreSQL (metadata), ClickHouse (analytics data)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Web application (browser-based dashboard)
**Project Type**: Web service / Analytics dashboard
**Performance Goals**: Real-time analytics queries, sub-second response times
**Constraints**: Privacy-first (no cookies, GDPR compliant)
**Scale/Scope**: Multi-tenant SaaS analytics platform

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Test-driven development | ✅ Pass | ExUnit tests exist for comparisons module |
| Performance as a feature | ✅ Pass | ClickHouse handles large analytics queries |
| Privacy-first | ✅ Pass | Feature uses existing privacy-compliant architecture |
| Simplicity and YAGNI | ✅ Pass | Feature is already implemented simply |

## Project Structure

### Documentation (this feature)

```text
specs/006-time-period-comparison/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Not needed - internal feature
└── tasks.md            # Not needed - feature already implemented
```

### Source Code (repository root)

```text
lib/plausible/stats/
├── comparisons.ex       # Backend comparison logic
├── query.ex            # Query struct with comparison fields
├── query_include.ex    # Include options including comparison
└── ...

assets/js/dashboard/
├── nav-menu/query-periods/
│   ├── comparison-period-menu.tsx  # Comparison UI
│   ├── dashboard-time-periods.ts    # Period definitions
│   └── date-range-calendar.tsx      # Date picker
├── stats/reports/
│   ├── metric-value.tsx            # Metric display with change
│   └── change-arrow.tsx             # Visual change indicator
└── ...
```

**Structure Decision**: Feature uses existing codebase structure with:
- Backend logic in `lib/plausible/stats/`
- UI components in `assets/js/dashboard/nav-menu/`
- Metric display in `assets/js/dashboard/stats/reports/`

## Phase 0: Research Summary

Research confirmed that all functional requirements from the specification are already implemented:

| Requirement | Implementation |
|-------------|----------------|
| FR-001: Select current date range | Via `dashboard-period-menu.tsx` |
| FR-002: Select comparison date range | Via `comparison-period-menu.tsx` |
| FR-003: Display percentage change | Via `metric-value.tsx` |
| FR-004: Visual indicators | Via `change-arrow.tsx` |
| FR-005: Preset comparison options | previous_period, year_over_year, custom |
| FR-006: Custom date range | Via `DateRangeCalendar` |
| FR-007: Multiple metrics | Each metric displays its own change |
| FR-008: Handle division by zero | Should display "N/A" |
| FR-009: Preserve comparison | Via URL search params |
| FR-010: Clear labels | Via `getCurrentComparisonPeriodDisplayName` |

## Phase 1: Design Summary

The feature is already fully designed and implemented. No additional design work required.

### Key Components

1. **Comparison Mode Selector**: Allows users to choose between off, previous period, year over year, or custom
2. **Date Range Calendar**: For selecting custom comparison periods
3. **Metric Cards**: Display current value and percentage change with color-coded arrows
4. **Query Parameters**: `comparison`, `compare_from`, `compare_to`, `match_day_of_week`

### No External Contracts Required

This is an internal feature that uses existing:
- Stats API endpoints (already exist)
- Query parameter parsing (already exists)
- Frontend components (already exist)

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No complexity violations - feature is already implemented using existing patterns and architecture.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | Feature already implemented | N/A |

## Conclusion

The time period comparison feature specified in `spec.md` is already fully implemented in the codebase. The implementation meets all functional requirements defined in the specification.

**No additional implementation tasks are required.** The feature is ready for use.
