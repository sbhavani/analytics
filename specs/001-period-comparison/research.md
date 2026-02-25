# Research: Time Period Comparison Feature

## Overview

The Time Period Comparison feature already exists in the codebase. This research document verifies the existing implementation against the specification requirements.

## Existing Implementation

### Backend (Elixir)

| Component | File | Status |
|-----------|------|--------|
| Comparison Logic | `lib/plausible/stats/comparisons.ex` | Implemented |
| Change Calculation | `lib/plausible/stats/compare.ex` | Implemented |
| Query Include | `lib/plausible/stats/query_include.ex` | Implemented |

### Frontend (React/TypeScript)

| Component | File | Status |
|-----------|------|--------|
| Comparison Mode Enum | `assets/js/dashboard/dashboard-time-periods.ts` | Implemented |
| Dashboard State | `assets/js/dashboard/dashboard-state.ts` | Implemented |
| Period Picker UI | `assets/js/dashboard/nav-menu/query-periods/dashboard-period-picker.tsx` | Implemented |
| Comparison Menu | `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx` | Implemented |
| Metric Value Display | `assets/js/dashboard/stats/reports/metric-value.tsx` | Implemented |
| Change Arrow Component | `assets/js/dashboard/stats/reports/change-arrow.tsx` | Implemented |

### Tests

| Component | File | Status |
|-----------|------|--------|
| Change Arrow Tests | `assets/js/dashboard/stats/reports/change-arrow.test.tsx` | Exists |
| Metric Value Tests | `assets/js/dashboard/stats/reports/metric-value.test.tsx` | Exists |
| Dashboard Time Periods Tests | `assets/js/dashboard/dashboard-time-periods.test.ts` | Exists |

## Feature Verification Against Spec

### FR-001: Comparison Mode Selection
- **Spec**: Previous Period, Year over Year, Custom Period, Off
- **Implementation**: `ComparisonMode` enum in `dashboard-time-periods.ts`
- **Status**: ✅ Complete

### FR-002: Previous Period Calculation
- **Spec**: Auto-calculate based on primary period length
- **Implementation**: `lib/plausible/stats/comparisons.ex`
- **Status**: ✅ Complete

### FR-003: Year over Year Calculation
- **Spec**: Shift primary period back one year
- **Implementation**: `:year_over_year` mode in comparisons.ex
- **Status**: ✅ Complete

### FR-004: Custom Date Range
- **Spec**: User selects via date picker
- **Implementation**: ComparisonCalendarMenu component
- **Status**: ✅ Complete

### FR-005: Percentage Change Display
- **Spec**: Display for each metric
- **Implementation**: `metric-value.tsx` with comparison data
- **Status**: ✅ Complete

### FR-006: Visual Indicators
- **Spec**: Colored arrows
- **Implementation**: `ChangeArrow` component
- **Status**: ✅ Complete

### FR-007: Bounce Rate Logic
- **Spec**: Inverted (decrease is positive)
- **Implementation**: `color()` function in change-arrow.tsx
- **Status**: ✅ Complete

### FR-008: Match Day of Week
- **Spec**: Option to align comparison days
- **Implementation**: `match_day_of_week` in dashboard state
- **Status**: ✅ Complete

### FR-009: URL Persistence
- **Spec**: Preserve in URL for shareability
- **Implementation**: `dashboardStateToSearchParams` in api.ts
- **Status**: ✅ Complete

### FR-010: Edge Cases
- **Spec**: Handle no data, zero values
- **Implementation**: `percent_change` function handles edge cases
- **Status**: ✅ Complete

## Conclusion

The Time Period Comparison feature is **already fully implemented** in the codebase. All 10 functional requirements from the spec are satisfied by the existing code.

**Recommendation**: This feature requires no new implementation. Consider:
1. Running existing tests to verify functionality
2. Adding additional test coverage if needed
3. Any future enhancements should be treated as feature additions
