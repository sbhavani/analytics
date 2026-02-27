# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Branch**: `011-advanced-filter-builder`
**Generated**: 2026-02-26

## Implementation Strategy

**MVP Scope**: User Stories 1-3 (P1) - Basic single conditions and AND/OR logic
**Incremental Delivery**: Complete US1-US3 first for MVP, then add nested groups (US4), save/load (US5), and edit (US6)

## Phase 1: Setup

Project initialization and dependency setup.

- [x] T001 Create database migration for VisitorSegment table in priv/repo/migrations/ with fields: id, name, site_id, user_id, filter_tree (jsonb), inserted_at, updated_at
- [x] T002 Add VisitorSegment schema in lib/plausible/segment.ex with Ecto schema and validation
- [x] T003 Configure Phoenix router scope for segments API in lib/plausible_web/router.ex - add routes for CRUD operations
- [x] T004 Create filter tree TypeScript types in assets/js/lib/types/filter-tree.ts for FilterTree, FilterGroupNode, FilterConditionNode

## Phase 2: Foundational

Core infrastructure needed by all user stories.

- [x] T005 Create filter tree validation module in lib/plausible/filter_tree_validator.ex to validate structure, nesting depth, and condition count
- [x] T006 Create segment query builder in lib/plausible/stats/segment_query_builder.ex to convert filter tree to ClickHouse query
- [x] T007 Build filter tree utility functions in assets/js/lib/filter-tree.ts with createEmptyTree, addCondition, removeCondition, updateCondition, addGroup, removeGroup
- [x] T008 Create API client service in assets/js/lib/api/segments.ts with saveSegment, listSegments, getSegment, updateSegment, deleteSegment, duplicateSegment, previewSegment methods
- [x] T009 Implement filter suggestions integration reusing existing /api/sites/:site_id/filter-suggestions endpoint

## Phase 3: User Story 1 - Create Simple Filter Condition (P1)

Users can create a basic segment with a single filter condition.

**Independent Test**: Apply one filter condition (e.g., "Country = US") and verify only matching visitors are displayed.

### Implementation Tasks

- [x] T010 [US1] Create FilterConditionEditor React component in assets/js/components/FilterConditionEditor.tsx with attribute dropdown, operator dropdown, value input, and remove button
- [x] T011 [US1] Build attribute selector in assets/js/components/AttributeSelector.tsx loading from available visit: and event: properties
- [x] T012 [US1] Implement operator selector in assets/js/components/OperatorSelector.tsx with available operators per attribute type
- [x] T013 [US1] Create value input with autocomplete in assets/js/components/ValueInput.tsx fetching suggestions from filter suggestions API
- [x] T014 [US1] Add preview panel component in assets/js/components/SegmentPreview.tsx showing visitor count and metrics
- [x] T015 [US1] Connect preview to POST /api/sites/:site_id/segments/preview endpoint

## Phase 4: User Story 2 - Combine Two Conditions with AND Logic (P1)

Users can combine multiple conditions with AND logic.

**Independent Test**: Create two conditions with AND and verify only visitors matching both criteria are included.

### Implementation Tasks

- [x] T016 [US2] Create FilterGroup React component in assets/js/components/FilterGroup.tsx with AND/OR toggle and children container
- [x] T017 [US2] Implement add condition button in FilterGroup that inserts new condition node
- [x] T018 [US2] Add visual AND/OR toggle with clear labeling between conditions
- [x] T019 [US2] Ensure filter tree properly serializes to backend format with group operator

## Phase 5: User Story 3 - Combine Conditions with OR Logic (P1)

Users can combine multiple conditions with OR logic.

**Independent Test**: Create two conditions with OR and verify visitors matching either condition are included.

### Implementation Tasks

- [x] T020 [US3] Implement OR logic toggle in FilterGroup - same component as US2, just different operator state
- [x] T021 [US3] Ensure OR group correctly deduplicates visitors matching multiple conditions in query builder

## Phase 6: User Story 4 - Create Nested Filter Groups (P2)

Users can create complex nested filter structures.

**Independent Test**: Create nested groups and verify logic correctly combines at each level.

### Implementation Tasks

- [x] T022 [US4] Add nested group creation button in FilterGroup that creates child group
- [x] T023 [US4] Implement nesting depth validation (max 5 levels) with user-friendly error message
- [x] T024 [US4] Create visual indentation for nested groups in FilterGroup component
- [x] T025 [US4] Add conditions-per-group limit validation (max 10) in filter tree validator

## Phase 7: User Story 5 - Save and Reuse Segments (P2)

Users can save and load segments for future use.

**Independent Test**: Save a segment, reload page, and verify segment loads with exact same configuration.

### Implementation Tasks

- [x] T026 [US5] Implement save segment modal in assets/js/components/SaveSegmentModal.tsx with name input (max 100 chars)
- [x] T027 [US5] Create segment list sidebar in assets/js/components/SegmentList.tsx showing saved segments for current site
- [x] T028 [US5] Implement load segment functionality - clicking segment loads filter tree from saved configuration
- [x] T029 [US5] Add segment list API integration - GET /api/sites/:site_id/segments
- [x] T030 [US5] Implement save segment API call - POST /api/sites/:site_id/segments
- [x] T031 [US5] Create "Save as new" option when editing existing segment

