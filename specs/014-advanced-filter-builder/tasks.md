# Tasks: Advanced Filter Builder

**Input**: Design documents from `/specs/014-advanced-filter-builder/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Not explicitly requested in spec - implementing with TDD approach for complex logic

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [x] T001 Create FilterBuilder component directory structure in assets/js/dashboard/components/FilterBuilder/
- [x] T002 [P] Create filter-parser utility module in assets/js/lib/filter-parser.ts
- [x] T003 [P] Create useFilterBuilder hook in assets/js/hooks/useFilterBuilder.ts

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Implement FilterTree type definitions in assets/js/lib/filter-parser.ts
- [x] T005 [P] Implement serialization functions (toBackend, fromBackend) in assets/js/lib/filter-parser.ts
- [x] T006 [P] Implement useFilterBuilder state management hook in assets/js/hooks/useFilterBuilder.ts
- [x] T007 Verify existing filter suggestions API integration in assets/js/lib/

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Building Simple Single-Condition Filters (Priority: P1) 🎯 MVP

**Goal**: Users can create a visitor segment based on a single attribute (field, operator, value)

**Independent Test**: Create a filter with one condition (e.g., "Country equals United States") and verify the segment contains only matching visitors

### Tests for User Story 1

- [x] T008 [P] [US1] Unit test for filter-parser serialization in assets/js/lib/__tests__/filter-parser.test.ts
- [x] T009 [P] [US1] Unit test for useFilterBuilder hook in assets/js/hooks/__tests__/useFilterBuilder.test.ts

### Implementation for User Story 1

- [x] T010 [P] [US1] Create ConditionRow component in assets/js/dashboard/components/FilterBuilder/ConditionRow.tsx
- [x] T011 [P] [US1] Create dimension selector dropdown in ConditionRow
- [x] T012 [US1] Create operator selector in ConditionRow (depends on T010, T011)
- [x] T013 [US1] Create value input with autocomplete in ConditionRow (depends on T012)
- [x] T014 [US1] Implement FilterBuilder container in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Combining Multiple Conditions with AND Logic (Priority: P1)

**Goal**: Users can narrow segments by combining conditions where all must be true

**Independent Test**: Add two conditions joined by AND and verify only visitors satisfying both appear in the segment

### Tests for User Story 2

- [x] T015 [P] [US2] Integration test for AND logic in assets/js/dashboard/components/FilterBuilder/__tests__/FilterBuilder.test.tsx

### Implementation for User Story 2

- [x] T016 [P] [US2] Add "Add Condition" button to FilterBuilder in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx
- [x] T017 [US2] Implement AND connector logic in useFilterBuilder hook in assets/js/hooks/useFilterBuilder.ts
- [x] T018 [US2] Render AND connector between condition rows in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Combining Multiple Conditions with OR Logic (Priority: P1)

**Goal**: Users can broaden segments by combining conditions where any must be true

**Independent Test**: Create two OR-connected conditions and verify visitors matching either condition appear in the segment

### Tests for User Story 3

- [x] T019 [P] [US3] Integration test for OR logic in assets/js/components/FilterBuilder/__tests__/FilterBuilder.test.tsx

### Implementation for User Story 3

- [x] T020 [P] [US3] Add connector toggle (AND/OR) to FilterBuilder in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx
- [x] T021 [US3] Implement OR connector logic in useFilterBuilder hook in assets/js/hooks/useFilterBuilder.ts

**Checkpoint**: All P1 user stories should now be independently functional

---

## Phase 6: User Story 4 - Creating Nested Condition Groups (Priority: P2)

**Goal**: Users can build complex logic like "(Country=US AND Device=Mobile) OR Country=UK"

**Independent Test**: Create a nested group and verify the segment includes visitors matching the group logic correctly

### Tests for User Story 4

- [x] T022 [P] [US4] Integration test for nested groups in assets/js/components/FilterBuilder/__tests__/FilterBuilder.test.tsx

### Implementation for User Story 4

- [x] T023 [P] [US4] Create ConditionGroup component in assets/js/dashboard/components/FilterBuilder/ConditionGroup.tsx
- [x] T024 [US4] Implement nesting logic in useFilterBuilder hook (max 3 levels) in assets/js/hooks/useFilterBuilder.ts
- [x] T025 [US4] Add "Group" button to combine conditions in assets/js/dashboard/components/FilterBuilder/ConditionGroup.tsx

**Checkpoint**: At this point, User Stories 1-4 should work together

---

## Phase 7: User Story 5 - Editing and Removing Filter Conditions (Priority: P2)

**Goal**: Users can modify existing conditions or remove them entirely

**Independent Test**: Modify and remove conditions and verify the segment updates accordingly

### Tests for User Story 5

- [x] T026 [P] [US5] Test for condition editing in assets/js/components/FilterBuilder/__tests__/FilterBuilder.test.tsx

### Implementation for User Story 5

- [x] T027 [P] [US5] Add remove button to ConditionRow in assets/js/dashboard/components/FilterBuilder/ConditionRow.tsx
- [x] T028 [US5] Implement condition update logic in useFilterBuilder hook in assets/js/hooks/useFilterBuilder.ts
- [x] T029 [US5] Handle empty state when all conditions removed in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx

---

## Phase 8: User Story 6 - Saving and Reusing Filter Templates (Priority: P3)

**Goal**: Users can save filter configurations as reusable templates

**Independent Test**: Save a filter as a template and apply it to create a new segment

### Tests for User Story 6

- [x] T030 [P] [US6] Integration test for template save/load in assets/js/components/FilterBuilder/__tests__/FilterBuilder.test.tsx

### Implementation for User Story 6

- [x] T031 [P] [US6] Create save segment form in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx
- [x] T032 [US6] Integrate with existing segment API endpoints in assets/js/dashboard/
- [x] T033 [US6] Add "Load Template" functionality in assets/js/dashboard/components/FilterBuilder/FilterBuilder.tsx
- [x] T034 [US6] Create FilterPreview component in assets/js/dashboard/components/FilterBuilder/FilterPreview.tsx

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T035 [P] Add validation errors display in FilterBuilder
- [x] T036 Add loading states for filter suggestions
- [x] T037 [P] Performance optimization for 20+ conditions
- [x] T038 Run quickstart.md validation
- [ ] T039 Update existing segment tests if needed in test/plausible/segments/

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Depends on US1 components but independently testable
- **User Story 3 (P1)**: Can start after Foundational (Phase 2) - Depends on US1, US2 core logic
- **User Story 4 (P2)**: Can start after Foundational - Depends on US1-US3 core components
- **User Story 5 (P2)**: Can start after Foundational - Depends on US1-US3 components
- **User Story 6 (P3)**: Can start after Foundational - Depends on US1 completion for save

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Hook logic before components
- Components before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, User Stories 1-3 can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models/components within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for filter-parser serialization in assets/js/lib/__tests__/filter-parser.test.ts"
Task: "Unit test for useFilterBuilder hook in assets/js/hooks/__tests__/useFilterBuilder.test.ts"

# Launch all components for User Story 1 together:
Task: "Create ConditionRow component in assets/js/dashboard/components/FilterBuilder/ConditionRow.tsx"
Task: "Create dimension selector dropdown in ConditionRow"
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
5. Add User Story 4-6 → Test independently → Deploy/Demo
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
