# Tasks: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Branch**: 009-graphql-analytics-api
**Generated**: 2026-02-26

## Implementation Strategy

This feature will be implemented incrementally with MVP first approach. User Story 1 (Query Analytics) represents the core value and should be delivered first.

### MVP Scope
- User Story 1: Core GraphQL query endpoint with basic aggregation
- Can be tested independently
- Provides immediate value: programmatic analytics access

### Incremental Delivery
- Each user story builds on the previous
- Filter capabilities add to query functionality
- Aggregation builds on filtering
- Custom metrics add advanced functionality

## Dependencies

User Story completion order (can be executed in parallel where marked):

```
[Setup] --> [Foundational] --> [US1: Query] --> [US2: Filter] --> [US3: Aggregate] --> [US4: Custom Metrics] --> [Polish]
                         |                   |
                         |                   +--> [Can parallelize: different query types]
                         |
                         +--> [Blocker: All stories need schema + types]
```

## Phase 1: Setup

- [x] T001 Add Absinthe dependency to mix.exs
- [x] T002 Add Absinthe.Plug to endpoint configuration
- [x] T003 Run mix deps.get to fetch dependencies

## Phase 2: Foundational

- [x] T004 Create GraphQL directory structure in lib/plausible_web/graphql/
- [x] T005 Create base schema.ex with query types
- [x] T006 Create input types (DateRangeInput, FilterInput) in lib/plausible_web/graphql/types/input_types.ex
- [x] T007 Create enum types (Metric, Dimension, Granularity) in lib/plausible_web/graphql/types/enums.ex
- [x] T008 Create object types (AggregateResult, TimeSeriesPoint, BreakdownResult) in lib/plausible_web/graphql/types/analytics_types.ex
- [x] T009 Create GraphQL context for authentication in lib/plausible_web/graphql/context.ex
- [x] T010 Create GraphQL controller in lib/plausible_web/controllers/api/graphql_controller.ex
- [x] T011 Add route for /api/graphql in lib/plausible_web/router.ex

## Phase 3: User Story 1 - Query Analytics Data

**Goal**: Enable developers to retrieve analytics data programmatically via GraphQL queries

**Independent Test**: Send GraphQL queries and verify data matches expected values from existing stats system

### Tests
- [x] T012 [US1] [P] Write ExUnit tests for aggregate query in test/plausible_web/graphql/analytics_aggregate_test.exs
- [x] T013 [US1] [P] Write ExUnit tests for breakdown query in test/plausible_web/graphql/analytics_breakdown_test.exs
- [x] T014 [US1] [P] Write ExUnit tests for timeseries query in test/plausible_web/graphql/analytics_timeseries_test.exs

### Implementation
- [x] T015 [US1] Implement aggregate query resolver in lib/plausible_web/graphql/resolvers/analytics.ex
- [x] T016 [US1] Implement breakdown query resolver in lib/plausible_web/graphql/resolvers/analytics.ex
- [x] T017 [US1] Implement timeseries query resolver in lib/plausible_web/graphql/resolvers/analytics.ex
- [x] T018 [US1] Connect resolvers to schema in lib/plausible_web/graphql/schema.ex
- [x] T019 [US1] Integrate with existing stats query modules (lib/plausible/stats/)

## Phase 4: User Story 2 - Filter Analytics Data

**Goal**: Enable data analysts to filter analytics by various dimensions

**Independent Test**: Apply filters to queries and verify results are correctly limited

### Tests
- [ ] T020 [US2] [P] Write tests for date range filtering in test/plausible_web/graphql/filter_date_range_test.exs
- [x] T021 [US2] [P] Write tests for geographic filtering in test/plausible_web/graphql/filter_geo_test.exs
- [x] T022 [US2] [P] Write tests for device filtering in test/plausible_web/graphql/filter_device_test.exs
- [x] T023 [US2] [P] Write tests for UTM filtering in test/plausible_web/graphql/filter_utm_test.exs

### Implementation
- [x] T024 [US2] Implement filter parsing in lib/plausible_web/graphql/resolvers/filter_parser.ex
- [x] T025 [US2] Connect filter input to existing stats filters module
- [x] T026 [US2] Add validation for filter inputs

## Phase 5: User Story 3 - Aggregate Metrics

**Goal**: Enable product managers to aggregate data for trends and summaries

**Independent Test**: Request aggregated metrics and verify calculations match expected values

### Tests
- [x] T027 [US3] [P] Write tests for total pageview aggregation in test/plausible_web/graphql/aggregate_test.exs
- [x] T028 [US3] [P] Write tests for average calculation in test/plausible_web/graphql/aggregate_avg_test.exs

### Implementation
- [x] T029 [US3] Implement count aggregation in resolvers
- [x] T030 [US3] Implement sum aggregation in resolvers
- [x] T031 [US3] Implement average calculation in resolvers

## Phase 6: User Story 4 - Custom Metrics

**Goal**: Enable users to query custom-defined metrics

**Independent Test**: Query custom metric and verify calculated values

### Tests
- [x] T032 [US4] [P] Write tests for custom metrics query in test/plausible_web/graphql/custom_metrics_test.exs

### Implementation
- [x] T033 [US4] Create custom metrics resolver in lib/plausible_web/graphql/resolvers/metrics.ex
- [x] T034 [US4] Add custom metrics to schema
- [x] T035 [US4] Connect to existing custom metrics definitions

## Phase 7: Polish & Cross-Cutting Concerns

- [x] T036 [P] Implement rate limiting middleware in lib/plausible_web/plugs/rate_limit_graphql.ex
- [x] T037 [P] Add comprehensive error handling for GraphQL
- [x] T038 Add input validation for date ranges (max 1 year)
- [x] T039 Add pagination support for breakdown queries
- [ ] T040 Run full test suite and fix any failures

## Parallel Execution Examples

### Setup Phase (T001-T003)
Can run sequentially only - dependency on mix.exs

### Foundational Phase (T004-T011)
- T004-T008: Can run in parallel (creating types)
- T009-T011: Must run after types are created

### User Story Phases
Each user story phase can have internal parallelization:
- Tests can run before implementation (TDD)
- Different filter types can be implemented in parallel (T024-T026)

## Task Summary

| Phase | Tasks | Description |
|-------|-------|-------------|
| Setup | T001-T003 | Add Absinthe dependency |
| Foundational | T004-T011 | Schema, types, controller |
| US1: Query | T012-T019 | Core GraphQL queries |
| US2: Filter | T020-T026 | Filtering capabilities |
| US3: Aggregate | T027-T031 | Aggregation functions |
| US4: Custom Metrics | T032-T035 | Custom metrics queries |
| Polish | T036-T040 | Rate limiting, validation |

**Total Tasks**: 40
**Parallelizable Tasks**: 20 (marked with [P])
**Test Tasks**: 9 (TDD approach per Constitution)
