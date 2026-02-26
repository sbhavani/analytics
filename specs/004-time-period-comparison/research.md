# Research: Time Period Comparison

**Feature**: Time Period Comparison - Compare metrics between two date ranges with percentage change display
**Status**: Feature already implemented in codebase

## Existing Implementation

### Backend Components

1. **Comparison Logic** (`lib/plausible/stats/comparisons.ex`)
   - Already handles previous_period, year_over_year, and custom date range modes
   - Provides `get_comparison_utc_time_range/1` to calculate comparison period
   - Handles day-of-week matching for accurate comparisons

2. **Query Structure** (`lib/plausible/stats/query.ex`)
   - `include.compare` field stores comparison mode
   - `comparison_utc_time_range` stores the comparison date range
   - `compare_from`/`compare_to` for custom date ranges

3. **API Integration**
   - Query params: `comparison`, `compare_from`, `compare_to`, `match_day_of_week`
   - Controllers parse and pass to Stats modules

### Frontend Components

1. **Comparison Menu** (`assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx`)
   - Dropdown with modes: Off, Previous Period, Year over Year, Custom
   - Calendar integration for custom date selection
   - Match day of week options

2. **Metric Display** (`assets/js/dashboard/stats/reports/metric-value.tsx`)
   - Shows percentage change with up/down arrows
   - Tooltip with both primary and comparison values

3. **State Management** (`assets/js/dashboard/dashboard-state.ts`)
   - Stores comparison state in URL params for persistence

## Feature Completeness Assessment

| Requirement | Status | Implementation |
|-------------|--------|----------------|
| FR-001: Comparison mode toggle | ✅ DONE | ComparisonPeriodMenu with dropdown |
| FR-002: Predefined presets | ✅ DONE | previous_period, year_over_year |
| FR-003: Custom date ranges | ✅ DONE | Calendar with date range selection |
| FR-004: % change calculation | ✅ DONE | Backend calculations |
| FR-005: Visual indicators | ✅ DONE | ChangeArrow component |
| FR-006: Validate non-overlapping | ✅ DONE | Calendar min/max dates |
| FR-007: Handle zero values | ✅ DONE | Null handling in frontend |
| FR-008: State persistence | ✅ DONE | URL query params |
| FR-009: Show both values | ✅ DONE | Tooltip displays both |

## Decision

**Conclusion**: The Time Period Comparison feature is **fully implemented** in the codebase. No additional research or implementation is needed. The specification in `spec.md` accurately describes the existing functionality.

## Notes

- The existing implementation exceeds the specification in some areas (e.g., year-over-year comparison was not explicitly mentioned in the original feature request but is implemented)
- Tests exist in `test/plausible/stats/comparisons_test.exs`
