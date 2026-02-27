# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Branch**: 015-advanced-filter-builder
**Generated**: 2026-02-27

## Implementation Strategy

**MVP Scope**: User Story 1 (Single Filter) - Provides foundational filter functionality
**Incremental Delivery**: Each user story builds on the previous, enabling progressive enhancement

---

## Phase 1: Setup

- [x] T001 Create project directory structure for new filter builder in `assets/js/dashboard/filtering/new-filter-builder/`

---

## Phase 2: Foundational

- [x] T002 [P] Define TypeScript types for FilterCondition, FilterGroup, FilterTree in `assets/js/dashboard/filtering/new-filter-builder/types.ts`
- [x] T003 [P] Create filter tree utility functions (create, add, remove, update) in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts`
- [x] T004 Write Jest tests for filterTreeUtils in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.test.ts`
- [x] T005 Create serialization utilities to convert filter tree to/from legacy flat filter array in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts`
- [x] T006 [P] Extend DashboardState type to include optional filterTree in `assets/js/dashboard/dashboard-state.ts`

---

## Phase 3: User Story 1 - Build Simple Single Filter (P1)

**Goal**: Allow users to add a single filter condition
**Independent Test**: Add one filter and verify dashboard updates

**Implementation**:

- [x] T007 [P] [US1] Create FilterBuilder container component in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx`
- [x] T008 [P] [US1] Create FilterCondition row component in `assets/js/dashboard/filtering/new-filter-builder/ConditionRow.tsx`
- [x] T009 [P] [US1] Create DimensionSelector dropdown component in `assets/js/dashboard/filtering/new-filter-builder/DimensionSelector.tsx`
- [x] T010 [P] [US1] Create OperatorSelector component in `assets/js/dashboard/filtering/new-filter-builder/OperatorSelector.tsx` (completed)
- [x] T011 [P] [US1] Create FilterValueInput component for value entry in `assets/js/dashboard/filtering/new-filter-builder/FilterValueInput.tsx`
- [x] T012 [US1] Implement FilterBuilderContext for state management in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`
- [x] T013 [US1] Write component tests for FilterBuilder in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.test.tsx`
- [x] T014 [US1] Create module export entry point in `assets/js/dashboard/filtering/new-filter-builder/index.ts`

---

## Phase 4: User Story 2 - Combine Multiple Filters with AND Logic (P1)

**Goal**: Allow users to add multiple filters combined with AND
**Independent Test**: Add two filters with AND grouping and verify results

**Implementation**:

- [x] T015 [US2] Implement addCondition function in filterTreeUtils to append to root group
- [x] T016 [US2] Update FilterBuilder to render list of FilterCondition components
- [x] T017 [US2] Add remove filter functionality to ConditionRow component
- [x] T018 [US2] Add filter count display and apply button to FilterBuilder

---

## Phase 5: User Story 3 - Combine Multiple Filters with OR Logic (P2)

**Goal**: Allow users to switch between AND and OR operators
**Independent Test**: Change operator and verify dashboard shows matching results

**Implementation**:

- [x] T019 [P] [US3] Create FilterGroup component for rendering AND/OR toggle in `assets/js/dashboard/filtering/new-filter-builder/ConditionGroup.tsx`
- [x] T020 [US3] Implement group operator toggle (AND/OR) in FilterGroup component
- [x] T021 [US3] Update filterTreeUtils with changeGroupOperator function

---

## Phase 6: User Story 4 - Create Nested Filter Groups (P2)

**Goal**: Support nested groups with different AND/OR operators up to 3 levels
**Independent Test**: Create nested groups and verify boolean logic

**Implementation**:

- [x] T022 [US4] Implement addGroup function in filterTreeUtils for nesting
- [x] T023 [US4] Add UI for creating nested groups in FilterGroup component
- [x] T024 [US4] Add depth validation (max 3 levels) in filterTreeUtils
- [x] T025 [US4] Implement visual hierarchy display for nested groups

---

