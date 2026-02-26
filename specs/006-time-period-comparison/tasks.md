# Tasks: Time Period Comparison

**Input**: Design documents from `/specs/006-time-period-comparison/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md

**Note**: This feature is already implemented in the codebase. The tasks below focus on verification and validation.

**Organization**: Tasks are grouped to verify each user story independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Verification Setup

**Purpose**: Verify the existing implementation against the specification

- [x] T001 Review existing implementation in lib/plausible/stats/comparisons.ex
- [x] T002 [P] Review existing frontend components in assets/js/dashboard/nav-menu/query-periods/comparison-period-menu.tsx

---

## Phase 2: User Story 1 Verification - Compare metrics between two date ranges (Priority: P1)

**Goal**: Verify that users can compare metrics between two date ranges with percentage change display

**Independent Test**: Select two date ranges and verify metrics display for both periods with accurate comparison values

### Verification Tasks

- [x] T003 [P] [US1] Verify current period selection in dashboard-period-menu.tsx works correctly
- [x] T004 [P] [US1] Verify comparison period selection in comparison-period-menu.tsx works correctly
- [x] T005 [US1] Verify percentage change calculation in metric-value.tsx matches formula: ((current - comparison) / comparison) × 100
- [x] T006 [US1] Verify visual indicators (green/red) display correctly in change-arrow.tsx

---

## Phase 3: User Story 2 Verification - Quick preset comparisons (Priority: P2)

**Goal**: Verify quick preset comparison options work correctly

**Independent Test**: Click each preset button and verify correct date range is applied

### Verification Tasks

- [x] T007 [P] [US2] Verify "vs Previous Period" preset in dashboard-time-periods.ts
- [x] T008 [P] [US2] Verify "vs Year over Year" preset in dashboard-time-periods.ts
- [x] T009 [US2] Verify "Custom" date range option in date-range-calendar.tsx

---

## Phase 4: User Story 3 Verification - Multiple metrics comparison (Priority: P3)

**Goal**: Verify multiple metrics display individual percentage changes

**Independent Test**: Select multiple metrics and verify each displays its own percentage change

### Verification Tasks

- [x] T010 [P] [US3] Verify each metric displays independent percentage change
- [x] T011 [US3] Verify "N/A" displays when comparison value is zero (division by zero)

---

## Phase 5: Edge Case Verification

**Purpose**: Verify edge cases from specification are handled correctly

- [x] T012 Verify division by zero displays "N/A" in metric-value.tsx
- [x] T013 [P] Verify date boundaries use calendar days (not 24-hour periods)
- [x] T014 Verify different period lengths handled correctly (no normalization)
- [x] T015 Verify negative values calculate percentage change correctly
- [x] T016 Verify URL persistence for comparison period settings

---

## Phase 6: Polish & Cross-Cutting Verification

**Purpose**: Final validation and documentation

- [x] T017 [P] Run existing ExUnit tests for comparisons module (Skipped - Elixir not available)
- [x] T018 [P] Run existing Jest tests for metric-value component
- [x] T019 Verify quickstart.md accurately describes the implemented feature
- [x] T020 Update quickstart.md with any discrepancies found during verification

---

## Dependencies & Execution Order

### Phase Dependencies

- **Verification Setup (Phase 1)**: No dependencies - can start immediately
- **User Story Verification (Phases 2-4)**: Can proceed in parallel after Phase 1
- **Edge Case Verification (Phase 5)**: Depends on Phases 2-4
- **Polish (Phase 6)**: Depends on all verification phases

### User Story Dependencies

- **User Story 1 (P1)**: Core functionality - verified first
- **User Story 2 (P2)**: Can verify in parallel with US1
- **User Story 3 (P3)**: Can verify in parallel with US1 and US2

### Parallel Opportunities

- All [P] tasks can run in parallel (different files, no dependencies)
- User story verifications can proceed in parallel

---

## Implementation Strategy

### Verification Approach

Since the feature is already implemented:

1. **Phase 1**: Review existing code to understand current implementation
2. **Phases 2-4**: Verify each user story independently
3. **Phase 5**: Verify edge cases
4. **Phase 6**: Run tests and finalize documentation

### Expected Outcome

- All functional requirements verified as working
- Any gaps documented for follow-up
- Tests passing
- Documentation accurate

---

## Notes

- Feature is already implemented - focus is on verification
- [P] tasks = different files, can run in parallel
- Each user story should be independently verifiable
- Commit after each verification or logical group
