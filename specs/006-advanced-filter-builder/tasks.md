# Tasks: Advanced Filter Builder for Visitor Segments

**Input**: Design documents from `/specs/006-advanced-filter-builder/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), data-model.md, contracts/

**Tests**: The constitution mandates ExUnit for Elixir and Jest for JavaScript tests.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Database migrations and project structure initialization

- [x] T001 Create database migrations for segments, filter_groups, filter_conditions tables in priv/repo/migrations/
- [x] T002 [P] Add filter fields configuration in lib/plausible/segments/fields.ex
- [x] T003 [P] Configure segment-related API routes in lib/plausible_web/router.ex

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create FilterCondition schema in lib/plausible/segments/filter_condition.ex
- [x] T005 Create FilterGroup schema in lib/plausible/segments/filter_group.ex
- [x] T006 Create VisitorSegment schema in lib/plausible/segments/visitor_segment.ex
- [x] T007 [P] Create filter field definitions module in lib/plausible/segments/fields.ex
- [x] T008 [P] Create segment context for CRUD operations in lib/plausible/segments/context.ex
- [x] T009 Setup ClickHouse query builder for segment filtering in lib/plausible/segments/query.ex
- [x] T010 Create segment preview API controller in lib/plausible_web/controllers/api/segment_controller.ex

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Create Simple AND Segment (Priority: P1) 🎯 MVP

**Goal**: Enable users to create segments with multiple conditions combined using AND logic, preview matching visitor count

**Independent Test**: Add 3 conditions (country=US, pages>5, AND logic) and verify correct visitor count displays

### Tests for User Story 1

- [x] T011 [P] [US1] ExUnit test for VisitorSegment.create/3 in test/plausible/segments/visitor_segment_test.exs
- [x] T012 [P] [US1] ExUnit test for filter query builder in test/plausible/segments/query_test.exs
- [x] T013 [P] [US1] Jest test for FilterCondition component in test/components/FilterCondition.test.tsx
- [x] T014 [P] [US1] Jest test for FilterGroup component in test/components/FilterGroup.test.tsx

### Implementation for User Story 1

- [x] T015 [P] [US1] Implement FilterCondition React component in assets/js/components/FilterCondition.tsx
- [x] T016 [P] [US1] Implement FilterGroup React component in assets/js/components/FilterGroup.tsx
- [x] T017 [US1] Implement FilterBuilder main container in assets/js/components/FilterBuilder.tsx (depends on T015, T016)
- [x] T018 [US1] Add segment preview API endpoint POST /api/sites/:site_id/segments/preview
- [x] T019 [US1] Connect FilterBuilder to preview API
- [x] T020 [US1] Add AND/OR connector toggle in FilterGroup component

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Create OR Segment (Priority: P1)

**Goal**: Enable users to combine conditions using OR logic

**Independent Test**: Create an OR group with two conditions and verify both user types are included in preview

### Tests for User Story 2

- [x] T021 [P] [US2] Jest test for OR connector toggle in test/components/FilterGroup.test.tsx

### Implementation for User Story 2

- [x] T022 [P] [US2] Update query builder to handle OR logic in lib/plausible/segments/query.ex
- [x] T023 [US2] Ensure AND/OR toggle works correctly in FilterGroup component

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Create Nested Filter Groups (Priority: P2)

**Goal**: Enable users to create nested groups with up to 3 levels of depth

**Independent Test**: Create nested groups (3 levels) and verify correct visitors are matched

### Tests for User Story 3

- [x] T024 [P] [US3] ExUnit test for nested filter query in test/plausible/segments/query_test.exs
- [x] T025 [P] [US3] Jest test for nested FilterGroup rendering in test/components/FilterGroup.test.tsx

### Implementation for User Story 3

- [x] T026 [US3] Update FilterGroup to support nested groups in data model (filter_groups.parent_group_id)
- [x] T027 [US3] Update query builder for nested group logic in lib/plausible/segments/query.ex
- [x] T028 [US3] Add nesting UI (indent, expand/collapse) in FilterGroup component
- [x] T029 [US3] Add depth limit validation (max 3 levels)

**Checkpoint**: User Story 3 is complete

---

## Phase 6: User Story 4 - Save and Manage Segments (Priority: P2)

**Goal**: Enable users to save, load, edit, and delete segments

**Independent Test**: Save a segment with a name, reload page, select segment, verify configuration loads correctly

### Tests for User Story 4

- [x] T030 [P] [US4] ExUnit test for segment CRUD operations in test/plausible/segments/context_test.exs
- [x] T031 [P] [US4] Jest test for SegmentList component in test/components/SegmentList.test.tsx

### Implementation for User Story 4

- [x] T032 [P] [US4] Implement segment save API endpoint POST /api/sites/:site_id/segments
- [x] T033 [P] [US4] Implement segment list API endpoint GET /api/sites/:site_id/segments
- [x] T034 [P] [US4] Implement segment get API endpoint GET /api/sites/:site_id/segments/:id
- [x] T035 [P] [US4] Implement segment update API endpoint PUT /api/sites/:site_id/segments/:id
- [x] T036 [P] [US4] Implement segment delete API endpoint DELETE /api/sites/:site_id/segments/:id
- [x] T037 [US4] Create SegmentList React component in assets/js/components/SegmentList.tsx
- [x] T038 [US4] Add segment save modal to FilterBuilder
- [x] T039 [US4] Connect segment load functionality to FilterBuilder
- [x] T040 [US4] Add segment delete confirmation UI

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T041 [P] Add error handling for invalid filter configurations
- [x] T042 [P] Handle large dataset preview timeout gracefully
- [x] T043 [P] Add validation for maximum 10 conditions per segment
- [x] T044 Add structured logging for all segment operations
- [x] T045 Update quickstart.md validation - test common use cases
- [x] T046 Add accessibility improvements (keyboard navigation, screen reader support)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed) or sequentially in priority order (P1 → P2)

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Depends on US1 for basic infrastructure
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Depends on US1, US2 for query builder
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Depends on US1 for basic CRUD

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, User Stories 1 and 2 can start in parallel (both P1)
- All tests for a user story marked [P] can run in parallel
- User Stories 3 and 4 can run in parallel after US1+US2 complete

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "ExUnit test for VisitorSegment.create/3 in test/plausible/segments/visitor_segment_test.exs"
Task: "ExUnit test for filter query builder in test/plausible/segments/query_test.exs"
Task: "Jest test for FilterCondition component in test/components/FilterCondition.test.tsx"
Task: "Jest test for FilterGroup component in test/components/FilterGroup.test.tsx"

# Launch all components for User Story 1 together:
Task: "Implement FilterCondition React component in assets/js/components/FilterCondition.tsx"
Task: "Implement FilterGroup React component in assets/js/components/FilterGroup.tsx"
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
5. Add User Story 4 → Test independently → Deploy/Demo
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 + 2
   - Developer B: User Story 3
   - Developer C: User Story 4
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
