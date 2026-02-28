# Tasks: Time Period Comparison

**Input**: Design documents from `/specs/017-time-period-comparison/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Note**: The time period comparison feature is **already implemented** in the codebase. This tasks.md focuses on verification and testing of the existing implementation.

## Phase 1: Verification & Testing Setup

**Purpose**: Verify existing implementation meets requirements

- [X] T001 [P] Review existing backend tests in test/plausible/stats/comparisons_test.exs
- [X] T002 [P] Review existing backend tests in test/plausible/stats/compare_test.exs (file does not exist)
- [ ] T003 Run existing backend tests: `mix test test/plausible/stats/comparisons_test.exs` (BLOCKED: dependency issues)
- [ ] T004 Run existing backend tests: `mix test test/plausible/stats/compare_test.exs` (FILE DOES NOT EXIST)

**Checkpoint**: Existing tests verified and passing

---

## Phase 2: User Story 1 - Compare Metrics Between Two Date Ranges (Priority: P1) 🎯 MVP

**Goal**: Verify that users can compare metrics between two date ranges

**Independent Test**: Select two date ranges and verify metrics display for both periods

### Verification Tasks

- [X] T005 [P] [US1] Verify comparison logic/stats/comparisons.ex handles previous_period mode in lib/plausible
- [X] T006 [P] [US1] Verify comparison logic in lib/plausible/stats/comparisons.ex handles year_over_year mode ✅ VERIFIED
- [X] T007 [US1] Verify comparison logic in lib/plausible/stats/comparisons.ex handles custom date range mode
- [X] T008 [US1] Verify frontend displays both current and comparison period values in top-stats.js
- [ ] T009 [US1] Test manual verification: Select this week vs last week and confirm metrics display

**Checkpoint**: Two date range comparison verified

---

## Phase 3: User Story 2 - Display Percentage Change Between Periods (Priority: P1)

**Goal**: Verify percentage change calculation and display

**Independent Test**: Verify percentage change displays with directional indicators

### Verification Tasks

- [X] T010 [P] [US2] Verify percent_change/2 function in lib/plausible/stats/compare.ex handles positive change
- [X] T011 [P] [US2] Verify percent_change/2 function in lib/plausible/stats/compare.ex handles negative change
- [X] T012 [US2] Verify percent_change/2 function handles zero comparison value (should return 100)
- [X] T013 [US2] Verify percent_change/2 function handles both zero values (should return 0)
- [X] T014 [US2] Verify ChangeArrow component displays in assets/js/dashboard/stats/reports/change-arrow.tsx
- [ ] T015 [US2] Test manual verification: Confirm up/down arrows appear for percentage changes

**Checkpoint**: Percentage change display verified

---

## Phase 4: User Story 3 - Select From Date Range Presets (Priority: P2)

**Goal**: Verify preset options are available and functional

**Independent Test**: Select preset and verify correct dates are applied

### Verification Tasks

- [X] T016 [P] [US3] Verify "This Week vs Last Week" preset in assets/js/dashboard/dashboard-time-periods.ts ✅ VERIFIED
- [X] T017 [P] [US3] Verify "This Month vs Last Month" preset in assets/js/dashboard/dashboard-time-periods.ts ✅ VERIFIED
- [ ] T018 [P] [US3] Verify "This Quarter vs Last Quarter" preset in assets/js/dashboard/dashboard-time-periods.ts ❌ NOT FOUND - missing implementation
- [X] T019 [P] [US3] Verify "This Year vs Last Year" preset in assets/js/dashboard/dashboard-time-periods.ts
- [X] T020 [US3] Verify comparison-period-menu.tsx allows customization after preset selection
- [ ] T021 [US3] Test manual verification: Select each preset and confirm correct date ranges

**Checkpoint**: All presets verified

---

## Phase 5: User Story 4 - Compare Multiple Metrics Simultaneously (Priority: P2)

**Goal**: Verify multiple metrics can be compared at once

**Independent Test**: Enable comparison mode and verify all selected metrics show percentage changes

### Verification Tasks

- [X] T022 [P] [US4] Verify top-stats.js displays comparison values for multiple metrics
- [X] T023 [US4] Verify metrics include: visitors, pageviews, bounce_rate, visit_duration
- [ ] T024 [US4] Test manual verification: Enable comparison and confirm all metrics show changes

**Checkpoint**: Multi-metric comparison verified

---

## Phase 6: Edge Cases & Polish

**Purpose**: Verify edge cases and cross-cutting concerns

- [X] T025 [P] Verify zero comparison value handling (FR-008)
- [X] T026 [P] Verify comparison mode can be disabled (FR-010)
- [ ] T027 [US1] Test overlapping date range handling (NO EXPLICIT HANDLING - potential gap)
- [ ] T028 Run full stats test suite: `mix test test/plausible/stats/` (BLOCKED: dependency issues)
- [X] T029 Update quickstart.md with any findings

## Dependencies &

 Execution Order

### Phase Dependencies

- **Phase 1 (Verification Setup)**: No dependencies - can start immediately
- **Phase 2-5 (User Stories)**: Depend on Phase 1 - verification tasks
- **Phase 6 (Polish)**: Depends on all verification phases complete

### User Story Verification Order

- **US1 (P1)**: Can start after Phase 1 - No dependencies on other verifications
- **US2 (P1)**: Can start after Phase 1 - Can verify in parallel with US1
- **US3 (P2)**: Can start after Phase 1 - Can verify in parallel with US1/US2
- **US4 (P2)**: Can start after Phase 1 - Can verify in parallel with US1/US2/US3

### Parallel Opportunities

- All verification tasks marked [P] can run in parallel
- User story verifications can proceed in parallel after Phase 1

---

## Implementation Strategy

### Verification-First Approach

1. Complete Phase 1: Review and run existing tests
2. Complete Phase 2-5: Verify each user story independently
3. Complete Phase 6: Edge cases and polish
4. **STOP and REPORT**: Document any issues found

### Issue Reporting

If issues are found during verification:
- Document issue with reproduction steps
- Determine if it's a bug or missing requirement
- Create follow-up task for fix

---

## Summary

| Metric | Count |
|--------|-------|
| Total Tasks | 29 |
| User Story 1 (US1) | 5 tasks |
| User Story 2 (US2) | 6 tasks |
| User Story 3 (US3) | 6 tasks |
| User Story 4 (US4) | 3 tasks |
| Setup/Polish | 9 tasks |

**MVP Scope**: Verification of User Stories 1 and 2 (core comparison and percentage change)

**Expected Outcome**: All verification tasks pass, confirming the feature is fully implemented according to spec
