# Tasks: Time Period Comparison

**Input**: Design documents from `/specs/002-period-comparison/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Tests**: Tests are REQUIRED per Constitution II - Test-Driven Development

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization - confirm existing project structure is ready

- [X] T001 Verify existing Phoenix project structure in lib/plausible/
- [X] T002 Verify existing React project structure in assets/src/
- [X] T003 Verify ClickHouse adapter is available for analytics queries

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

- [X] T004 [P] Create PeriodComparison context module in lib/plausible/stats/period_comparison.ex
- [X] T005 [P] Implement date range calculation logic for predefined periods in lib/plausible/stats/period_comparison.ex
- [X] T006 Implement percentage change calculation in lib/plausible/stats/period_comparison.ex
- [X] T007 [P] Add GET /api/stats/compare endpoint to stats controller
- [X] T008 [P] Add GET /api/periods/predefined endpoint to stats controller

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Compare Metrics Between Two Periods (Priority: P1) 🎯 MVP

**Goal**: Users can compare metrics between two date ranges with percentage change display

**Independent Test**: Select two date ranges and verify metrics displayed for both periods with accurate percentage change calculations

### Tests for User Story 1 (REQUIRED per Constitution) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T010 [P] [US1] ExUnit test for percentage change calculation in test/plausible/stats/period_comparison_test.exs
- [X] T011 [P] [US1] ExUnit test for date range validation in test/plausible/stats/period_comparison_test.exs
- [X] T012 [P] [US1] Jest test for ComparisonView component in assets/test/components/ComparisonView.test.tsx

### Implementation for User Story 1

- [X] T013 [P] [US1] Implement date range query logic for primary period in lib/plausible/stats/period_comparison.ex
- [X] T014 [P] [US1] Implement date range query logic for comparison period in lib/plausible/stats/period_comparison.ex
- [X] T015 [US1] Create ComparisonView React component in assets/src/components/ComparisonView.tsx
- [X] T016 [US1] Implement percentage indicator with color coding in assets/src/components/PercentageIndicator.tsx
- [X] T017 [US1] Connect frontend to /api/stats/compare endpoint
- [X] T018 [US1] Add validation for date ranges (start <= end, max 366 days)
- [X] T019 [US1] Add logging for comparison operations

**Checkpoint**: User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Quick Period Selection (Priority: P2)

**Goal**: Users can quickly select predefined period options without manually entering dates

**Independent Test**: Click predefined options (This Week vs Last Week) and verify correct date ranges applied

### Tests for User Story 2 (REQUIRED) ⚠️

- [X] T020 [P] [US2] ExUnit test for predefined period date calculations in test/plausible/stats/period_comparison_test.exs
- [X] T021 [P] [US2] Jest test for PeriodPicker component in assets/test/components/PeriodPicker.test.tsx

### Implementation for User Story 2

- [X] T022 [P] [US2] Implement predefined period options (This/Last Week, Month, Quarter, Year) in lib/plausible/stats/period_comparison.ex
- [X] T023 [P] [US2] Create PeriodPicker React component in assets/js/dashboard/components/period-picker.tsx
- [X] T024 [US2] Add predefined period selection to dashboard UI
- [X] T025 [US2] Integrate PeriodPicker with ComparisonView

**Checkpoint**: User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Understand Change Direction (Priority: P3)

**Goal**: Users can clearly see whether metrics increased or decreased with visual indicators

**Independent Test**: Create comparisons with known positive/negative changes and verify visual indicators match expected direction

### Tests for User Story 3 (REQUIRED) ⚠️

- [X] T026 [P] [US3] ExUnit test for zero value handling (N/A display) in test/plausible/stats/period_comparison_test.exs
- [X] T027 [P] [US3] Jest test for edge case display in assets/test/components/PercentageIndicator.test.tsx

### Implementation for User Story 3

- [X] T028 [P] [US3] Implement zero value handling (display "N/A") in lib/plausible/stats/period_comparison.ex
- [X] T029 [P] [US3] Implement "no data available" display in assets/src/components/ComparisonView.tsx
- [X] T030 [US3] Add color-coded indicators (green for increase, red for decrease)
- [X] T031 [US3] Verify all edge cases are handled properly

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T032 [P] Add E2E test for full period comparison flow in e2e/tests/period_comparison.spec.ts
- [X] T033 Run Credo linting for Elixir code
- [X] T034 Run ESLint/Prettier for TypeScript code
- [X] T035 Performance validation - ensure queries complete in under 1 second
- [X] T036 Update documentation in quickstart.md with implementation notes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Phase 6)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - Should be independently testable from US1
- **User Story 3 (P3)**: Can start after Foundational (Phase 2) - Should be independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation (Constitution II)
- Backend logic before frontend components
- Core implementation before edge cases
- Story complete before moving to next priority

### Parallel Opportunities

- T004, T005, T007, T008 can run in parallel (different modules)
- T010, T011, T012 can run in parallel (different test files)
- T013, T014, T015 can run in parallel (different components)
- T022, T023 can run in parallel (different implementations)
- T028, T029 can run in parallel (different edge case handlers)

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 36 |
| Setup Phase | 3 |
| Foundational Phase | 5 |
| User Story 1 (P1) | 10 |
| User Story 2 (P2) | 6 |
| User Story 3 (P3) | 6 |
| Polish Phase | 5 |
| Parallelizable Tasks | 16 |

**Suggested MVP Scope**: Complete Phases 1-3 (Setup + Foundational + User Story 1) for initial release

**Independent Test Criteria per Story**:
- US1: Can compare two date ranges and see percentage change
- US2: Can select predefined periods with one click
- US3: Can interpret comparison results via visual indicators
