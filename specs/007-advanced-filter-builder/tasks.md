# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Branch**: `007-advanced-filter-builder`
**Generated**: 2026-02-26

## Implementation Strategy

The implementation follows an MVP-first approach where User Story 1 (basic filter condition) delivers immediate value, with subsequent user stories adding progressively more advanced functionality. Each user story phase represents a complete, independently testable increment.

## Phase Dependencies

```
Phase 1 (Setup) --> Phase 2 (Foundational) --> Phase 3-8 (User Stories) --> Phase 9 (Polish)
```

## Task Summary

- **Total Tasks**: 28
- **Parallelizable Tasks**: 12
- **User Stories**: 6

---

## Phase 1: Setup

- [ ] T001 Review existing filter builder components in `assets/js/dashboard/filtering/new-filter-builder/`
- [ ] T002 [P] Verify existing TypeScript types in `assets/js/dashboard/filtering/new-filter-builder/types.ts`
- [x] T003 [P] Review existing filter utilities in `assets/js/dashboard/util/filters.js`

---

## Phase 2: Foundational

**Goal**: Create core types and utilities needed by all user stories

**Independent Test Criteria**: Core utilities can be imported and used without errors

### Implementation Tasks

- [ ] T004 Define FilterCondition interface with id, dimension, operator, value fields in `assets/js/dashboard/filtering/new-filter-builder/types.ts`
- [ ] T005 Define FilterGroup interface with id, operator, children fields in `assets/js/dashboard/filtering/new-filter-builder/types.ts`
- [ ] T006 Define FilterTemplate interface extending SavedSegment in `assets/js/dashboard/filtering/new-filter-builder/types.ts`
- [ ] T007 Implement createCondition() utility to generate new conditions with unique IDs in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts`
- [ ] T008 Implement createGroup() utility to generate new groups in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts`
- [ ] T009 Implement validateCondition() function for basic validation in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts`
- [x] T010 [P] Implement serializeFilterTree() to convert filter tree to JSON for API in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts`
- [x] T011 [P] Implement deserializeFilterTree() to parse API response in `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts`

---

## Phase 3: User Story 1 - Basic Filter Condition (P1)

**Goal**: Allow users to create a single filter condition

**Independent Test Criteria**: Users can add a single condition with dimension, operator, and value; the filter applies and shows matching visitors

### Implementation Tasks

- [ ] T012 [P] [US1] Implement DimensionSelector dropdown component in `assets/js/dashboard/filtering/new-filter-builder/DimensionSelector.tsx`
- [x] T013 [P] [US1] Implement OperatorSelector component for choosing filter operators in `assets/js/dashboard/filtering/new-filter-builder/OperatorSelector.tsx`
- [ ] T014 [US1] Implement ConditionRow component to display single filter condition in `assets/js/dashboard/filtering/new-filter-builder/ConditionRow.tsx`
- [ ] T015 [US1] Implement FilterBuilderContext state management with addCondition, removeCondition actions in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`
- [ ] T016 [US1] Implement main FilterBuilder component container in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx`
- [ ] T017 [US1] Integrate filter builder with existing segment modal in `assets/js/dashboard/segments/segment-modals.tsx`

---

## Phase 4: User Story 2 - AND Logic (P1)

**Goal**: Allow users to combine conditions with AND logic

**Independent Test Criteria**: Adding two conditions with AND shows only visitors matching BOTH conditions

### Implementation Tasks

- [ ] T018 [US2] Add AND/OR connector UI between conditions in ConditionRow component in `assets/js/dashboard/filtering/new-filter-builder/ConditionRow.tsx`
- [ ] T019 [US2] Update FilterBuilderContext to support changing condition connector type in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`
- [ ] T020 [US2] Implement FilterSummary to display AND logic visually in `assets/js/dashboard/filtering/new-filter-builder/FilterSummary.tsx`

---

## Phase 5: User Story 3 - OR Logic (P1)

**Goal**: Allow users to combine conditions with OR logic

**Independent Test Criteria**: Adding two conditions with OR shows visitors matching EITHER condition

### Implementation Tasks

- [ ] T021 [US3] Support OR connector in FilterBuilderContext in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`
- [ ] T022 [US3] Update FilterSummary to display mixed AND/OR logic clearly in `assets/js/dashboard/filtering/new-filter-builder/FilterSummary.tsx`

