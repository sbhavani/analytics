# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Date**: 2026-02-26
**Branch**: `013-advanced-filter-builder`

## Overview

This document contains actionable, dependency-ordered tasks for implementing the Advanced Filter Builder feature. Tasks are organized by user story to enable independent implementation and testing.

## Dependencies Graph

```
Phase 1: Setup
    │
    ▼
Phase 2: Foundational ───────┐
    │                        │
    ▼                        │
Phase 3: US1 ───────────────┼──► All Stories Need These First
    │                        │
Phase 4: US2 ───────────────┤
    │                        │
Phase 5: US3 ───────────────┤
    │                        │
Phase 6: US4 ───────────────┤
    │                        │
Phase 7: US5 ───────────────┤
    │                        │
Phase 8: US6 ───────────────┤
    │                        │
    ▼                        │
Phase 9: Polish ◄────────────┘
```

## Implementation Strategy

### MVP Scope (Phase 3-5)
- User Stories 1-3 (P1) form the MVP
- Delivers basic single-condition and multi-condition (AND/OR) filtering
- Can be tested independently and provides immediate value

### Incremental Delivery
- Each user story phase is independently testable
- Stories can be implemented in parallel after foundational phase is complete
- Polish phase addresses cross-cutting concerns

---

## Phase 1: Setup

**Goal**: Prepare development environment and understand existing codebase

- [x] T001 Review existing filter implementation in `assets/js/dashboard/util/filters.js`
- [x] T002 Review existing segment types in `assets/js/dashboard/filtering/segments.ts`
- [x] T003 Review existing segment backend in `lib/plausible/segments/segment.ex`
- [x] T004 Review filter parser in `lib/plausible/stats/filters/` directory

---

## Phase 2: Foundational

**Goal**: Core infrastructure changes required by all user stories

**Independent Test**: Can run existing tests to verify backward compatibility maintained

### Backend Foundation

- [x] T005 Create filter parser module for nested filter structures in `lib/plausible/stats/filters/filter_parser.ex`
- [x] T006 Add validation for nested filter depth (max 2 levels) in filter parser
- [x] T007 Add validation for max children per group (10) in filter parser
- [x] T008 Update query builder to handle FilterGroup in `lib/plausible/stats/query_builder.ex`
- [x] T009 Update segment validation to accept nested filter format in `lib/plausible/segments/segment.ex`
- [x] T010 Add flat-to-nested filter conversion utility for backward compatibility

### Frontend Foundation

- [x] T011 Add TypeScript types for FilterGroup and FilterComposite in `assets/js/types/query-api.d.ts`
- [x] T012 Create filter serialization utility in `assets/js/dashboard/util/filter-serializer.ts`
- [x] T013 Update segments-context to handle nested filter format in `assets/js/dashboard/filtering/segments-context.tsx`
- [x] T014 Update segments.ts to parse nested filter format in `assets/js/dashboard/filtering/segments.ts`

### Tests

- [ ] T015 Write ExUnit tests for nested filter parser in `test/plausible/stats/filters/filter_parser_test.exs`
- [ ] T016 Write Jest tests for filter serializer in `assets/js/dashboard/util/filter-serializer.test.ts`

---

## Phase 3: User Story 1 - Single-Condition Filter

**Priority**: P1
**Goal**: Users can create a filter with a single condition

**Independent Test**: Create a filter with one condition (country equals "US"), verify it applies correctly and only matching visitors are displayed

### Backend

- [ ] T017 [US1] Add single-condition filter API endpoint support in segment controller

### Frontend

- [x] T018 [P] [US1] Create FilterCondition component in `assets/js/dashboard/filtering/filter-builder/filter-condition.tsx`
- [x] T019 [US1] Create main FilterBuilder container in `assets/js/dashboard/filtering/filter-builder/index.tsx`
- [ ] T020 [US1] Integrate FilterBuilder with existing filter modal in `assets/js/dashboard/stats/modals/filter-modal.tsx`

### Tests

- [ ] T021 [US1] Write integration test for single-condition filter in Elixir
- [ ] T022 [US1] Write component test for FilterCondition in Jest

---

## Phase 4: User Story 2 - AND Logic

**Priority**: P1
**Goal**: Users can combine multiple conditions with AND logic

**Independent Test**: Create two conditions (country=US AND device=mobile), verify only visitors matching BOTH conditions appear

### Backend

- [ ] T023 [US2] Ensure AND logic generates correct ClickHouse query with explicit parentheses

### Frontend

- [x] T024 [P] [US2] Create FilterConnector component for AND/OR toggle in `assets/js/dashboard/filtering/filter-builder/filter-connector.tsx`
- [x] T025 [US2] Create FilterGroup component in `assets/js/dashboard/filtering/filter-builder/filter-group.tsx`
- [x] T026 [US2] Add condition addition UI to FilterBuilder
- [x] T027 [US2] Add connector selection UI between conditions

