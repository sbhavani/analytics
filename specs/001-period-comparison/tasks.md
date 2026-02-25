# Tasks: Time Period Comparison

**Feature**: Time Period Comparison
**Branch**: 001-period-comparison
**Generated**: 2026-02-25

## Overview

This feature is **already implemented** in the codebase. The tasks below focus on verification and testing to ensure the existing implementation meets all specification requirements.

## Implementation Strategy

Since the feature already exists, this task list focuses on:
1. **Verification**: Running existing tests to confirm functionality
2. **Validation**: Ensuring all spec requirements are met
3. **No new implementation required**

## Phase 1: Setup & Verification

### T001 Verify Existing Test Suite

**Goal**: Confirm existing tests pass

- [x] T001 Run JavaScript test suite for comparison components
  - File: `assets/js/dashboard/stats/reports/change-arrow.test.tsx`
  - Command: `npm test -- --testPathPattern="change-arrow"`
  - Verification: All tests pass

- [x] T002 Run JavaScript test suite for metric value components
  - File: `assets/js/dashboard/stats/reports/metric-value.test.tsx`
  - Command: `npm test -- --testPathPattern="metric-value"`
  - Verification: All tests pass

- [x] T003 Run JavaScript test suite for dashboard time periods
  - File: `assets/js/dashboard/dashboard-time-periods.test.ts`
  - Command: `npm test -- --testPathPattern="dashboard-time-periods"`
  - Verification: All tests pass

## Phase 2: Specification Verification

### T004 Verify Previous Period Comparison (US1)

**Goal**: Confirm previous period comparison works correctly

- [x] T004 [P] [US1] Verify ComparisonMode enum in dashboard-time-periods.ts
  - File: `assets/js/dashboard/dashboard-time-periods.ts` (lines 44-49)
  - Check: `previous_period` mode exists

- [ ] T005 [P] [US1] Verify comparison date calculation in backend
  - File: `lib/plausible/stats/comparisons.ex`
  - Check: Previous period calculation logic present

- [x] T006 [US1] Verify percentage change display for previous period
  - File: `assets/js/dashboard/stats/reports/metric-value.tsx`
  - Check: Comparison data rendered when previous_period enabled

### T007 Verify Year-over-Year Comparison (US2)

**Goal**: Confirm year-over-year comparison works correctly

- [x] T007 [P] [US2] Verify year_over_year mode in ComparisonMode enum
  - File: `assets/js/dashboard/dashboard-time-periods.ts` (lines 44-49)
  - Check: `year_over_year` mode exists

- [x] T008 [P] [US2] Verify year-over-year date calculation in backend
  - File: `lib/plausible/stats/comparisons.ex`
  - Check: Year shift logic present for YoY comparisons

- [x] T009 [US2] Verify leap year handling
  - File: `lib/plausible/stats/comparisons.ex`
  - Check: Correct date handling for February in leap years

### T010 Verify Custom Date Range Comparison (US3)

**Goal**: Confirm custom date range selection works

- [x] T010 [P] [US3] Verify custom comparison mode in enum
  - File: `assets/js/dashboard/dashboard-time-periods.ts` (lines 44-49)
  - Check: `custom` mode exists

- [x] T011 [P] [US3] Verify custom date picker functionality
  - File: `assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx`
  - Check: Custom date selection UI present

- [x] T012 [US3] Verify URL persistence for custom dates
  - File: `assets/js/dashboard/api.ts`
  - Check: `compare_from` and `compare_to` serialized to URL

### T013 Verify Match Day of Week Option (US4)

**Goal**: Confirm day-of-week matching works

- [x] T013 [P] [US4] Verify match day of week enum and storage
  - File: `assets/js/dashboard/dashboard-time-periods.ts` (lines 58-66)
  - Check: `ComparisonMatchMode` enum with `MatchDayOfWeek`

- [x] T014 [US4] Verify backend day-of-week matching logic
  - File: `lib/plausible/stats/comparisons.ex`
  - Check: `compare_match_day_of_week` parameter handling

### T015 Verify Visual Display (US5)

**Goal**: Confirm percentage changes display with correct styling

- [x] T015 [P] [US5] Verify ChangeArrow component
  - File: `assets/js/dashboard/stats/reports/change-arrow.tsx`
  - Check: Color logic for positive (green) and negative (red) changes

- [x] T016 [P] [US5] Verify bounce rate inversion
  - File: `assets/js/dashboard/stats/reports/change-arrow.tsx` (lines 30-35)
  - Check: Bounce rate decrease shows as positive (green)

- [x] T017 [US5] Verify metric value rendering with comparison
  - File: `assets/js/dashboard/stats/reports/metric-value.tsx`
  - Check: Comparison value and change displayed

## Phase 3: Edge Cases & Polish

### T018 Verify Edge Case Handling

**Goal**: Confirm edge cases are handled correctly

- [x] T018 [P] Verify zero-value comparison handling
  - File: `lib/plausible/stats/compare.ex`
  - Check: `percent_change` function handles 0/0 and non-zero/0 cases

- [x] T019 [P] Verify no-data handling
  - Files: `assets/js/dashboard/stats/reports/metric-value.tsx`
  - Check: Displays "-" or "N/A" when comparison data missing

- [x] T020 Verify URL state restoration
  - File: `assets/js/dashboard/dashboard-state.ts`
  - Check: Comparison state restored from URL on page load

## Dependencies

```
Phase 1 (Setup)
  └── T001, T002, T003 (run tests in parallel)

Phase 2 (Specification Verification)
  ├── T004, T005, T006 (US1 - Previous Period)
  ├── T007, T008, T009 (US2 - Year over Year)
  ├── T010, T011, T012 (US3 - Custom Range)
  ├── T013, T014 (US4 - Match Day of Week)
  └── T015, T016, T017 (US5 - Visual Display)

Phase 3 (Edge Cases)
  └── T018, T019, T020 (all can run in parallel)
```

## Parallel Opportunities

| Tasks | Reason |
|-------|--------|
| T001, T002, T003 | Different test files, no dependencies |
| T004, T005 | Different files (enum vs backend) |
| T007, T008 | Different files (enum vs backend) |
| T010, T011 | Different files (enum vs UI) |
| T013, T014 | Different files (frontend vs backend) |
| T015, T016 | Different components |
| T018, T019, T020 | Different edge case scenarios |

## Independent Test Criteria

Each user story can be verified independently:

- **US1 (Previous Period)**: Select any period, enable "Previous period", verify percentage changes display
- **US2 (Year over Year)**: Select any period, enable "Year over year", verify percentage changes display
- **US3 (Custom Range)**: Select custom comparison dates, verify metrics compared against those dates
- **US4 (Match Day of Week)**: Toggle "Match day of week" option, verify comparison adjusts
- **US5 (Visual Display)**: Enable any comparison, verify green/red arrows and percentages

## MVP Scope

Since the feature is already implemented, the **MVP verification** is:

- **T001-T003**: Run existing tests → All pass = MVP verified
- If tests pass, the core functionality works

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 20 |
| User Stories Covered | 5 (US1-US5) |
| Parallelizable Tasks | 12 |
| Verification Tasks | 20 |
| Implementation Tasks | 0 (already implemented) |

**Note**: This feature is already fully implemented. All tasks are verification-focused to ensure the existing code meets the specification requirements.
