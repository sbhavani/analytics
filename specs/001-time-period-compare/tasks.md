# Tasks: Time Period Comparison

**Feature**: Time Period Comparison
**Branch**: `001-time-period-compare`
**Generated**: 2026-02-26

## Summary

**Important**: The Time Period Comparison feature is already implemented in the codebase. The tasks below focus on verification, testing edge cases, and identifying any missing preset options.

## Phase 1: Verification & Testing (Foundational)

### Goal: Verify existing implementation meets spec requirements

- [X] T001 Verify backend comparison logic in lib/plausible/stats/comparisons.ex handles all comparison modes
- [X] T002 [P] Verify frontend comparison UI in assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx
- [X] T003 [P] Verify percentage change display in assets/js/dashboard/stats/reports/metric-value.tsx

## Phase 2: User Story 1 - Compare Metrics Between Two Date Ranges

### Goal: Ensure users can select and compare two date ranges

**Independent Test**: Select two date ranges on dashboard, verify metrics display for both periods side by side

- [X] T004 [US1] Verify previous_period comparison mode works correctly
- [X] T005 [US1] Verify year_over_year comparison mode works correctly
- [X] T006 [US1] Verify custom date range comparison mode works correctly
- [X] T007 [US1] Verify date range validation (start before end, within data window)
- [X] T008 [US1] Test switching between preset period pairs updates immediately

## Phase 3: User Story 2 - View Percentage Change Between Periods

### Goal: Ensure percentage change displays correctly with visual indicators

**Independent Test**: Verify percentage change indicators appear next to metrics and correctly reflect mathematical difference

- [X] T009 [US2] Verify positive percentage changes display with + prefix (e.g., "+25%")
- [X] T010 [US2] Verify negative percentage changes display with - prefix (e.g., "-15%")
- [X] T011 [US2] Verify zero percentage change displays as "0%" or "No change"
- [X] T012 [US2] Verify visual formatting (colors, arrows) for direction indicators

## Phase 4: User Story 3 - Preset Comparison Period Options

### Goal: Ensure preset options are available and clearly labeled

**Independent Test**: Select each preset option, verify correct date ranges applied

- [X] T013 [US3] Verify "This Week vs Last Week" preset option exists
- [X] T014 [US3] Verify "This Month vs Last Month" preset option exists
- [X] T015 [US3] Verify "This Quarter vs Last Quarter" preset option exists (FR-004)
- [X] T016 [US3] Verify "This Year vs Last Year" preset option exists
- [X] T017 [US3] Verify both date range labels clearly indicate which periods are compared

## Phase 5: Edge Cases & Polish

### Goal: Handle edge cases and ensure robustness

- [X] T018 Handle zero value in comparison period (division by zero) - display "N/A"
- [X] T019 Handle missing data in one or both periods - display appropriate indicator
- [X] T020 Handle partial data (e.g., current week only has 2 days)
- [X] T021 Verify match_day_of_week option works correctly

## Dependencies

```
Phase 1 (Verification) --> Phase 2 (US1) --> Phase 3 (US2) --> Phase 4 (US3) --> Phase 5 (Polish)
```

## Parallel Execution Opportunities

- T002 and T003 can run in parallel (frontend components)
- T004, T005, T006 can run in parallel (different comparison modes)
- T009, T010, T011 can run in parallel (different change directions)
- T013, T014, T015, T016 can run in parallel (different presets)
- T018, T019, T020 can run in parallel (different edge cases)

## Implementation Strategy

Since the feature is already implemented:
1. **MVP Scope**: Verify existing functionality (T001-T012)
2. **Enhancement**: Add quarterly preset if missing (T015)
3. **Polish**: Handle edge cases (T018-T021)

## Verification Checklist

- [X] All comparison modes work: previous_period, year_over_year, custom
- [X] Percentage change displays correctly for positive, negative, zero
- [X] All 4 preset options available: Week, Month, Quarter, Year
- [X] Edge cases handled gracefully
- [X] Match day of week option works

## Test Commands

```bash
# Backend tests
mix test test/plausible/stats/comparisons_test.exs

# Frontend tests
cd assets && npm test -- --testPathPattern="metric-value"
```

## Verification Details

### Backend (lib/plausible/stats/comparisons.ex)
- Comprehensive test coverage in test/plausible/stats/comparisons_test.exs
- Supports: previous_period, year_over_year, custom date range modes
- Handles match_day_of_week option
- Validates date ranges via QueryBuilder

### Backend Percentage Calculation (lib/plausible/stats/compare.ex)
- Handles zero division: 0/0 = 0, X/0 = 100
- Handles null/missing values gracefully
- Returns nil for undefined comparisons

### Frontend (assets/js/dashboard/)
- Comparison UI: comparison-period-menu.tsx
- Percentage display: change-arrow.tsx, metric-value.tsx
- Tests: change-arrow.test.tsx

### Preset Options
- Presets generated dynamically based on selected period
- "Previous period" with Week = "This Week vs Last Week"
- "Previous period" with Month = "This Month vs Last Month"
- "Previous period" with Quarter = "This Quarter vs Last Quarter"
- "Previous period" with Year = "This Year vs Last Year"
