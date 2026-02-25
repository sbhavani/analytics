# Tasks: GraphQL Analytics API

**Input**: Design documents from `/specs/002-graphql-analytics/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: Included per constitution (Test-Driven Development is non-negotiable)

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependencies

- [x] T001 Add Absinthe dependencies to mix.exs in lib/
- [x] T002 [P] Configure GraphQL plugin in mix.exs ✅ DONE
- [x] T003 Create GraphQL directory structure in lib/plausible_web/graphql/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Create main GraphQL schema in lib/plausible_web/graphql/schema.ex
- [x] T005 [P] Create common input types in lib/plausible_web/graphql/types/common.ex
- [x] T006 [P] Create connection types for pagination in lib/plausible_web/graphql/types/common.ex
- [x] T007 Setup GraphQL endpoint in router.ex
- [x] T008 Add authentication middleware in lib/plausible_web/graphql/middleware/authentication.ex
- [x] T009 Create helper utilities in lib/plausible_web/graphql/resolvers/helpers.ex

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Query Pageview Data (Priority: P1) 🎯 MVP

**Goal**: Users can query pageview data through GraphQL with date range filtering

**Independent Test**: Make a GraphQL query for pageviews and verify response contains URL, title, visitors, timestamp

### Tests for User Story 1

> **Write these tests FIRST, ensure they FAIL before implementation**

- [x] T010 [P] [US1] Schema test for pageviews query in test/plausible_web/graphql/schema_test.exs
- [x] T011 [P] [US1] Resolver test for pageviews in test/plausible_web/graphql/resolvers/pageviews_test.exs
- [ ] T012 [US1] Integration test for pageviews API in test/plausible_web/graphql/integration/pageviews_test.exs

### Implementation for User Story 1

- [x] T013 [P] [US1] Create pageview type definitions in lib/plausible_web/graphql/types/pageview.ex
- [x] T014 [P] [US1] Create pageview filter input in lib/plausible_web/graphql/types/filters.ex
- [x] T015 [US1] Implement pageview resolver in lib/plausible_web/graphql/resolvers/pageviews.ex
- [x] T016 [US1] Add pageviews query to schema in lib/plausible_web/graphql/schema.ex
- [x] T017 [US1] Add pagination support to pageview queries
- [x] T018 [US1] Add date range validation
- [x] T019 [US1] Add error handling for empty results (return empty array)

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Query Events Data (Priority: P1)

**Goal**: Users can query event data through GraphQL with filtering

**Independent Test**: Query events and verify response includes name, category, timestamp, properties

### Tests for User Story 2

- [x] T020 [P] [US2] Schema test for events query in test/plausible_web/graphql/schema_test.exs
- [x] T021 [P] [US2] Resolver test for events in test/plausible_web/graphql/resolvers/events_test.exs
- [ ] T022 [US2] Integration test for events API in test/plausible_web/graphql/integration/events_test.exs

### Implementation for User Story 2

- [x] T023 [P] [US2] Create event type definitions in lib/plausible_web/graphql/types/event.ex
- [x] T024 [P] [US2] Create event filter input in lib/plausible_web/graphql/types/filters.ex
- [x] T025 [US2] Implement event resolver in lib/plausible_web/graphql/resolvers/events.ex
- [x] T026 [US2] Add events query to schema in lib/plausible_web/graphql/schema.ex
- [x] T027 [US2] Add event filtering by name and category

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Aggregate Analytics Metrics (Priority: P2)

**Goal**: Users can aggregate analytics data (count, sum, average, min, max)

**Independent Test**: Request aggregated data and verify correct calculated values

### Tests for User Story 3

- [x] T028 [P] [US3] Schema test for aggregate query in test/plausible_web/graphql/schema_test.exs
- [x] T029 [P] [US3] Resolver test for aggregate in test/plausible_web/graphql/resolvers/aggregate_test.exs
- [ ] T030 [US3] Integration test for aggregate API in test/plausible_web/graphql/integration/aggregate_test.exs

### Implementation for User Story 3

- [x] T031 [P] [US3] Create aggregate result type in lib/plausible_web/graphql/types/aggregate.ex
- [x] T032 [P] [US3] Create aggregation input type in lib/plausible_web/graphql/types/filters.ex
- [x] T033 [US3] Implement aggregate resolver in lib/plausible_web/graphql/resolvers/aggregate.ex
- [x] T034 [US3] Add aggregate query to schema in lib/plausible_web/graphql/schema.ex
- [x] T035 [US3] Support all 5 aggregation types: count, sum, average, min, max
- [x] T036 [US3] Add timeseries query for time-based aggregation

---

## Phase 6: User Story 4 - Query Custom Metrics (Priority: P2)

**Goal**: Users can query custom metrics with historical values

**Independent Test**: Query custom metrics and verify current value and historical data

### Tests for User Story 4

- [x] T037 [P] [US4] Schema test for custom metrics in test/plausible_web/graphql/schema_test.exs
- [x] T038 [P] [US4] Resolver test for custom metrics in test/plausible_web/graphql/resolvers/metrics_test.exs

### Implementation for User Story 4

- [x] T039 [P] [US4] Create custom metric types in lib/plausible_web/graphql/types/metric.ex
- [x] T040 [US4] Implement custom metrics resolver in lib/plausible_web/graphql/resolvers/metrics.ex
- [x] T041 [US4] Add custom metrics query to schema in lib/plausible_web/graphql/schema.ex

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T042 [P] Add query complexity analysis middleware
- [x] T043 Add structured logging for GraphQL operations
- [x] T044 Run quickstart.md validation
- [x] T045 [P] Performance testing for pagination (verify 10k+ records)
- [x] T046 Update API documentation

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed) or sequentially in priority order
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Independent from US1 once foundational ready
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but independently testable
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1/US2 but independently testable

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Types before resolvers
- Resolvers before schema integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel
- Once Foundational phase completes, all user stories can start in parallel
- All tests for a user story marked [P] can run in parallel
- Types within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Schema test for pageviews query in test/plausible_web/graphql/schema_test.exs"
Task: "Resolver test for pageviews in test/plausible_web/graphql/resolvers/pageviews_test.exs"
Task: "Integration test for pageviews API in test/plausible_web/graphql/integration/pageviews_test.exs"

# Launch all types for User Story 1 together:
Task: "Create pageview type definitions in lib/plausible_web/graphql/types/pageview.ex"
Task: "Create pageview filter input in lib/plausible_web/graphql/types/filters.ex"
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

---

## Task Count Summary

| Phase | Task Count |
|-------|------------|
| Phase 1: Setup | 3 |
| Phase 2: Foundational | 6 |
| Phase 3: US1 - Pageviews | 10 |
| Phase 4: US2 - Events | 8 |
| Phase 5: US3 - Aggregation | 9 |
| Phase 6: US4 - Custom Metrics | 5 |
| Phase 7: Polish | 5 |
| **Total** | **46** |
| **Completed** | **31** |
| **Remaining** | **15** |