## Phase 7: User Story 5 - Save and Reuse Filter Segments (P3)

**Goal**: Save filter configurations as named segments
**Independent Test**: Save segment, clear filters, load segment and verify restored

**Implementation**:

- [x] T026 [P] [US5] Create SaveTemplateModal component in `assets/js/dashboard/filtering/new-filter-builder/SaveTemplateModal.tsx`
- [x] T027 [US5] Implement segment save API call using existing segments-context
- [x] T028 [P] [US5] Create LoadTemplateDropdown component in `assets/js/dashboard/filtering/new-filter-builder/LoadTemplateDropdown.tsx`
- [x] T029 [US5] Implement segment load functionality to populate filter tree

---

## Phase 8: User Story 6 - Edit and Remove Filter Groups (P2)

**Goal**: Allow editing and removing entire filter groups
**Independent Test**: Edit group operator, delete group, undo action

**Implementation**:

- [x] T030 [US6] Add edit group operator UI in FilterGroup component
- [x] T031 [US6] Implement deleteGroup function in filterTreeUtils
- [x] T032 [US6] Add undo functionality for deleted groups

---

## Phase 9: Backend Integration

- [x] T033 Create Elixir filter tree parser in `lib/plausible/segments/filter_tree.ex`
- [x] T034 Add filter tree validation to segment schema in `lib/plausible/segments/segment.ex`
- [x] T035 Write ExUnit tests for filter_tree.ex in `test/plausible/segments/filter_tree_test.exs`

---

## Phase 10: Polish & Cross-Cutting Concerns

- [x] T036 [P] Add FilterSummary component to display current filter state in `assets/js/dashboard/filtering/new-filter-builder/FilterSummary.tsx`
- [x] T037 Add clear all filters functionality
- [x] T038 Implement validation error display for invalid filter configurations
- [x] T039 Add drag-and-drop reordering support for filters
- [ ] T040 Integrate FilterBuilder with existing dashboard filters-bar
- [ ] T041 End-to-end testing of full filter workflow

---

## Dependencies

```
Phase 1 (Setup)
  └── All Subsequent Phases

Phase 2 (Foundational)
  ├── T002 → T003 → T004 → T005
  └── T006 (independent)

Phase 3 (US1: Single Filter)
  └── Phase 2
  ├── T007 → T008 → T009 → T010 → T011 → T012 → T013 → T014

Phase 4 (US2: AND Logic)
  └── Phase 3
  └── T015 → T016 → T017 → T018

Phase 5 (US3: OR Logic)
  └── Phase 4
  └── T019 → T020 → T021

Phase 6 (US4: Nested Groups)
  └── Phase 5
  └── T022 → T023 → T024 → T025

Phase 7 (US5: Save/Load Segments)
  └── Phase 6
  └── T026 → T027 → T028 → T029

Phase 8 (US6: Edit/Remove Groups)
  └── Phase 7
  └── T030 → T031 → T032

Phase 9 (Backend)
  └── Phase 2
  └── T033 → T034 → T035

Phase 10 (Polish)
  └── All Previous Phases
```

---

## Parallel Opportunities

**Parallel Group A** (Frontend Components):
- T002, T003, T006 can run in parallel (different files)

**Parallel Group B** (US1 Components):
- T007, T008, T009, T010, T011 can run in parallel (different components)

**Parallel Group C** (US5 Components):
- T026, T028 can run in parallel (different components)

---

## Test Criteria Summary

| User Story | Independent Test |
|------------|------------------|
| US1 | Add one filter, verify dashboard updates |
| US2 | Add two filters with AND, verify matching results |
| US3 | Toggle OR operator, verify any-match results |
| US4 | Create nested groups, verify boolean logic |
| US5 | Save segment, load segment, verify restored |
| US6 | Edit operator, delete group, verify changes |

---

## Notes

- Tests are REQUIRED per Constitution II (TDD)
- Backend integration (Phase 9) can happen in parallel with frontend phases once types and utilities are ready
- End-to-end testing in final phase ensures all pieces work together
