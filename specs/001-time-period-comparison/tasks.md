# Tasks: Time Period Comparison

**Feature**: Time Period Comparison
**Branch**: `001-time-period-comparison`
**Spec**: [spec.md](./spec.md)
**Plan**: [plan.md](./plan.md)

## Implementation Strategy

**MVP Scope**: User Story 1 - Core period comparison functionality
- Enable users to compare metrics between two date ranges
- Display percentage change with visual indicators
- Backend API endpoints for comparison data

**Incremental Delivery**:
1. First: Backend percentage calculation + comparison endpoint (US1 core)
2. Second: Predefined period pairs (US2)
3. Third: Custom date ranges + preferences persistence (US3)
4. Fourth: Frontend components
5. Fifth: Polish and cross-cutting concerns

## Dependencies

```
Phase 2 (Foundational)
    │
    ├── T001: Period comparison context module
    └── T002: ClickHouse query helpers
              │
              ├── Phase 3 (US1 - Compare Metrics)
              │   ├── T003: Unit tests for calculation
              │   ├── T004: ComparisonResult logic
              │   ├── T005: Analytics query service
              │   └── T006: GET compare endpoint
              │
              ├── Phase 4 (US2 - Predefined Pairs)
              │   ├── T007: Predefined period pair calculations
              │   └── T008: GET period-pairs endpoint
              │
              └── Phase 5 (US3 - Custom Ranges)
                  ├── T009: Custom range validation
                  └── T010: POST preferences endpoint
```

## Phases

### Phase 1: Setup

No setup tasks required - feature extends existing analytics dashboard.

---

### Phase 2: Foundational

**Goal**: Create core infrastructure for period comparison

**Independent Test Criteria**: Core calculation functions work correctly in isolation

- [X] T001 Create period comparison context module in lib/plausible/analytics/period_comparison.ex for date range calculations
- [X] T002 [P] Create ClickHouse query helpers in lib/plausible/clickhouse/period_queries.ex for period-based aggregations

---

### Phase 3: User Story 1 - Compare Metrics Between Two Time Periods (Priority: P1)

**Goal**: Enable users to compare metrics between two date ranges with percentage change display

**Independent Test Criteria**: User can select two periods and see metrics with percentage change

**Implementation**:
- [X] T003 [US1] Write unit tests for percentage change calculations in test/plausible/analytics/period_comparison_test.exs (TDD - tests first)
- [X] T004 [US1] Implement ComparisonResult calculation logic with state transitions in lib/plausible/analytics/period_comparison.ex
- [X] T005 [US1] Create analytics comparison query service in lib/plausible/analytics/comparison_query.ex for ClickHouse queries
- [X] T006 [US1] Implement GET /api/v1/sites/:site_id/analytics/compare endpoint in lib/plausible_web/controllers/api/external_stats_controller.ex

---

### Phase 4: User Story 2 - Select Predefined Time Period Pairs (Priority: P2)

**Goal**: Provide predefined period pair options for quick comparison

**Independent Test Criteria**: All predefined pairs display correctly and calculate correct date ranges

**Implementation**:
- [X] T007 [US2] Implement predefined period pair calculations in lib/plausible/analytics/predefined_periods.ex
- [X] T008 [US2] Implement GET /api/v1/sites/:site_id/analytics/period-pairs endpoint in lib/plausible_web/controllers/api/external_stats_controller.ex

---

### Phase 5: User Story 3 - Define Custom Date Ranges (Priority: P3)

**Goal**: Allow users to define custom date ranges for comparison

**Independent Test Criteria**: User can select custom dates for both periods and comparison persists

**Implementation**:
- [X] T009 [US3] Implement custom date range validation in lib/plausible/analytics/period_comparison.ex (start <= end, max 2 years, no future dates)
- [X] T010 [US3] Implement POST /api/v1/sites/:site_id/analytics/preferences/comparison endpoint in lib/plausible_web/controllers/api/external_stats_controller.ex

---

### Phase 6: Frontend Integration

**Goal**: Add UI components for period comparison selection and display

**Independent Test Criteria**: Components render correctly and interact with API

**Implementation**:
- [X] T011 [P] Create PeriodSelector React component in assets/js/components/PeriodSelector.tsx
- [X] T012 [P] Create ComparisonTable React component in assets/js/components/ComparisonTable.tsx
- [X] T013 [P] Create MetricCard React component in assets/js/dashboard/components/MetricCard.tsx
- [X] T014 [P] Integrate period comparison into existing dashboard view in assets/js/dashboard/index.tsx

---

### Phase 7: Polish & Cross-Cutting Concerns

**Goal**: Ensure feature quality and cross-cutting requirements

**Implementation**:
- [X] T015 Add structured logging for period comparison operations in lib/plausible/analytics/period_comparison.ex
- [ ] T016 Perform integration testing with real ClickHouse queries
- [ ] T017 Verify acceptance criteria from spec.md

---

## Parallel Execution Examples

### Example 1: US1 and US2 can be parallelized
```
Worker 1: T003 (unit tests) → T004 (calculation logic) → T005 (query service)
Worker 2: T007 (predefined periods)
```
Both can work independently once Phase 2 is complete.

### Example 2: Frontend components can be parallelized
```
Worker 1: T011 (PeriodSelector)
Worker 2: T012 (ComparisonTable)
Worker 3: T013 (MetricCard)
```
All three frontend components can be built in parallel once backend APIs (T006, T008) are defined.

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 17 |
| **Phase 2 (Foundational)** | 2 |
| **Phase 3 (US1 - Compare Metrics)** | 4 |
| **Phase 4 (US2 - Predefined Pairs)** | 2 |
| **Phase 5 (US3 - Custom Ranges)** | 2 |
| **Phase 6 (Frontend)** | 4 |
| **Phase 7 (Polish)** | 3 |
| **Parallelizable Tasks** | 5 ([P] marked) |
| **MVP Tasks** | 7 (T001-T007) |

**Suggested MVP**: Complete Phase 2 + Phase 3 (T001-T006) for initial release of core comparison functionality.