### Tests

- [ ] T028 [US2] Write integration test for AND filter query in Elixir

---

## Phase 5: User Story 3 - OR Logic

**Priority**: P1
**Goal**: Users can combine multiple conditions with OR logic

**Independent Test**: Create two conditions (country=US OR country=UK), verify visitors matching ANY condition appear

### Backend

- [ ] T029 [US3] Ensure OR logic generates correct ClickHouse query with proper precedence

### Frontend

- [ ] T030 [US3] Enable OR connector selection in FilterConnector component

### Tests

- [ ] T031 [US3] Write integration test for OR filter query in Elixir

---

## Phase 6: User Story 4 - Nested Filter Groups

**Priority**: P2
**Goal**: Users can create complex nested filters like "(Country=US AND Device=Mobile) OR (Country=UK)"

**Independent Test**: Create nested groups and verify correct boolean logic is applied

### Backend

- [ ] T032 [US4] Add nested group query generation for ClickHouse in query builder
- [ ] T033 [US4] Validate max nesting depth (2 levels) on backend

### Frontend

- [x] T034 [P] [US4] Create NestedGroupIndicator component in `assets/js/dashboard/filtering/filter-builder/nested-group.tsx`
- [x] T035 [US4] Add UI for creating nested groups within existing groups
- [x] T036 [US4] Add visual hierarchy indication for nested groups
- [x] T037 [US4] Add nesting depth validation warning in UI

### Tests

- [ ] T038 [US4] Write integration test for nested filter query in Elixir
- [ ] T039 [US4] Write component test for nested group UI in Jest

---

## Phase 7: User Story 5 - Save and Reuse Segments

**Priority**: P2
**Goal**: Users can save filter configurations as named segments and load them later

**Independent Test**: Create a filter, save with name "US Mobile", retrieve and verify it populates correctly

### Backend

- [ ] T040 [US5] Accept nested filter format in segment create/update API
- [ ] T041 [US5] Return nested filter format in segment list API

### Frontend

- [ ] T042 [US5] Add "Save Segment" button to FilterBuilder
- [ ] T043 [US5] Create segment save modal/dialog
- [ ] T044 [US5] Update saved segments list to load nested filters correctly
- [ ] T045 [US5] Add prompt for update vs save-as-new when modifying saved segment

### Tests

- [ ] T046 [US5] Write API test for segment CRUD with nested filters
- [ ] T047 [US5] Write integration test for save/load workflow

---

## Phase 8: User Story 6 - Edit and Delete Filters

**Priority**: P3
**Goal**: Users can modify or remove individual conditions without recreating the entire filter

**Independent Test**: Add 3 conditions, delete middle one, verify remaining 2 persist with correct connector logic

### Frontend

- [ ] T048 [US6] Add edit capability to FilterCondition component
- [ ] T049 [US6] Add delete button to each condition
- [ ] T050 [US6] Handle last condition deletion (return to empty state)
- [ ] T051 [US6] Add unsaved changes prompt when navigating away

### Tests

- [ ] T052 [US6] Write component test for condition edit/delete in Jest

---

## Phase 9: Polish & Cross-Cutting Concerns

**Goal**: Final improvements and edge case handling

### Edge Cases

- [ ] T053 Handle empty filter submission (show validation error)
- [ ] T054 Handle invalid filter combinations gracefully
- [ ] T055 Add loading states for segment save/load operations

### Performance

- [ ] T056 Optimize filter rendering for 10+ conditions per group

### Accessibility

- [ ] T057 Add keyboard navigation support to FilterBuilder
- [ ] T058 Add ARIA labels to filter components

### Documentation

- [ ] T059 Update user-facing documentation for new filter capabilities

---

## Summary

| Metric | Value |
|--------|-------|
| **Total Tasks** | 59 |
| **Setup Phase** | 4 |
| **Foundational Phase** | 16 |
| **User Story 1 (P1)** | 6 |
| **User Story 2 (P1)** | 6 |
| **User Story 3 (P1)** | 3 |
| **User Story 4 (P2)** | 6 |
| **User Story 5 (P2)** | 8 |
| **User Story 6 (P3)** | 5 |
| **Polish Phase** | 7 |

### Parallel Opportunities

- **T018, T024, T034**: Frontend component creation - can be parallelized across developers
- **T017, T023, T029**: Backend API/logic updates - sequential (logic builds)
- **T040, T041**: Backend segment API - can parallelize read/write
- **T042-T045**: Frontend save/load UI - sequential (depends on API)

### Suggested MVP Scope

Implement **Phases 1-5** (Tasks T001-T031):
- Single-condition filters
- Multi-condition AND/OR logic
- ~25 tasks total

This delivers the core filtering capability while remaining testable and valuable.
