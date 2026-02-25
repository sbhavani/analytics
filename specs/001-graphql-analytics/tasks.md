# Tasks: GraphQL Analytics API

**Feature**: GraphQL Analytics API | **Branch**: `001-graphql-analytics`
**Generated**: 2026-02-25

## Implementation Strategy

**MVP Scope**: User Story 1 (Pageviews) - Core query capability with basic date range filtering
**Delivery**: Incremental - Each user story is independently testable

### User Story Dependencies

- US1 (Pageviews): FOUNDATIONAL → Complete first
- US2 (Events): FOUNDATIONAL → Can parallel with US1 after setup
- US3 (Custom Metrics): US1+US2 → Requires pageview/event foundation
- US4 (Filters/Aggregation): Built into all stories

### Parallel Opportunities

- US1 and US2 can be implemented in parallel after Phase 2 (Foundational)

---

## Phase 1: Setup

- [X] T001 Add Absinthe dependency to mix.exs
- [X] T002 Add Absinthe Plug to endpoint.ex (handled via router)
- [X] T003 Create lib/plausible/graphql directory structure

---

## Phase 2: Foundational

*Blocking prerequisites - MUST complete before user stories*

- [X] T004 Create DateRangeInput type in lib/plausible/graphql/types/date_range_input.ex
- [X] T005 Create AggregationInput type in lib/plausible/graphql/types/aggregation_input.ex
- [X] T006 Create PaginationInput type in lib/plausible/graphql/types/pagination_input.ex
- [X] T007 Create PageviewFilterInput type in lib/plausible/graphql/types/pageview_filter_input.ex
- [X] T008 Create EventFilterInput type in lib/plausible/graphql/types/event_filter_input.ex
- [X] T009 Create MetricFilterInput type in lib/plausible/graphql/types/metric_filter_input.ex
- [X] T010 Create PaginationInfo type in lib/plausible/graphql/types/pagination_info.ex
- [X] T011 Create base GraphQL schema in lib/plausible/graphql/schema.ex
- [X] T012 [P] Write unit tests for input types in test/plausible/graphql/types_test.exs

---

## Phase 3: User Story 1 - Query Pageview Data (P1)

*Goal: API consumers can retrieve pageview analytics with date range filters*

**Independent Test**: Send GraphQL query for pageviews with date range, verify response contains accurate pageview counts

- [X] T013 Create Pageview type in lib/plausible/graphql/types/pageview.ex
- [X] T014 Create PageviewResult type in lib/plausible/graphql/types/pageview_result.ex
- [X] T015 Create PageviewResolver module in lib/plausible/graphql/resolvers/pageview_resolver.ex
- [X] T016 Add pageviews query to schema in lib/plausible/graphql/schema.ex
- [X] T017 Write ExUnit tests for pageview resolver in test/plausible/graphql/pageview_resolver_test.exs
- [X] T018 [P] Test pageviews query with date range filter via GraphQL controller test

---

## Phase 4: User Story 2 - Query Event Data (P1)

*Goal: API consumers can retrieve event analytics with filters*

**Independent Test**: Send GraphQL query for events with event type filter, verify response contains matching events

- [X] T019 Create Event type in lib/plausible/graphql/types/event.ex
- [X] T020 Create EventResult type in lib/plausible/graphql/types/event_result.ex
- [X] T021 Create EventResolver module in lib/plausible/graphql/resolvers/event_resolver.ex
- [X] T022 Add events query to schema in lib/plausible/graphql/schema.ex
- [X] T023 Write ExUnit tests for event resolver in test/plausible/graphql/event_resolver_test.exs
- [X] T024 [P] Test events query with event type filter via GraphQL controller test

---

## Phase 5: User Story 3 - Query Custom Metrics (P2)

*Goal: API consumers can retrieve custom metrics by name with time aggregation*

**Independent Test**: Send GraphQL query for custom metrics, verify response contains metric values

- [X] T025 Create CustomMetric type in lib/plausible/graphql/types/custom_metric.ex
- [X] T026 Create MetricResult type in lib/plausible/graphql/types/metric_result.ex
- [X] T027 Create MetricResolver module in lib/plausible/graphql/resolvers/metric_resolver.ex
- [X] T028 Add metrics query to schema in lib/plausible/graphql/schema.ex
- [X] T029 Write ExUnit tests for metric resolver in test/plausible/graphql/metric_resolver_test.exs
- [X] T030 [P] Test metrics query with aggregation via GraphQL controller test

---

## Phase 6: User Story 4 - Filter and Aggregate Analytics (P2)

*Goal: API consumers can apply filters and aggregations across all query types*

**Independent Test**: Send GraphQL queries with various filter combinations and aggregation functions

- [X] T031 Implement multi-dimension filtering in PageviewResolver
- [X] T032 Implement multi-dimension filtering in EventResolver
- [X] T033 Implement aggregation functions (SUM, COUNT, AVG, MIN, MAX) in resolvers
- [X] T034 Implement time-based aggregation (HOUR, DAY, WEEK, MONTH) in resolvers
- [X] T035 Add validation for date range max 366 days in resolvers
- [X] T036 Write integration tests for combined filter + aggregation scenarios

---

## Phase 7: Integration & API Endpoint

- [X] T037 Create GraphQL controller in lib/plausible_web/controllers/api/graphql_controller.ex
- [X] T038 Add /api/graphql route to router.ex
- [X] T039 Integrate existing AuthorizePublicAPI plug with stats:read:* scope
- [ ] T040 Add rate limit headers to GraphQL responses
- [X] T041 Write controller integration tests in test/plausible_web/controllers/api/graphql_controller_test.exs

---

## Phase 8: Testing & Validation

- [ ] T042 Run existing test suite to ensure no regressions
- [ ] T043 Test GraphQL introspection query works
- [ ] T044 Test error responses for invalid queries (FR-011)
- [ ] T045 Test combined multi-type query (SC-005)

---

## Phase 9: Polish

- [ ] T046 Verify performance meets < 5 second target (SC-004)
- [X] T047 Add structured logging for GraphQL queries
- [X] T048 Update OpenTelemetry with GraphQL span data

---

## Task Count Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| Phase 1 | 3 | Setup |
| Phase 2 | 9 | Foundational |
| Phase 3 (US1) | 6 | Pageviews |
| Phase 4 (US2) | 6 | Events |
| Phase 5 (US3) | 6 | Custom Metrics |
| Phase 6 (US4) | 6 | Filters & Aggregation |
| Phase 7 | 5 | Integration |
| Phase 8 | 4 | Testing |
| Phase 9 | 3 | Polish |
| **Total** | **48** | |

---

## Independent Test Criteria

| User Story | Test Criteria |
|------------|---------------|
| US1 - Pageviews | Query pageviews with date range returns accurate counts |
| US2 - Events | Query events with event type filter returns matching events |
| US3 - Custom Metrics | Query metrics by name returns values for time period |
| US4 - Filters/Aggregation | Combined filters + aggregation produce correct results |

---

## Parallel Execution Examples

```elixir
# After Phase 2 complete, these can run in parallel:
# Task T013-T018 (US1: Pageviews) and T019-T024 (US2: Events)
# Task T029 and T030 can run in parallel (different resolvers)
```
