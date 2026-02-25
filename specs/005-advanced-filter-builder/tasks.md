# Tasks: Advanced Filter Builder

**Input**: Design documents from `/specs/005-advanced-filter-builder/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, quickstart.md

**Tests**: Test tasks included per constitution requirement for TDD

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create filter-builder component directory structure in assets/js/dashboard/components/filter-builder/
- [x] T002 [P] Add type definitions for FilterCondition and FilterGroup in assets/js/dashboard/types/filter-builder.ts
- [x] T003 Configure Jest test environment for new components

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create FilterBuilderContext for managing filter state in assets/js/dashboard/filtering/filter-builder-context.tsx
- [x] T005 [P] Implement filter serialization utilities to convert FilterGroup to legacy filter format in assets/js/dashboard/util/filter-serialization.ts
- [x] T006 [P] Add visitor attributes configuration in assets/js/dashboard/util/visitor-attributes.ts
- [x] T007 Create FilterBuilderContainer wrapper component in assets/js/dashboard/components/filter-builder/FilterBuilderContainer.tsx (depends on T004, T005)
- [x] T008 Integrate FilterBuilderContainer with existing filter-modal.js (depends on T007)

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create Simple Single Condition Filter (Priority: P1) 🎯 MVP

**Goal**: Users can create a basic filter with a single field, operator, and value

**Independent Test**: Create a filter with "Country equals US" and verify visitor list updates correctly

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T009 [P] [US1] Write unit tests for FilterConditionRow in assets/js/dashboard/components/filter-builder/filter-condition-row.test.tsx
- [ ] T010 [P] [US1] Write unit tests for filter serialization in assets/js/dashboard/util/filter-serialization.test.ts

### Implementation for User Story 1

- [x] T011 [P] [US1] Create FilterConditionRow component in assets/js/dashboard/components/filter-builder/FilterConditionRow.tsx
- [x] T012 [P] [US1] Create FieldSelector component in assets/js/dashboard/components/filter-builder/FieldSelector.tsx
- [x] T013 [P] [US1] Create OperatorSelector component in assets/js/dashboard/components/filter-builder/OperatorSelector.tsx
- [x] T014 [US1] Create ValueInput component in assets/js/dashboard/components/filter-builder/ValueInput.tsx (depends on T011, T012, T013)
- [x] T015 [US1] Wire up FilterConditionRow to FilterBuilderContext (depends on T004, T011, T012, T013, T014)
- [x] T016 [US1] Implement apply filter action that updates visitor list (depends on T005, T015)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Combine Two Conditions with AND Logic (Priority: P1)

**Goal**: Users can add a second condition and connect with AND operator

**Independent Test**: Add two conditions with AND, verify only visitors matching BOTH appear

### Tests for User Story 2

- [ ] T017 [P] [US2] Write unit tests for AND logic in filter evaluation in assets/js/dashboard/util/filter-evaluation.test.ts

### Implementation for User Story 2

- [x] T018 [P] [US2] Create LogicalOperatorSelector component in assets/js/dashboard/components/filter-builder/LogicalOperatorSelector.tsx ✅ COMPLETE
- [x] T019 [US2] Add add condition button to FilterBuilderContainer (depends on T018)
- [x] T020 [US2] Implement AND logic in filter serialization (depends on T005, T019)
- [x] T021 [US2] Add visual AND indicator between conditions in FilterConditionRow (depends on T018, T019)

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Combine Multiple Conditions with OR Logic (Priority: P1)

**Goal**: Users can connect conditions with OR to match any of several values

**Independent Test**: Add conditions with OR, verify visitors matching ANY condition appear

### Implementation for User Story 3

- [x] T022 [US3] Update LogicalOperatorSelector to support OR option
- [x] T023 [US3] Implement OR logic in filter serialization (depends on T020, T022)
- [x] T024 [US3] Add OR visual indicator in UI (depends on T022, T023)
- [x] T025 [US3] Handle mixed AND/OR grouping in serialization (depends on T023)

**Checkpoint**: All three P1 user stories should be independently functional

---

## Phase 6: User Story 4 - Create Nested Filter Groups (Priority: P2)

**Goal**: Users can group conditions and apply different logic within groups

**Independent Test**: Create nested groups, verify correct visitors based on grouping logic

### Implementation for User Story 4

- [x] T026 [P] [US4] Create FilterGroup component in assets/js/dashboard/components/filter-builder/FilterGroup.tsx
- [x] T027 [P] [US4] Create AddGroupButton component in assets/js/dashboard/components/filter-builder/AddGroupButton.tsx
- [x] T028 [US4] Implement nested group rendering in FilterBuilderContainer (depends on T026, T027)
- [x] T029 [US4] Handle depth limitation (max 3 levels) validation (depends on T028)
- [x] T030 [US4] Add visual nesting indicators in UI (depends on T028, T029)

---

## Phase 7: User Story 5 - Save and Reuse Filter Segments (Priority: P2)

**Goal**: Users can save filters as named segments for reuse

**Independent Test**: Save a filter with a name, reload it, verify conditions restore correctly

### Implementation for User Story 5

- [x] T031 [P] [US5] Create SaveSegmentModal component in assets/js/dashboard/components/filter-builder/SaveSegmentModal.tsx
- [x] T032 [P] [US5] Add segment type selector (personal/site) in assets/js/dashboard/components/filter-builder/SaveSegmentModal.tsx
- [x] T033 [US5] Implement save segment API call (depends: T031, T032)
- [x] T034 [US5] Create LoadSegmentDropdown component in assets/js/dashboard/components/filter-builder/LoadSegmentDropdown.tsx
- [x] T035 [US5] Implement load segment functionality (depends on T034)

---

## Phase 8: User Story 6 - Edit and Delete Filter Conditions (Priority: P2)

**Goal**: Users can modify or remove individual conditions without rebuilding

**Independent Test**: Edit a condition, remove another, verify remaining conditions work correctly

### Implementation for User Story 6

- [x] T036 [P] [US6] Add edit mode toggle in FilterConditionRow
- [x] T037 [P] [US6] Implement delete condition in FilterBuilderContext
- [x] T038 [US6] Add clear all button to FilterBuilderContainer (depends on T037)
- [x] T039 [US6] Add condition validation (depends on T036, T037)

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T040 [P] Add filter preview count display in assets/js/dashboard/components/filter-builder/FilterPreview.tsx
- [x] T041 [P] Handle empty results message
- [x] T042 Add loading states and error handling
- [x] T043 Performance optimization for large filter chains
- [x] T044 Update existing segment-modals.tsx integration
- [x] T045 Run full test suite and fix any issues
- [x] T046 Run linting and formatting checks

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Phase 9)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational - Depends on US1 for basic condition rendering
- **User Story 3 (P1)**: Can start after Foundational - Depends on US2 for operator logic
- **User Story 4 (P2)**: Can start after US1-US3 - Requires basic condition rendering
- **User Story 5 (P2)**: Can start after Foundational - Uses existing segment infrastructure
- **User Story 6 (P2)**: Can start after US1 - Builds on condition rendering

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Components before context integration
- Context before serialization
- Core implementation before polish

### Parallel Opportunities

- T002, T003 can run in parallel
- T005, T006 can run in parallel
- T011, T012, T013 can run in parallel
- T017 can run in parallel with other test tasks
- T018, T019 can run in parallel
- T026, T027 can run in parallel
- T031, T032 can run in parallel
- T036, T037 can run in parallel
- T040, T041 can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Write unit tests for FilterConditionRow in assets/js/dashboard/components/filter-builder/filter-condition-row.test.tsx"
Task: "Write unit tests for filter serialization in assets/js/dashboard/util/filter-serialization.test.ts"

# Launch all components for User Story 1 together:
Task: "Create FilterConditionRow component in assets/js/dashboard/components/filter-builder/FilterConditionRow.tsx"
Task: "Create FieldSelector component in assets/js/dashboard/components/filter-builder/FieldSelector.tsx"
Task: "Create OperatorSelector component in assets/js/dashboard/components/filter-builder/OperatorSelector.tsx"
```

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
5. Add User Stories 4-6 → Test → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1
   - Developer B: User Story 2
   - Developer C: User Story 3
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
