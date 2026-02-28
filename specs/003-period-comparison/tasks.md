# Tasks: Time Period Comparison

**Feature**: Time Period Comparison | **Branch**: `003-period-comparison`
**Generated**: 2026-02-27

## Summary

The Time Period Comparison feature is **already fully implemented** in the codebase. All user stories and functional requirements from the specification have been implemented.

- **Total Tasks**: 4
- **User Story Tasks**: 0 (all user stories already complete)
- **Verification Tasks**: 4

---

## Phase 1: Verification (Feature Already Implemented)

The following tasks verify the existing implementation aligns with the specification.

### Task Group: Implementation Verification

- [x] T001 Verify backend comparison logic in lib/plausible/stats/comparisons.ex supports previous_period, year_over_year, and custom date range modes
- [x] T002 Verify percentage calculation in lib/plausible/stats/compare.ex handles all metric types correctly
- [x] T003 Verify frontend comparison UI in assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx renders all comparison modes
- [x] T004 Verify metric display in assets/js/dashboard/stats/reports/metric-value.tsx shows percentage changes with color-coded arrows

---

## Implementation Details

### User Story 1: Previous Period Comparison (IMPLEMENTED)

All functionality implemented in:
- `lib/plausible/stats/comparisons.ex` - Period calculation logic
- `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` - UI for mode selection
- `assets/js/dashboard/stats/reports/metric-value.tsx` - Value display with change indicators

**Independent Test**: Select date range, enable "previous period" comparison, verify both current and previous values display with percentage change.

---

### User Story 2: Year-over-Year Comparison (IMPLEMENTED)

All functionality implemented in:
- `lib/plausible/stats/comparisons.ex` - `get_comparison_date_range/1` handles `:year_over_year` mode
- `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` - UI for year-over-year selection

**Independent Test**: Select date range, enable "year-over-year" comparison, verify data from 12 months prior displays.

---

### User Story 3: Custom Date Range Comparison (IMPLEMENTED)

All functionality implemented in:
- `lib/plausible/stats/comparisons.ex` - `{:date_range, from, to}` mode
- `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` - Custom date range calendar
- `assets/js/dashboard/nav-menu/query-periods/date-range-calendar.tsx` - Date picker component

**Independent Test**: Select "custom range" comparison mode, choose specific dates, verify comparison data displays correctly.

---

## Dependency Graph

```
T001 (Backend verification)
    │
    ├── T002 (Percentage calculation)
    │
    ├── T003 (Frontend UI verification)
    │
    └── T004 (Metric display verification)
```

---

## Parallel Opportunities

All verification tasks can run in parallel as they test independent components:
- T001: Backend comparison logic
- T002: Percentage calculations
- T003: Frontend comparison UI
- T004: Metric display components

---

## Suggested MVP Scope

**MVP Status**: COMPLETE

The feature is fully implemented. No additional development tasks are required. The verification tasks confirm alignment with the specification.

---

## Implementation Strategy

Since the feature is already implemented:

1. **Verification Phase**: Run verification tasks to confirm existing code meets specification
2. **Enhancement Phase** (if needed): Identify any gaps or enhancements via `/speckit.clarify`

---

## Files Reference

### Backend (Elixir)

| File | Purpose |
|------|---------|
| `lib/plausible/stats/comparisons.ex` | Core comparison period calculation |
| `lib/plausible/stats/compare.ex` | Percentage change calculations |
| `lib/plausible/stats/query.ex` | Query struct with comparison options |
| `test/plausible/stats/comparisons_test.exs` | ExUnit tests |

### Frontend (React/TypeScript)

| File | Purpose |
|------|---------|
| `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` | Comparison mode selector UI |
| `assets/js/dashboard/nav-menu/query-periods/dashboard-period-picker.tsx` | Date range picker |
| `assets/js/dashboard/stats/reports/metric-value.tsx` | Metric display with comparison |
| `assets/js/dashboard/stats/reports/change-arrow.tsx` | Directional change indicators |
| `assets/js/dashboard/dashboard-state-context.tsx` | State management |
| `assets/js/dashboard/dashboard-time-periods.ts` | Time period utilities |

---

## Notes

- Feature fully implemented - all 9 functional requirements satisfied
- All 3 user stories (Previous Period, Year-over-Year, Custom Range) complete
- Tests exist in `test/plausible/stats/comparisons_test.exs`
- No additional implementation tasks required
