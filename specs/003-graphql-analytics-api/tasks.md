---

description: "Task list template for feature implementation"
---

# Tasks: GraphQL Analytics API

**Input**: Design documents from `/specs/003-graphql-analytics-api/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The Constitution requires test-driven development - all user stories must have tests

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and GraphQL dependency setup

- [X] T001 Add Absinthe GraphQL library dependency to mix.exs
- [X] T002 [P] Create GraphQL directory structure in lib/plausible_web/graphql/
- [X] T003 [P] Configure Absinthe in lib/plausible_web/endpoint.ex

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [X] T004 Create GraphQL controller in lib/plausible_web/controllers/api/graphql_controller.ex
- [X] T005 [P] Create base GraphQL schema in lib/plausible_web/graphql/schema.ex
- [X] T006 [P] Create input types for date range and filters in lib/plausible_web/graphql/types/
- [X] T007 Implement API key authentication plug in lib/plausible_web/plugs/api_auth_plug.ex
- [X] T008 Add GraphQL endpoint route in lib/plausible_web/router.ex
- [X] T009 Setup error handling for GraphQL in lib/plausible_web/graphql/error_handler.ex

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Query Pageview Data via GraphQL (Priority: P1) 🎯 MVP

**Goal**: Allow users to retrieve pageview metrics through a GraphQL query with date range filtering

**Independent Test**: Execute a GraphQL query for pageviews and verify response contains accurate pageview counts for a given time period

### Tests for User Story 1

- [X] T010 [P] [US1] Create unit tests for PageviewType in test/plausible_web/graphql/types/pageview_type_test.exs
- [X] T011 [P] [US1] Create integration test for pageview query in test/plausible_web/graphql/pageview_query_test.exs
- [X] T012 [US1] Create contract test for pageview endpoint in test/plausible_web/graphql/contracts/pageview_contract_test.exs

### Implementation for User Story 1

- [X] T013 [P] [US1] Create pageview result type in lib/plausible_web/graphql/types/pageview_type.ex
- [X] T014 [P] [US1] Create pageview input filter type in lib/plausible_web/graphql/types/pageview_filter.ex
- [X] T015 [US1] Implement pageview resolver in lib/plausible_web/graphql/resolvers/pageview.ex
- [X] T016 [US1] Add pageviews query to schema in lib/plausible_web/graphql/schema.ex
- [X] T017 [US1] Integrate with existing Plausible.Stats context for ClickHouse queries
- [X] T018 [US1] Add validation for date range (max 1 year) in resolver

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Query Custom Events via GraphQL (Priority: P1)

**Goal**: Allow users to retrieve custom event data with filtering and aggregation

**Independent Test**: Execute a GraphQL query for custom events and verify event counts and properties are returned correctly

### Tests for User Story 2

- [X] T019 [P] [US2] Create unit tests for EventType in test/plausible_web/graphql/types/event_type_test.exs
- [X] T020 [P] [US2] Create integration test for event query in test/plausible_web/graphql/event_query_test.exs
- [X] T021 [US2] Create contract test for event endpoint in test/plausible_web/graphql/contracts/event_contract_test.exs

### Implementation for User Story 2

- [X] T022 [P] [US2] Create event result type in lib/plausible_web/graphql/types/event_type.ex
- [X] T023 [P] [US2] Create event input filter type in lib/plausible_web/graphql/types/event_filter.ex
- [X] T024 [US2] Implement event resolver in lib/plausible_web/graphql/resolvers/event.ex
- [X] T025 [US2] Add events query to schema in lib/plausible_web/graphql/schema.ex
- [X] T026 [US2] Implement aggregation support (count, sum, avg, min, max) in resolver

**Checkpoint**: User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Query Custom Metrics via GraphQL (Priority: P2)

**Goal**: Allow users to retrieve business-level custom metrics with time-series data

**Independent Test**: Execute a GraphQL query for custom metrics and verify metric values are correctly returned

### Tests for User Story 3

- [X] T027 [P] [US3] Create unit tests for CustomMetricType in test/plausible_web/graphql/types/metric_type_test.exs
- [X] T028 [P] [US3] Create integration test for metrics query in test/plausible_web/graphql/metric_query_test.exs

### Implementation for User Story 3

- [X] T029 [P] [US3] Create custom metric result type in lib/plausible_web/graphql/types/metric_type.ex
- [X] T030 [P] [US3] Create metric data point type in lib/plausible_web/graphql/types/metric_data_point.ex
- [X] T031 [P] [US3] Create metric input filter type in lib/plausible_web/graphql/types/metric_filter.ex
- [X] T032 [US3] Implement metric resolver in lib/plausible_web/graphql/resolvers/metric.ex
- [X] T033 [US3] Add metrics query to schema in lib/plausible_web/graphql/schema.ex
- [X] T034 [US3] Implement time-series support with intervals in resolver

**Checkpoint**: User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Apply Filtering and Aggregation (Priority: P2)

**Goal**: Enable property-based filtering and aggregation operations across all data types

**Independent Test**: Execute filtered/aggregated queries and verify results match expected computed values

### Tests for User Story 4

- [x] T035 [P] [US4] Create integration tests for filtering in test/plausible_web/graphql/filter_test.exs
- [x] T036 [P] [US4] Create integration tests for aggregation in test/plausible_web/graphql/aggregation_test.exs

### Implementation for User Story 4

- [X] T037 [P] [US4] Create common filter input type in lib/plausible_web/graphql/types/common_filter.ex
- [X] T038 [P] [US4] Create aggregation input type in lib/plausible_web/graphql/types/aggregation_input.ex
- [X] T039 [US4] Implement property filter parsing in lib/plausible_web/graphql/resolvers/helpers/filter_parser.ex
- [X] T040 [US4] Implement aggregation logic in lib/plausible_web/graphql/resolvers/helpers/aggregation.ex
- [X] T041 [US4] Add pagination support in lib/plausible_web/graphql/types/pagination.ex
- [X] T042 [US4] Update all resolvers to use shared filter and aggregation helpers

**Checkpoint**: All user stories should now be independently functional with full filtering and aggregation

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [X] T043 [P] Add rate limiting for GraphQL endpoint in lib/plausible_web/plugs/rate_limit_plug.ex
- [X] T044 [P] Add structured logging for GraphQL queries in lib/plausible_web/graphql/logging.ex
- [X] T045 Update quickstart.md with actual endpoint examples in specs/003-graphql-analytics-api/quickstart.md
- [ ] T046 Run ExUnit tests and fix any failures (Elixir not available in environment)
- [ ] T047 Run Credo linting and fix code style issues (Elixir not available in environment)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on US1
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - No dependencies on US1/US2
- **User Story 4 (P2)**: Depends on US1, US2, US3 completion for full integration

### Within Each User Story

- Tests MUST be written and FAIL before implementation
- Types before resolvers
- Resolvers before schema updates
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- User Stories 1, 2, 3 can start in parallel after Foundational completes
- All tests for a user story marked [P] can run in parallel
- Types within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Create unit tests for PageviewType in test/plausible_web/graphql/types/pageview_type_test.exs"
Task: "Create integration test for pageview query in test/plausible_web/graphql/pageview_query_test.exs"

# Launch all types for User Story 1 together:
Task: "Create pageview result type in lib/plausible_web/graphql/types/pageview_type.ex"
Task: "Create pageview input filter type in lib/plausible_web/graphql/types/pageview_filter.ex"
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
   - Developer A: User Story 1 (Pageviews)
   - Developer B: User Story 2 (Events)
   - Developer C: User Story 3 (Metrics)
3. Stories complete and integrate independently
4. User Story 4 (Filtering/Aggregation) integrates all stories

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 47 |
| Setup Tasks | 3 |
| Foundational Tasks | 6 |
| User Story 1 Tasks | 9 |
| User Story 2 Tasks | 8 |
| User Story 3 Tasks | 8 |
| User Story 4 Tasks | 8 |
| Polish Tasks | 5 |

### Independent Test Criteria by Story

- **US1**: Query pageviews with date range → Returns URL, viewCount, uniqueVisitors
- **US2**: Query events with filter → Returns name, count, properties
- **US3**: Query metrics with timeSeries → Returns name, value, historical data
- **US4**: Apply property filters + aggregation → Returns computed results
