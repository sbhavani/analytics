---

description: "Task list for GraphQL Analytics API feature implementation"

---

# Tasks: GraphQL Analytics API

**Input**: Design documents from `/specs/010-graphql-analytics-api/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Required per Constitution - Test-Driven Development is mandatory

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency configuration

- [ ] T001 Add Absinthe GraphQL dependency to mix.exs
- [X] T002 [P] Add Absinthe.Plug and Absinthe.Plug.cto dependencies
- [ ] T003 Create GraphQL directory structure in lib/plausible/graphql/
- [ ] T004 Create test directory structure in test/plausible/graphql/

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [ ] T005 Create GraphQL schema module in lib/plausible/graphql/schema.ex
- [X] T006 [P] Create GraphQL types module in lib/plausible/graphql/types.ex
- [X] T007 [P] Create query object in lib/plausible/graphql/resolvers.ex
- [ ] T008 Create GraphQL plug/router setup in lib/plausible_web/endpoint/graphql.ex
- [ ] T009 Add GraphQL route to router in lib/plausible_web/router.ex
- [ ] T010 Create authentication middleware for GraphQL in lib/plausible/graphql/middleware/auth.ex
- [ ] T011 Create authorization middleware for site access in lib/plausible/graphql/middleware/authorization.ex
- [ ] T012 Create error handling for GraphQL in lib/plausible/graphql/error_handler.ex
- [ ] T013 Setup structured logging for GraphQL operations

**Checkpoint**: Foundation ready - user story implementation can now begin

---

## Phase 3: User Story 1 - Query Pageview Data (Priority: P1) 🎯 MVP

**Goal**: Enable users to retrieve pageview statistics with date range and page filters

**Independent Test**: Query pageview data for a specific date range and verify returned records match expected pageview counts

### Tests for User Story 1 ⚠️

- [X] T014 [P] [US1] Unit test for pageview GraphQL types in test/plausible/graphql/types_test.exs
- [X] T015 [P] [US1] Unit test for pageview resolver in test/plausible/graphql/resolvers/pageview_test.exs
- [ ] T016 [US1] Integration test for pageview query in test/plausible/graphql/integration/pageview_test.exs
- [ ] T017 [US1] Contract test for pageview API endpoint in test/plausible/graphql/contract/pageview_test.exs

### Implementation for User Story 1

- [X] T018 [P] [US1] Define Pageview type in lib/plausible/graphql/types/pageview_types.ex
- [X] T019 [P] [US1] Define PageviewFilterInput in lib/plausible/graphql/types/pageview_types.ex
- [ ] T020 [US1] Implement pageview resolver using existing Plausible.Stats in lib/plausible/graphql/resolvers/pageview.ex
- [ ] T021 [US1] Add pageviews query to schema in lib/plausible/graphql/schema.ex
- [ ] T022 [US1] Add pageviewAggregate query to schema in lib/plausible/graphql/schema.ex
- [ ] T023 [US1] Implement pagination support for pageview queries
- [ ] T024 [US1] Add date range validation (max 12 months)

**Checkpoint**: User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Query Event Data (Priority: P1)

**Goal**: Enable users to retrieve event data with event type filters

**Independent Test**: Query event data for specific event types and verify returned events match expected records

### Tests for User Story 2 ⚠️

- [X] T025 [P] [US2] Unit test for event GraphQL types in test/plausible/graphql/types_test.exs
- [X] T026 [P] [US2] Unit test for event resolver in test/plausible/graphql/resolvers/event_test.exs
- [ ] T027 [US2] Integration test for event query in test/plausible/graphql/integration/event_test.exs
- [ ] T028 [US2] Contract test for event API endpoint in test/plausible/graphql/contract/event_test.exs

### Implementation for User Story 2

- [X] T029 [P] [US2] Define Event type in lib/plausible/graphql/types/event_types.ex
- [X] T030 [P] [US2] Define EventFilterInput in lib/plausible/graphql/types/event_types.ex
- [ ] T031 [US2] Implement event resolver using existing Plausible.Stats in lib/plausible/graphql/resolvers/event.ex
- [ ] T032 [US2] Add events query to schema in lib/plausible/graphql/schema.ex
- [ ] T033 [US2] Add eventAggregate query to schema in lib/plausible/graphql/schema.ex

**Checkpoint**: User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Query Custom Metrics (Priority: P2)

**Goal**: Enable users to retrieve custom business metrics with name filters

**Independent Test**: Query custom metrics and verify returned values match expected data

### Tests for User Story 3 ⚠️

- [X] T034 [P] [US3] Unit test for custom metric GraphQL types in test/plausible/graphql/types_test.exs
- [X] T035 [P] [US3] Unit test for custom metric resolver in test/plausible/graphql/resolvers/custom_metric_test.exs
- [ ] T036 [US3] Integration test for custom metric query in test/plausible/graphql/integration/custom_metric_test.exs
- [ ] T037 [US3] Contract test for custom metric API endpoint in test/plausible/graphql/contract/custom_metric_test.exs

### Implementation for User Story 3

- [X] T038 [P] [US3] Define CustomMetric type in lib/plausible/graphql/types/custom_metric_types.ex
- [X] T039 [P] [US3] Define MetricFilterInput in lib/plausible/graphql/types/custom_metric_types.ex
- [ ] T040 [US3] Implement custom metric resolver in lib/plausible/graphql/resolvers/custom_metric.ex
- [ ] T041 [US3] Add customMetrics query to schema in lib/plausible/graphql/schema.ex
- [ ] T042 [US3] Add customMetricAggregate query to schema in lib/plausible/graphql/schema.ex

**Checkpoint**: All three core data types (pageviews, events, custom metrics) now accessible

---

## Phase 6: User Story 4 - Filter and Aggregate Analytics Data (Priority: P2)

**Goal**: Enable users to filter by multiple criteria and aggregate data with various operations

**Independent Test**: Apply various filters and aggregations and verify results match expected computed values

### Tests for User Story 4 ⚠️

- [X] T043 [P] [US4] Unit test for aggregation types in test/plausible/graphql/types_test.exs
- [X] T044 [P] [US4] Unit test for filter input handling in test/plausible/graphql/resolvers/filter_test.exs
- [ ] T045 [US4] Integration test for combined filters in test/plausible/graphql/integration/filter_test.exs

### Implementation for User Story 4

- [X] T046 [P] [US4] Define AggregationInput and AggregationType enum in lib/plausible/graphql/types/common_types.ex
- [X] T047 [P] [US4] Define DateRangeInput in lib/plausible/graphql/types/common_types.ex
- [ ] T048 [US4] Implement aggregation logic in lib/plausible/graphql/resolvers/aggregation.ex
- [ ] T049 [US4] Implement multi-filter support in lib/plausible/graphql/resolvers/filter.ex
- [ ] T050 [US4] Add comprehensive error messages for invalid aggregations

**Checkpoint**: All user stories should now be independently functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T051 [P] Run Credo linting and fix any issues
- [X] T052 [P] Add performance benchmarks for query execution in benchmarks/graphql/
- [ ] T053 Verify all success criteria from spec.md are met
- [ ] T054 Update quickstart.md with working examples
- [ ] T055 Add rate limiting for GraphQL endpoint
- [ ] T056 Final integration tests across all user stories in test/plausible/graphql/integration/full_test.exs
- [ ] T057 Run full test suite and fix any failures

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Independently testable
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - Independently testable
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Builds on US1-US3 functionality

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Types before resolvers
- Resolvers before schema integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, all user stories can start in parallel
- All tests for a user story marked [P] can run in parallel
- Types within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for pageview GraphQL types in test/plausible/graphql/types_test.exs"
Task: "Unit test for pageview resolver in test/plausible/graphql/resolvers/pageview_test.exs"

# Launch all types for User Story 1 together:
Task: "Define Pageview type in lib/plausible/graphql/types/pageview_types.ex"
Task: "Define PageviewFilterInput in lib/plausible/graphql/types/pageview_types.ex"
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

## Summary

- **Total Tasks**: 57
- **Tasks per User Story**:
  - US1 (Pageview Data): 12 tasks
  - US2 (Event Data): 10 tasks
  - US3 (Custom Metrics): 9 tasks
  - US4 (Filter & Aggregate): 8 tasks
- **Setup Phase**: 4 tasks
- **Foundational Phase**: 9 tasks
- **Polish Phase**: 7 tasks

### Independent Test Criteria

- **US1**: Can query pageviews with date range and verify count matches expected
- **US2**: Can query events by type and verify events are returned
- **US3**: Can query custom metrics and verify values
- **US4**: Can apply multiple filters and aggregations and verify computed results

### Suggested MVP Scope

Implement through Phase 3 (User Story 1) - Query Pageview Data. This delivers the core GraphQL endpoint with pageview queries, which provides immediate value and validates the architecture before expanding to other data types.

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
