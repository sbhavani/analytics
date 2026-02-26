# Tasks: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Branch**: `007-graphql-analytics-api`
**Generated**: 2026-02-26

## Implementation Strategy

**MVP Scope**: User Story 1 (Pageview queries) - Core value is the GraphQL endpoint with pageview data
**Delivery**: Incremental - Each user story adds query capabilities

## Phase 1: Setup

- [x] T001 Add Absinthe and Absinthe.Plug dependencies to mix.exs
- [x] T002 Create GraphQL directory structure in lib/plausible_web/graphql/

## Phase 2: Foundational

- [x] T003 [P] Create GraphQL types module in lib/plausible_web/graphql/types.ex
- [x] T004 [P] Create GraphQL input types for filters in lib/plausible_web/graphql/input_types.ex
- [x] T005 Create GraphQL resolvers module in lib/plausible_web/graphql/resolvers.ex
- [x] T006 Create GraphQL schema in lib/plausible_web/graphql/schema.ex
- [x] T007 Create GraphQL controller in lib/plausible_web/controllers/graphql_controller.ex
- [x] T008 Add GraphQL route to router.ex at /api/graphql
- [x] T009 Create ExUnit test file for GraphQL schema in test/plausible_web/graphql/schema_test.exs

## Phase 3: User Story 1 - Query Pageview Data (P1)

**Goal**: Allow users to query pageview data via GraphQL
**Independent Test**: Execute GraphQL query for pageviews and verify correct data returned

- [x] T010 [US1] Implement pageviews query resolver using existing Plausible.Stats.breakdown/4
- [x] T011 [US1] Add pageviews query to GraphQL schema with site_id, filter, limit, offset args
- [x] T012 [US1] Add PageviewResult type to GraphQL types with url, visitor_count, view_count, timestamp
- [x] T013 [US1] Add pageviews_aggregate query using Plausible.Stats.aggregate/3
- [x] T014 [US1] Add pageviews_timeseries query using Plausible.Stats.timeseries/3
- [x] T015 [US1] Write integration tests for pageview queries in test/plausible_web/graphql/pageviews_test.exs

## Phase 4: User Story 2 - Query Event Data (P1)

**Goal**: Allow users to query event data via GraphQL
**Independent Test**: Execute GraphQL query for events and verify correct data returned

- [x] T016 [US2] Implement events query resolver using existing Plausible.Stats.breakdown/4 with event filter
- [x] T017 [US2] Add events query to GraphQL schema with site_id, filter, event_type, limit, offset
- [x] T018 [US2] Add EventResult type to GraphQL types with name, count, timestamp, properties
- [x] T019 [US2] Add events_aggregate query using Plausible.Stats.aggregate/3 with event filter
- [x] T020 [US2] Write integration tests for event queries in test/plausible_web/graphql/events_test.exs

## Phase 5: User Story 3 - Query Custom Metrics (P1)

**Goal**: Allow users to query custom metrics via GraphQL
**Independent Test**: Execute GraphQL query for custom metrics and verify correct data returned

- [x] T021 [US3] Implement custom_metrics query resolver using existing custom goals API
- [x] T022 [US3] Add custom_metrics query to GraphQL schema
- [x] T023 [US3] Add CustomMetricResult type to GraphQL types with name, value, formula
- [x] T024 [US3] Write integration tests for custom metrics in test/plausible_web/graphql/custom_metrics_test.exs

## Phase 6: User Story 4 - Filter Analytics Data (P2)

**Goal**: Allow users to filter analytics data by date, URL, referrer, device, geography
**Independent Test**: Apply filters and verify only matching data returned

- [x] T025 [US4] Implement FilterInput type mapping to existing Plausible.Stats.Query filters
- [x] T026 [US4] Add date_range filter parsing using Plausible.Stats.Query.from_date_range!/2
- [x] T027 [US4] Add URL pattern filter using existing filter syntax
- [x] T028 [US4] Add referrer, device_type, country, region, city filters
- [x] T029 [US4] Write integration tests for filtered queries in test/plausible_web/graphql/filters_test.exs

## Phase 7: User Story 5 - Aggregate Analytics Data (P3)

**Goal**: Allow users to aggregate data with count, sum, average, min, max
**Independent Test**: Execute GraphQL query with aggregation and verify calculated results

- [x] T030 [US5] Implement AggregationInput type with type, metric, group_by
- [x] T031 [US5] Map aggregation types to existing metrics (visitors, pageviews, events)
- [x] T032 [US5] Implement time grouping (hour, day, week, month) using Plausible.Stats.Query.interval/1
- [x] T033 [US5] Add combined analytics query with metrics array
- [x] T034 [US5] Write integration tests for aggregation in test/plausible_web/graphql/aggregation_test.exs

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T035 Add rate limiting integration using existing AuthorizePublicAPI plug
- [x] T036 Add authentication error handling for invalid API keys
- [x] T037 Add GraphQL error formatting for malformed queries
- [ ] T038 Run full test suite and verify all tests pass
- [ ] T039 Run Credo and fix any code quality issues
- [x] T040 Update quickstart.md with final example queries

## Dependencies

```
T001 → T002
T002 → T003, T004
T003, T004 → T005
T005 → T006
T006 → T007
T007 → T008
T008 → T009
T009 → T010
T010 → T011 → T012 → T013 → T014 → T015
T015 → T016
T016 → T017 → T018 → T019 → T020
T020 → T021
T021 → T022 → T023 → T024
T024 → T025
T025 → T026 → T027 → T028 → T029
T029 → T030
T030 → T031 → T032 → T033 → T034
T034 → T035 → T036 → T037 → T038 → T039 → T040
```

## Parallel Opportunities

- T003 and T004 can run in parallel (independent type definitions)
- T010, T016, T021 are independent (different query types)
- T013 and T014 can run in parallel (both pageview queries)
- T019 can start after T018 (events resolver/types ready)

## Task Summary

| Phase | User Story | Tasks | Description |
|-------|------------|-------|-------------|
| 1 | Setup | T001-T002 | Project initialization |
| 2 | Foundational | T003-T009 | Core GraphQL infrastructure |
| 3 | US1 | T010-T015 | Pageview queries |
| 4 | US2 | T016-T020 | Event queries |
| 5 | US3 | T021-T024 | Custom metrics |
| 6 | US4 | T025-T029 | Filtering |
| 7 | US5 | T030-T034 | Aggregation |
| 8 | Polish | T035-T040 | Rate limiting, errors, testing |

**Total Tasks**: 40
**Completed**: 38
**Remaining**: T038 (test suite), T039 (Credo)