---

## Phase 6: User Story 4 - Nested Filter Groups (P2)

**Goal**: Allow users to create nested groups with different logical operators

**Independent Test Criteria**: Creating nested group (A OR B) AND C returns correct visitors

### Implementation Tasks

- [ ] T023 [US4] Implement ConditionGroup component for rendering nested groups in `assets/js/dashboard/filtering/new-filter-builder/ConditionGroup.tsx`
- [ ] T024 [US4] Add group selection and grouping UI in FilterBuilder in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx`
- [ ] T025 [US4] Update FilterBuilderContext to support addGroup, removeGroup, changeGroupOperator actions in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`

---

## Phase 7: User Story 5 - Save and Reuse Filter Segments (P2)

**Goal**: Allow users to save filter configurations as named segments

**Independent Test Criteria**: Saving a segment with name, then loading it restores all conditions

### Implementation Tasks

- [ ] T026 [US5] Implement SaveTemplateModal component in `assets/js/dashboard/filtering/new-filter-builder/SaveTemplateModal.tsx`
- [ ] T027 [US5] Implement LoadTemplateDropdown component in `assets/js/dashboard/filtering/new-filter-builder/LoadTemplateDropdown.tsx`
- [ ] T028 [US5] Integrate with existing segments API (POST/GET /api/stats/:site_id/segments) in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`

---

## Phase 8: User Story 6 - Validate Filter Input (P2)

**Goal**: Provide clear validation feedback for invalid filter conditions

**Independent Test Criteria**: Entering invalid values shows helpful error messages

### Implementation Tasks

- [ ] T029 Add validation error display in ConditionRow component in `assets/js/dashboard/filtering/new-filter-builder/ConditionRow.tsx`
- [ ] T030 Add overall filter validation in FilterBuilderContext before applying in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`

---

## Phase 9: Polish & Cross-Cutting Concerns

**Goal**: Final integration and edge case handling

### Implementation Tasks

- [x] T031 [P] Add undo/redo support via Ctrl+Z/Cmd+Z in FilterBuilderContext in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx`
- [x] T032 [P] Add visitor count preview before applying filter in `assets/js/dashboard/filtering/new-filter-builder/FilterSummary.tsx`
- [ ] T033 Add clear all button to reset filter builder in `assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx`

---

## Parallel Execution Examples

### Example 1: Independent Component Development
```bash
# T012 (DimensionSelector) and T013 (OperatorSelector) can be developed in parallel
# as they are independent dropdown components
```

### Example 2: Utility Functions
```bash
# T010 (serialize) and T011 (deserialize) can be developed in parallel
# Both are pure functions with no shared state
```

### Example 3: Context and Components
```T015 (Context) must complete before T016 (FilterBuilder), but T012-T013 can parallelize
```

---

## Independent Test Criteria by User Story

| User Story | Test Action | Expected Result |
|------------|-------------|-----------------|
| US1 | Add single condition (Country=US) | Visitor list filters to US visitors only |
| US2 | Add two conditions with AND | Only visitors matching BOTH conditions shown |
| US3 | Add two conditions with OR | Visitors matching EITHER condition shown |
| US4 | Create (A OR B) AND C | Correct complex logic applied |
| US5 | Save segment, reload page, load segment | All conditions restored |
| US6 | Enter empty value, try to apply | Error message displayed |

---

## MVP Scope

The MVP (Minimum Viable Product) includes only **User Story 1 - Basic Filter Condition**:
- Tasks T001-T017 (Phases 1-3)
- Deliverable: Single condition filter functionality

This provides immediate value by enabling basic visitor segmentation while leaving room for incremental delivery of more advanced features.