## Phase 8: User Story 6 - Edit Existing Segments (P3)

Users can modify and delete saved segments.

**Independent Test**: Load segment, modify condition, verify changes are applied.

### Implementation Tasks

- [x] T032 [US6] Implement update segment API - PATCH /api/sites/:site_id/segments/:segment_id
- [x] T033 [US6] Add delete segment API - DELETE /api/sites/:site_id/segments/:segment_id with confirmation dialog
- [x] T034 [US6] Implement duplicate segment API - POST /api/sites/:site_id/segments/:segment_id/duplicate
- [x] T035 [US6] Add segment modification tracking (dirty state) in FilterBuilder component
- [x] T036 [US6] Implement discard changes functionality restoring original segment state

## Phase 9: Polish & Cross-Cutting Concerns

Final improvements and edge case handling.

- [x] T037 Add empty state UI when no conditions exist in filter builder
- [x] T038 Implement zero results message with suggestions to relax filters
- [x] T039 Add loading states for all async operations (save, load, preview)
- [x] T040 Add error handling with user-friendly messages for API failures
- [x] T041 Implement keyboard shortcuts for common actions (Ctrl+S save, Escape cancel)
- [x] T042 Add accessibility attributes (ARIA labels) for screen readers
- [x] T043 Add ExUnit tests for FilterTreeValidator in test/plausible/filter_tree_validator_test.exs
- [x] T044 Add Jest tests for filter-tree utilities in test/js/filter-tree.test.ts
- [x] T045 Add integration tests for segment API in test/plausible_web/controllers/segment_controller_test.exs

## Dependency Graph

```
Phase 1 (Setup)
  └─ T001 → T002 → T003 → T004

Phase 2 (Foundational)
  ├─ T005 (depends on T002)
  ├─ T006 (depends on T005)
  ├─ T007 (depends on T004)
  ├─ T008 (depends on T003)
  └─ T009 (independent)

Phase 3 (US1 - Simple Filter)
  ├─ T010 (depends on T007, T008)
  ├─ T011 (depends on T007)
  ├─ T012 (depends on T007)
  ├─ T013 (depends on T009)
  ├─ T014 (depends on T008)
  └─ T015 (depends on T014, T006)

Phase 4 (US2 - AND Logic)
  ├─ T016 (depends on T010, T007)
  ├─ T017 (depends on T016)
  ├─ T018 (depends on T016)
  └─ T019 (depends on T016, T006)

Phase 5 (US3 - OR Logic)
  ├─ T020 (depends on T018)
  └─ T021 (depends on T019)

Phase 6 (US4 - Nested Groups)
  ├─ T022 (depends on T016)
  ├─ T023 (depends on T005)
  └─ T024 (depends on T022)

Phase 7 (US5 - Save/Reuse)
  ├─ T026 (depends on T015)
  ├─ T027 (depends on T008)
  ├─ T028 (depends on T027)
  ├─ T029 (depends on T003)
  ├─ T030 (depends on T003)
  └─ T031 (depends on T026)

Phase 8 (US6 - Edit)
  ├─ T032 (depends on T030)
  ├─ T033 (depends on T032)
  ├─ T034 (depends on T032)
  ├─ T035 (depends on T028)
  └─ T036 (depends on T035)

Phase 9 (Polish)
  ├─ T037 → T046 (independent improvements)
```

## Parallel Opportunities

The following tasks can be executed in parallel (different files, no dependencies):

- **T005, T006**: Both are backend validators - can work in parallel after T002
- **T010, T011, T012, T013**: All React components for condition editing - can be developed in parallel after T007
- **T026, T027**: Save modal and segment list - can be developed in parallel after T015/T008
- **T032, T033, T034**: API operations for edit/delete/duplicate - can be developed in parallel after T030

## Task Summary

| Metric | Count |
|--------|-------|
| Total Tasks | 46 |
| Setup Tasks | 4 |
| Foundational Tasks | 5 |
| US1 Tasks (Simple Filter) | 6 |
| US2 Tasks (AND Logic) | 4 |
| US3 Tasks (OR Logic) | 2 |
| US4 Tasks (Nested Groups) | 4 |
| US5 Tasks (Save/Reuse) | 6 |
| US6 Tasks (Edit) | 5 |
| Polish Tasks | 9 |

## Independent Test Criteria

| User Story | Test Criteria |
|------------|---------------|
| US1 | Single condition segment shows only matching visitors |
| US2 | AND combined segments show only visitors matching ALL conditions |
| US3 | OR combined segments show visitors matching ANY condition |
| US4 | Nested groups correctly evaluate complex logic at each level |
| US5 | Saved segments can be retrieved with identical configuration |
| US6 | Modified segments reflect changes, discarded changes restore original |
