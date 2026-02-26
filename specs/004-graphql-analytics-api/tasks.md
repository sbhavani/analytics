---

description: "Task list for GraphQL Analytics API feature implementation"
---

# Tasks: GraphQL Analytics API

**Input**: Design documents from `/specs/004-graphql-analytics-api/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: Required - TDD approach mandated by Constitution. Write tests first, ensure they fail before implementation.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and Absinthe GraphQL dependency setup

- [x] T001 Create GraphQL module directory structure in lib/plausible/graphqla/
- [x] T002 Add Absinthe dependencies to mix.exs if not present
- [x] T003 [P] Configure GraphQLAbsinthe in lib/plausible_web/endpoint.ex

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T004 Setup GraphQL schema boilerplate in lib/plausible_graphqla/schema.ex
- [x] T005 Create GraphQL types directory structure in lib/plausible_graphqla/types/
- [x] T006 [P] Define common scalar types (Date, DateTime, JSON) in lib/plausible_graphqla/types/scalars.ex
- [x] T007 [P] Define connection types for pagination in lib/plausible_graphqla/types/connection.ex
- [x] T008 Create GraphQL resolvers directory in lib/plausible_graphqla/resolvers/
- [x] T009 Setup authentication middleware for GraphQL endpoint in lib/plausible_graphqla/middleware/
- [x] T010 Add GraphQL route to router in lib/plausible_web/router.ex

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Query Pageview Data (Priority: P1) 🎯 MVP

**Goal**: Implement GraphQL endpoint to query pageview data with date range and URL filtering

**Independent Test**: Can be fully tested by making a GraphQL query for pageviews and verifying the response contains expected pageview records with proper data structure

### Tests for User Story 1 (TDD - Write First) ⚠️

> NOTE: Write these tests FIRST, ensure they FAIL before implementation

- [x] T011 [P] [US1] Write unit tests for PageviewType in test/plausible_graphqla/types/pageview_type_test.exs
- [x] T012 [P] [US1] Write integration test for pageviews query in test/plausible_graphqla/pageviews_query_test.exs

### Implementation for User Story 1

- [x] T013 [P] [US1] Define PageviewFilter input type in lib/plausible_graphqla/types/pageview_types.ex
- [x] T014 [P] [US1] Define Pageview object type in lib/plausible_graphqla/types/pageview_types.ex
- [x] T015 [US1] Implement pageview resolver in lib/plausible_graphqla/resolvers/pageview_resolver.ex (depends on T013, T014)
- [x] T016 [US1] Add pageviews query to schema in lib/plausible_graphqla/schema.ex
- [x] T017 [US1] Connect pageviews query to existing ClickHouse query infrastructure
- [x] T018 [US1] Add date range filter parsing in pageview resolver
- [x] T019 [US1] Add URL pattern filter support in pageview resolver

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Query Event Data (Priority: P2)

**Goal**: Implement GraphQL endpoint to query event data with date range and event type filtering

**Independent Test**: Can be fully tested by making a GraphQL query for events and verifying the response contains expected event records

### Tests for User Story 2 (TDD - Write First) ⚠️

- [x] T020 [P] [US2] Write unit tests for EventType in test/plausible/graphqla/types/event_type_test.exs
- [x] T021 [P] [US2] Write integration test for events query in test/plausible_graphqla/events_query_test.exs

### Implementation for User Story 2

- [x] T022 [P] [US2] Define EventFilter input type in lib/plausible_graphqla/types/event_types.ex
- [x] T023 [P] [US2] Define Event object type in lib/plausible_graphqla/types/event_types.ex
- [x] T024 [US2] Implement event resolver in lib/plausible_graphqla/resolvers/event_resolver.ex (depends on T022, T023)
- [x] T025 [US2] Add events query to schema in lib/plausible_graphqla/schema.ex
- [x] T026 [US2] Connect events query to existing ClickHouse query infrastructure
- [x] T027 [US2] Add event type filter support in event resolver

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Query Custom Metrics (Priority: P2)

**Goal**: Implement GraphQL endpoint to query custom metrics data with metric name filtering

**Independent Test**: Can be fully tested by making a GraphQL query for custom metrics and verifying the response contains expected metric records

### Tests for User Story 3 (TDD - Write First) ⚠️

- [x] T028 [P] [US3] Write unit tests for CustomMetricType in test/plausible_graphqla/types/custom_metric_type_test.exs
- [x] T029 [P] [US3] Write integration test for custom metrics query in test/plausible_graphqla/custom_metrics_query_test.exs

### Implementation for User Story 3

- [x] T030 [P] [US3] Define CustomMetricFilter input type in lib/plausible_graphqla/types/custom_metric_types.ex
- [x] T031 [P] [US3] Define CustomMetric object type in lib/plausible_graphqla/types/custom_metric_types.ex
- [x] T032 [US3] Implement custom metric resolver in lib/plausible_graphqla/resolvers/custom_metric_resolver.ex (depends on T030, T031)
- [x] T033 [US3] Add customMetrics query to schema in lib/plausible_graphqla/schema.ex
- [x] T034 [US3] Connect custom metrics query to existing ClickHouse query infrastructure
- [x] T035 [US3] Add metric name filter support in custom metric resolver

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - Aggregate Analytics Data (Priority: P3)

**Goal**: Implement GraphQL endpoint to retrieve aggregated analytics data with time-based and categorical groupings

**Independent Test**: Can be fully tested by making a GraphQL query with aggregation functions and verifying the response contains correct calculated values

### Tests for User Story 4 (TDD - Write First) ⚠️

- [x] T036 [P] [US4] Write integration test for aggregation queries in test/plausible_graphqla/aggregation_query_test.exs

### Implementation for User Story 4

- [x] T037 [P] [US4] Define AggregationResult object type in lib/plausible_graphqla/types/aggregation_types.ex
- [x] T038 [P] [US4] Define TimeGranularity enum in lib/plausible_graphqla/types/aggregation_types.ex
- [x] T039 [US4] Implement aggregation resolver in lib/plausible_graphqla/resolvers/aggregation_resolver.ex (depends on T037, T038)
- [x] T040 [US4] Add aggregation queries to schema in lib/plausible_graphqla/schema.ex
- [x] T041 [US4] Implement time-based aggregation (day, week, month) for pageviews
- [x] T042 [US4] Implement categorical aggregation for events by event type
- [x] T043 [US4] Implement sum/count/average aggregations for custom metrics

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T044 [P] Add query complexity analysis to prevent expensive queries
- [x] T045 Implement rate limiting for GraphQL endpoint
- [x] T046 Add structured logging for GraphQL queries
- [x] T047 [P] Performance testing for 90-day range queries
- [x] T048 Update API documentation with GraphQL examples
- [ ] T049 Run quickstart.md validation - verify all example queries work

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
- **User Story 2 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - May integrate with US1 but should be independently testable
- **User Story 4 (P3)**: Can start after Foundational (Phase 2) - Depends on US1, US2, US3 being functional for aggregation

### Within Each User Story

- Tests (TDD) MUST be written and FAIL before implementation
- Types before resolvers
- Resolvers before schema queries
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, User Stories 1, 2, and 3 can start in parallel
- All tests for a user story marked [P] can run in parallel
- Types within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Write unit tests for PageviewType in test/plausible_graphqla/types/pageview_type_test.exs"
Task: "Write integration test for pageviews query in test/plausible_graphqla/pageviews_query_test.exs"

# Launch all types for User Story 1 together:
Task: "Define PageviewFilter input type in lib/plausible_graphqla/types/pageview_types.ex"
Task: "Define Pageview objectausible_graphqla type in lib/pl/types/pageview_types.ex"
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
- Verify tests fail before implementing (TDD approach)
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
