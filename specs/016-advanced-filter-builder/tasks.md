# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Branch**: 016-advanced-filter-builder
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)

## Task Summary

- **Total Tasks**: 27
- **Completed**: 18
- **User Stories**: 7 (P1: 4, P2: 2, P3: 1)
- **Parallel Opportunities**: 6
- **Independent Test Criteria**: Each user story can be tested independently

## Implementation Strategy

**MVP Scope**: User Story 1 + Foundational (Tasks T001-T006)
- This delivers basic single-condition filtering capability
- Core data types, utilities, and context established
- Independent test: Create single filter, apply, verify dashboard updates

**Incremental Delivery**: Each user story phase is independently testable
- Phase 3 (US1-3): Basic AND/OR conditions
- Phase 4 (US4): Nested groups
- Phase 5 (US5): Save/load segments
- Phase 6 (US6): Edit/delete
- Phase 7 (US7): Preview

---

## Phase 1: Setup

*Project initialization and configuration*

- [x] T001 Create filter builder directory structure in assets/js/dashboard/filtering/new-filter-builder/
- [x] T002 Add FilterBuilder to existing dashboard component exports in assets/js/dashboard/index.ts
- [x] T003 Configure TailwindCSS for new filter builder components if needed

---

## Phase 2: Foundational

*Core utilities, types, and context - blocking prerequisites for all user stories*

- [x] T004 Create TypeScript types for FilterCondition, FilterGroup, FilterTree in assets/js/dashboard/filtering/new-filter-builder/types.ts
- [x] T005 Implement filterTreeUtils.ts with utility functions (createCondition, createGroup, findById, updateCondition, deleteCondition) in assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts
- [x] T006 Create FilterBuilderContext with useReducer for state management in assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx
- [x] T007 Write Jest tests for filterTreeUtils.ts in assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.test.ts

---

## Phase 3: User Stories 1-3 - Basic Filter Conditions (P1)

*Goal: Users can create single conditions and combine with AND/OR logic*

**Independent Test**: Create filter for "Visitors from US", add second condition for "Browser=Chrome", toggle AND/OR, verify correct visitor filtering

### User Story 1 - Single Condition Filter

- [x] T008 [P] [US1] Implement ConditionRow component for editing single condition in assets/js/dashboard/filtering/new-filter-builder/ConditionRow.tsx
- [x] T009 [US1] Implement DimensionSelector dropdown in assets/js/dashboard/filtering/new-filter-builder/DimensionSelector.tsx
- [x] T010 [US1] Implement OperatorSelector dropdown in assets/js/dashboard/filtering/new-filter-builder/OperatorSelector.tsx

### User Story 2-3 - AND/OR Logic

- [x] T011 [P] [US2] Implement ConditionGroup component for rendering groups with connector in assets/js/dashboard/filtering/new-filter-builder/ConditionGroup.tsx
- [x] T012 [P] [US3] Add AddCondition button functionality to ConditionGroup in assets/js/dashboard/filtering/new-filter-builder/ConditionGroup.tsx

### Integration

- [x] T013 [US1] Implement main FilterBuilder container component in assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx
- [x] T014 [US1] Integrate FilterBuilderContext with FilterBuilder component in assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx

---

## Phase 4: User Story 4 - Nested Filter Groups (P2)

*Goal: Users can create nested groups for complex logical expressions*

**Independent Test**: Create "(Country=US AND Browser=Chrome) OR (Country=DE)" structure, verify correct logical evaluation

- [x] T015 [P] [US4] Extend ConditionGroup to support nested groups in assets/js/dashboard/filtering/new-filter-builder/ConditionGroup.tsx
- [x] T016 [US4] Implement nested group rendering with indentation and visual hierarchy in assets/js/dashboard/filtering/new-filter-builder/ConditionGroup.tsx
- [x] T017 [US4] Add depth validation (max 5 levels) to filterTreeUtils in assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts

---

## Phase 5: User Story 5 - Save/Load Segments (P2)

*Goal: Users can save and load named segments*

**Independent Test**: Save filter as "US Chrome Users", reload page, select saved segment, verify filter restored

- [x] T018 [P] [US5] Implement SaveTemplateModal component in assets/js/dashboard/filtering/new-filter-builder/SaveTemplateModal.tsx
- [x] T019 [P] [US5] Implement LoadTemplateDropdown component in assets/js/dashboard/filtering/new-filter-builder/LoadTemplateDropdown.tsx
- [x] T020 [US5] Integrate with existing segments API (POST /api/{site}/segments) in FilterBuilderContext in assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.tsx

---

## Phase 6: User Story 6 - Edit/Delete Conditions (P1)

*Goal: Users can modify or remove individual conditions*

**Independent Test**: Add 3 conditions, delete middle one, modify first one's value, verify correct behavior

- [x] T021 [P] [US6] Add delete button to ConditionRow in assets/js/dashboard/filtering/new-filter-builder/ConditionRow.tsx
- [x] T022 [US6] Add inline editing (click to edit) for ConditionRow fields in assets/js/dashboard/filtering/new-filter-builder/ConditionRow.tsx
- [x] T023 [US6] Add clear all functionality to FilterBuilder in assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx

---

## Phase 7: User Story 7 - Preview Filter Results (P3)

*Goal: Users see visitor count preview before applying filter*

**Independent Test**: Create filter, verify preview shows visitor count, verify loading state and zero-visitors warning

- [x] T024 [P] [US7] Implement SegmentPreview component with visitor count in assets/js/dashboard/filtering/new-filter-builder/SegmentPreview.tsx

---

## Phase 8: Polish & Cross-Cutting

- [x] T025 Write Jest tests for FilterBuilderContext in assets/js/dashboard/filtering/new-filter-builder/FilterBuilderContext.test.tsx
- [x] T026 Add analytics events for filter builder usage tracking
- [x] T027 Accessibility audit (keyboard navigation, ARIA labels)

---

## Dependencies

```
Phase 1 (Setup)
  └── T001 ─┬─► T002 ──► T003
             │
Phase 2 (Foundational)
             ├──► T004 ──► T005 ──► T006 ──► T007
             |    (types)  (utils)  (ctx)    (tests)
             |
Phase 3 (US1-3: Basic Conditions)
             ├──► T008 ──► T009 ──► T010 ──► T011 ──► T012 ──► T013 ──► T014
             |    (row)    (dim)    (op)     (group)  (add)    (container)
             |
Phase 4 (US4: Nested Groups)
             ├──► T015 ──► T016 ──► T017
             |
Phase 5 (US5: Save/Load)
             ├──► T018 ──► T019 ──► T020
             |
Phase 6 (US6: Edit/Delete)
             ├──► T021 ──► T022 ──► T023
             |
Phase 7 (US7: Preview)
             └──► T024
```

---

## Parallel Execution Opportunities

| Tasks | Reason |
|-------|--------|
| T008, T011 | Different components (ConditionRow, ConditionGroup) |
| T018, T019 | Different components (SaveTemplateModal, LoadTemplateDropdown) |
| T015, T021 | Different features (nested groups vs edit/delete) |
| T004, T005 | Types and utilities can be designed in parallel |

---

## MVP Verification

**MVP Scope**: T001-T014 (Phase 1-3, User Stories 1-3)

**Test Criteria**:
1. User can select attribute, operator, value for single condition
2. User can add second condition with AND/OR connector
3. Toggle between AND and OR changes filter logic correctly
4. Filter applies to dashboard and updates visitor data

**Command to verify**:
```bash
npm test -- --testPathPattern="filter-builder"
```
