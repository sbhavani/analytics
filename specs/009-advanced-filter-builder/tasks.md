# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Generated**: 2026-02-26
**Source**: [spec.md](./spec.md), [plan.md](./plan.md), [data-model.md](./data-model.md)

## Implementation Strategy

**MVP Scope**: User Story 1 (Single-condition filter) - core filter builder functionality
**Delivery**: Incremental by user story priority

### Dependencies

```
Setup (Phase 1)
    │
    ▼
Foundational (Phase 2)
    │
    ├──► US1 - Single Condition Filter ◄── (MVP - Priority)
    │
    ├──► US2 - AND Logic
    │
    ├──► US3 - OR Logic
    │
    ├──► US5 - Save/Edit/Delete Segments
    │
    ├──► US4 - Nested Groups (P2)
    │
    └──► US6 - Visual Feedback (P2)

Polish (Final Phase)
```

### Parallel Opportunities

- US2 and US3 can be developed in parallel (different logic types)
- US4 depends on completing US1 first
- US5 is independent after foundational phase
- US6 builds on top of US1-US3

---

## Phase 1: Setup

- [X] T001 Review existing Segment implementation in lib/plausible/segments/segment.ex
- [X] T002 Review existing filter query builder in lib/plausible/stats/sql/where_builder.ex
- [X] T003 Review existing stats API controller in lib/plausible_web/controllers/api/stats_controller.ex
- [X] T004 Review existing frontend filter utilities in assets/js/dashboard/util/filters.ts
- [X] T005 Review existing React components structure in assets/js/dashboard/components/

---

## Phase 2: Foundational

- [X] T006 [P] Create TypeScript types for FilterCondition and FilterGroup in assets/js/types/filter-builder.ts
- [X] T007 [P] Create visitor attributes configuration with operators in assets/js/dashboard/util/filter-attributes.ts
- [X] T008 Create API client functions for segment CRUD operations in assets/js/dashboard/api/segments.ts
- [X] T009 Create useFilterBuilder React hook for state management in assets/js/dashboard/hooks/useFilterBuilder.ts
- [X] T010 Add filter-to-query-parser utility to convert filter groups to existing API format in assets/js/dashboard/util/filter-query-parser.ts

---

## Phase 3: User Story 1 - Single Condition Filter

**Goal**: Allow users to create a filter with a single condition

**Independent Test**: Add one condition, see live preview of matching visitors, confirm segment appears in saved list

### Implementation

- [X] T011 [US1] Create FilterConditionRow component for single condition in assets/js/dashboard/components/FilterBuilder/FilterConditionRow.tsx
- [X] T012 [US1] Create attribute selector dropdown in assets/js/dashboard/components/FilterBuilder/AttributeSelector.tsx
- [X] T013 [US1] Create operator selector dropdown in assets/js/dashboard/components/FilterBuilder/OperatorSelector.tsx
- [X] T014 [US1] Create value input component (text, select based on attribute) in assets/js/dashboard/components/FilterBuilder/ValueInput.tsx
- [X] T015 [US1] Create main FilterBuilder container component in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx
- [X] T016 [US1] Integrate FilterBuilder into dashboard in assets/js/dashboard/components/FilterBuilder/index.tsx
- [X] T017 [US1] Test single condition filter creation and visitor count display

---

## Phase 4: User Story 2 - AND Logic

**Goal**: Allow users to combine multiple conditions with AND logic

**Independent Test**: Add 2+ conditions with AND, verify only visitors matching all conditions are counted

### Implementation

- [X] T018 [P] [US2] Create FilterGroup container component with AND logic in assets/js/dashboard/components/FilterBuilder/FilterGroup.tsx
- [X] T019 [US2] Add "Add Condition" button to filter group in FilterGroup.tsx
- [X] T020 [US2] Implement AND logic when combining multiple conditions in filter-query-parser.ts
- [X] T021 [US2] Test AND logic with multiple conditions

---

