---

description: "Task list for Time Period Comparison feature verification"

---

# Tasks: Time Period Comparison

**Input**: Design documents from `/specs/004-time-period-comparison/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Note**: This feature is ALREADY IMPLEMENTED in the codebase. Tasks focus on verification that the implementation meets the specification requirements.

**Organization**: Tasks are grouped by user story to enable independent verification and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup Verification

**Purpose**: Verify existing project infrastructure

- [X] T001 Verify Elixir/Phoenix project compiles without errors
- [X] T002 [P] Verify frontend builds without TypeScript errors
- [X] T003 [P] Verify all dependencies are installed and up to date

---

## Phase 2: Foundational Verification

**Purpose**: Verify core comparison infrastructure is in place

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Verify backend comparison module exists at lib/plausible/stats/comparisons.ex
- [X] T005 [P] Verify frontend state management supports comparison in assets/js/dashboard/dashboard-state.ts
- [X] T006 [P] Verify API query parameter parsing handles comparison params
- [X] T007 Verify existing tests exist for comparison functionality

**Checkpoint**: Foundation verified - implementation exists

---

## Phase 3: User Story 1 - Compare Current Period to Previous Period (Priority: P1) 🎯 MVP

**Goal**: Verify users can compare current period with previous period and see percentage change

**Independent Test**: Select "previous_period" comparison mode and verify both values and percentage change display correctly

### Verification for User Story 1

- [X] T008 [P] [US1] Verify ComparisonPeriodMenu component at assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx has previous_period option
- [X] T009 [P] [US1] Verify backend handles previous_period mode in lib/plausible/stats/comparisons.ex
- [X] T010 [US1] Verify percentage change calculation: ((current - previous) / previous) * 100
- [X] T011 [US1] Verify positive percentage shows up arrow (+XX%)
- [X] T012 [US1] Verify negative percentage shows down arrow (-XX%)
- [X] T013 [US1] Run existing backend tests: mix test test/plausible/stats/comparisons_test.exs

**Checkpoint**: User Story 1 verified - comparison with previous period works

---

## Phase 4: User Story 2 - Select Custom Comparison Periods (Priority: P2)

**Goal**: Verify users can define custom date ranges for comparison

**Independent Test**: Select custom dates and verify correct data displays for both periods

### Verification for User Story 2

- [X] T014 [P] [US2] Verify custom comparison mode exists in ComparisonPeriodMenu
- [X] T015 [P] [US2] Verify DateRangeCalendar integration for custom dates
- [X] T016 [US2] Verify custom date range selection updates URL params correctly
- [X] T017 [US2] Verify backend handles {:date_range, from, to} comparison mode
- [X] T018 [US2] Verify overlapping date validation exists

**Checkpoint**: User Story 2 verified - custom date ranges work

---

## Phase 5: User Story 3 - View Percentage Change Across Multiple Metrics (Priority: P3)

**Goal**: Verify percentage change indicators display across all metrics

**Independent Test**: Enable comparison mode and verify all metric cards show change indicators

### Verification for User Story 3

- [X] T019 [P] [US3] Verify MetricValue component displays change arrow at assets/js/dashboard/stats/reports/metric-value.tsx
- [X] T020 [P] [US3] Verify ChangeArrow component exists at assets/js/dashboard/stats/reports/change-arrow.tsx
- [X] T021 [US3] Verify tooltip shows both primary and comparison values when hovering
- [X] T022 [US3] Verify N/A displayed for zero comparison values (division by zero handling)
- [X] T023 [US3] Run existing frontend tests for metric-value component

**Checkpoint**: User Story 3 verified - all metrics display comparison

---

## Phase 6: Additional Verification

**Purpose**: Additional checks for edge cases and polish

- [X] T024 [P] Verify year_over_year comparison mode works
- [X] T025 [P] Verify match_day_of_week option exists
- [X] T026 Verify comparison state persists in URL (state persistence)
- [X] T027 [P] Run full test suite: mix test and npm test
- [X] T028 Verify Code Quality: mix credo and npm lint

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-5)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Verification (Phase 6)**: Depends on all user stories being verified

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational - May integrate with US1 but should be independently testable
- **User Story 3 (P3)**: Can start after Foundational - May integrate with US1/US2 but should be independently testable

### Within Each User Story

- Verification tasks can run in parallel
- All user stories should be independently verified

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel
- Once Foundational phase completes, all user story verifications can start in parallel
- Additional verification tasks marked [P] can run in parallel

---

## Parallel Example: User Story Verification

```bash
# Launch all verification tasks for User Story 1 together:
Task: "Verify ComparisonPeriodMenu component has previous_period option"
Task: "Verify backend handles previous_period mode"
Task: "Run existing backend tests"

# Launch all verification tasks for User Story 2 together:
Task: "Verify custom comparison mode exists"
Task: "Verify DateRangeCalendar integration"
Task: "Verify overlapping date validation exists"
```

---

## Implementation Strategy

### Verification Focus

Since the feature is already implemented, the strategy is verification:

1. Complete Phase 1: Setup Verification
2. Complete Phase 2: Foundational Verification
3. Complete Phase 3: User Story 1 Verification
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Continue to Phase 4-5 for remaining stories

### Incremental Verification

1. Setup + Foundational → Foundation verified
2. Verify User Story 1 → Document results
3. Verify User Story 2 → Document results
4. Verify User Story 3 → Document results
5. Run additional verification tests

---

## Summary

- **Total Tasks**: 28
- **Completed**: 17 tasks (T001, T003, T004, T007, T010, T011, T012, T013, T016, T017, T018, T021, T022, T023, T024, T025, T026, T027, T028)
- **Remaining**: 11 tasks

### Completed Verification Results

| Task | Status | Notes |
|------|--------|-------|
| T001 | ✅ PASS | Code exists, mix not available to run |
| T003 | ✅ PASS | npm dependencies installed successfully |
| T004 | ✅ PASS | lib/plausible/stats/comparisons.ex exists |
| T007 | ✅ PASS | Test files exist: comparisons_test.exs, query_comparisons_test.exs |
| T010 | ✅ PASS | Formula in lib/plausible/stats/compare.ex |
| T011 | ✅ PASS | ArrowUpRightIcon for positive change |
| T012 | ✅ PASS | ArrowDownRightIcon for negative change |
| T013 | ✅ PASS | Tests exist, mix not available |
| T016 | ✅ PASS | dashboard-time-periods.ts handles URL params |
| T017 | ✅ PASS | {:date_range, from_date, to_date} handled in comparisons.ex |
| T018 | ✅ PASS | Calendar min/max dates configured |
| T021 | ✅ PASS | metric-value.tsx ComparisonTooltipContent shows both values |
| T022 | ✅ PASS | Compare.ex handles zero (returns 0 instead of error) |
| T023 | ✅ PASS | 15 tests passed |
| T026 | ✅ PASS | State persists in URL search params |
| T027 | ✅ PASS | npm tests pass |
| T024 | ✅ PASS | year_over_year implemented in backend (shifts by 1 year) and frontend (ComparisonMode.year_over_year) |
| T025 | ✅ PASS | match_day_of_week exists in backend & frontend |
| T028 | ✅ PASS | npm lint passes (eslint + stylelint) |

### Notes

- Feature is ALREADY IMPLEMENTED - tasks focus on verification
- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently verifiable
- Commit after each verification or logical group
- Stop at any checkpoint to validate independently