## Phase 5: User Story 3 - OR Logic

**Goal**: Allow users to combine multiple conditions with OR logic

**Independent Test**: Add 2+ conditions with OR, verify combined count equals sum of individual counts

### Implementation

- [X] T022 [P] [US3] Add logic toggle (AND/OR) to FilterGroup component in FilterGroup.tsx
- [X] T023 [US3] Implement OR logic in filter-query-parser.ts
- [X] T024 [US3] Test OR logic with multiple conditions

---

## Phase 6: User Story 5 - Save/Edit/Delete Segments

**Goal**: Allow users to save, edit, and delete segments

**Independent Test**: Save segment, find in list later, load for editing, delete

### Implementation

- [X] T025 [US5] Create SegmentList component in assets/js/dashboard/components/FilterBuilder/SegmentList.tsx
- [X] T026 [US5] Create SaveSegmentModal component in assets/js/dashboard/components/FilterBuilder/SaveSegmentModal.tsx
- [X] T027 [US5] Create DeleteSegmentConfirm component in assets/js/dashboard/components/FilterBuilder/DeleteSegmentConfirm.tsx
- [X] T028 [US5] Integrate segment CRUD operations with useFilterBuilder hook
- [X] T029 [US5] Add load segment functionality to FilterBuilder
- [X] T030 [US5] Test save, edit, delete segment workflow

---

## Phase 7: User Story 4 - Nested Filter Groups

**Goal**: Allow users to create nested groups of conditions (3 levels max)

**Independent Test**: Create nested groups, verify correct count calculation

### Implementation

- [X] T031 [US4] Add "Add Nested Group" button to FilterGroup in FilterGroup.tsx
- [X] T032 [US4] Implement recursive rendering for nested groups in FilterGroup.tsx
- [X] T033 [US4] Add nesting depth validation (max 3 levels) in useFilterBuilder hook
- [X] T034 [US4] Update filter-query-parser.ts to handle nested groups
- [X] T035 [US4] Test nested group creation and logic

---

## Phase 8: User Story 6 - Visual Feedback

**Goal**: Real-time visitor count updates within 2 seconds

**Independent Test**: Modify condition, verify count updates within 2 seconds

### Implementation

- [X] T036 [US6] Implement debounced visitor count query in useFilterBuilder hook
- [X] T037 [US6] Create VisitorCountDisplay component in assets/js/dashboard/components/FilterBuilder/VisitorCountDisplay.tsx
- [X] T038 [US6] Add loading state and error handling to visitor count display
- [X] T039 [US6] Test real-time update performance (<2 seconds)

---

## Phase 9: Polish & Cross-Cutting Concerns

- [X] T040 [P] Add validation for max 20 conditions limit in useFilterBuilder hook
- [X] T041 [P] Add validation for max 3 nesting levels in useFilterBuilder hook
- [X] T042 [P] Handle edge case: 0 visitors match filter
- [X] T043 Add error messages for invalid filter configurations
- [X] T044 [P] Add keyboard navigation support for filter builder
- [X] T045 Test overall feature integration and edge cases

---

## Summary

| Metric | Count |
|--------|-------|
| Total Tasks | 45 |
| Phase 1: Setup | 5 |
| Phase 2: Foundational | 5 |
| Phase 3: US1 | 7 |
| Phase 4: US2 | 4 |
| Phase 5: US3 | 3 |
| Phase 6: US5 | 6 |
| Phase 7: US4 | 5 |
| Phase 8: US6 | 4 |
| Phase 9: Polish | 6 |

### Parallelizable Tasks

- T002, T003, T004, T005 (Setup - can run in parallel)
- T006, T007 (Foundational - parallelizable)
- T018, T022 (US2, US3 - parallelizable)
- T031, T032 (US4 - parallelizable)
- T040, T041, T042, T044 (Polish - parallelizable)

### Suggested MVP Scope

**T001-T010** (Setup + Foundational) + **T011-T017** (US1) = 17 tasks for MVP
