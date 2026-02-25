# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Feature Branch**: `001-advanced-filter-builder`
**Generated**: 2026-02-25

## Implementation Strategy

The implementation follows an MVP-first approach where each user story builds incrementally:
- **MVP Scope**: User Story 1 (Single-condition filters) - This alone provides value
- **Incremental Delivery**: Each user story phase is independently testable
- **Parallel Opportunities**: US2 (AND) and US3 (OR) can be implemented in parallel since they share the multi-condition UI

## Phase 1: Setup

Foundation tasks for development environment.

- [x] T001 Review existing filter infrastructure in assets/js/dashboard/util/filters.js
- [x] T002 Review existing segment types in assets/js/dashboard/filtering/segments.ts
- [x] T003 Review existing filter modal implementation in assets/js/dashboard/stats/modals/filter-modal.js
- [x] T004 Review backend segment module in lib/plausible/segments.ex

## Phase 2: Foundational

Core utilities and types needed for all user stories.

- [x] T005 Create TypeScript types for FilterCondition in assets/js/dashboard/types/filter-expression.ts
- [x] T006 Create TypeScript types for FilterGroup in assets/js/dashboard/types/filter-expression.ts
- [x] T007 Create TypeScript types for FilterExpression in assets/js/dashboard/types/filter-expression.ts
- [x] T008 [P] Implement filter expression serialization utility in assets/js/dashboard/util/filter-expression.ts
- [x] T009 [P] Implement filter expression parsing utility in assets/js/dashboard/util/filter-expression.ts
- [x] T010 Implement validation for filter expression (max 20 conditions, 5 nesting levels) in assets/js/dashboard/util/filter-expression.ts

## Phase 3: User Story 1 - Single Condition Filter (P1)

**Story Goal**: Users can create a simple single-condition filter
**Independent Test**: Create filter "Country equals United States" and verify only US visitors appear
**Test Criteria**: Single condition creates valid filter, filter applies to query

- [x] T011 [US1] Create FilterBuilder container component in assets/js/dashboard/components/filter-builder/filter-builder.tsx
- [x] T012 [US1] Add dimension selector dropdown in assets/js/dashboard/components/filter-builder/dimension-selector.tsx
- [x] T013 [US1] Add operator selector based on dimension type in assets/js/dashboard/components/filter-builder/operator-selector.tsx
- [x] T014 [US1] Add value input (text, select, or date based on dimension) in assets/js/dashboard/components/filter-builder/value-input.tsx
- [x] T015 [US1] Render single condition display summary in assets/js/dashboard/components/filter-builder/condition-summary.tsx
- [x] T016 [US1] Connect filter builder to dashboard state context in assets/js/dashboard/components/filter-builder/filter-builder.tsx
- [x] T017 [US1] Test single condition filter creation flow in assets/js/dashboard/components/filter-builder/filter-builder.test.tsx

## Phase 4: User Stories 2 & 3 - AND/OR Logic (P1)

**Story Goal**: Users can combine multiple conditions with AND or OR logic
**Independent Test**: Create two conditions with AND, verify only visitors matching ALL are included; same for OR
**Test Criteria**: Multiple conditions with AND/OR connector display correctly, query filters correctly

- [x] T018 [P] [US2] Add "Add Condition" button to filter builder in assets/js/dashboard/components/filter-builder/filter-builder.tsx
- [x] T019 [P] [US2] Add AND/OR operator selector between conditions in assets/js/dashboard/components/filter-builder/condition-connector.tsx
- [x] T020 [P] [US3] Implement OR logic the same way (operator selection between conditions)
- [x] T021 [US2] Update filter expression serialization to handle multiple conditions in assets/js/dashboard/util/filter-expression.ts
- [x] T022 [US2] Test AND logic - multiple conditions all must match in assets/js/dashboard/components/filter-builder/filter-builder.test.tsx
- [x] T023 [US3] Test OR logic - any condition matching includes visitor in assets/js/dashboard/components/filter-builder/filter-builder.test.tsx

## Phase 5: User Story 4 - Nested Filter Groups (P2)

**Story Goal**: Users can create complex nested filters like "(Country=US AND Device=Mobile) OR (Country=UK)"
**Independent Test**: Create nested groups and verify correct visitors are included
**Test Criteria**: Groups display with visual container, nested evaluation follows correct order

- [x] T024 [US4] Add "Create Group" action to group multiple conditions in assets/js/dashboard/components/filter-builder/group-actions.tsx
- [x] T025 [US4] Add visual group container component in assets/js/dashboard/components/filter-builder/filter-group.tsx
- [x] T026 [US4] Add group operator toggle (AND/OR) in assets/js/dashboard/components/filter-builder/filter-group.tsx
- [x] T027 [US4] Implement nested filter expression serialization in assets/js/dashboard/util/filter-expression.ts
- [x] T028 [US4] Add nesting depth validation (max 5 levels) in assets/js/dashboard/util/filter-expression.ts
- [x] T029 [US4] Test nested group creation and evaluation in assets/js/dashboard/components/filter-builder/filter-builder.test.tsx

## Phase 6: User Story 5 - Save and Reuse Segments (P2)

**Story Goal**: Users can save filter configurations as named segments for reuse
**Independent Test**: Save a segment, return later, apply saved segment
**Test Criteria**: Segment saves to database, loads correctly, applies to query

- [x] T030 [US5] Add "Save as Segment" button to filter builder in assets/js/dashboard/components/filter-builder/filter-builder.tsx
- [x] T031 [US5] Create segment name input modal/dialog in assets/js/dashboard/components/filter-builder/save-segment-dialog.tsx
- [x] T032 [US5] Implement segment save API call in assets/js/dashboard/api/segments.ts
- [x] T033 [US5] Update backend segment schema if needed in lib/plausible/segments.ex
- [x] T034 [US5] Add segment list dropdown to load saved segments in assets/js/dashboard/components/filter-builder/segment-list.tsx
- [x] T035 [US5] Add segment load functionality - deserialize saved expression in assets/js/dashboard/components/filter-builder/filter-builder.tsx
- [x] T036 [US5] Test save and load segment flow in assets/js/dashboard/components/filter-builder/filter-builder.test.tsx

## Phase 7: User Story 6 - Edit and Delete Conditions (P2)

**Story Goal**: Users can modify or remove existing filter conditions
**Independent Test**: Modify existing condition value, verify results update; delete condition, verify removed
**Test Criteria**: Edit makes fields editable, delete removes from expression

- [x] T037 [US6] Add edit mode toggle to condition in assets/js/dashboard/components/filter-builder/condition-row.tsx
- [x] T038 [US6] Add delete button to each condition in assets/js/dashboard/components/filter-builder/condition-row.tsx
- [x] T039 [US6] Add delete button to groups in assets/js/dashboard/components/filter-builder/filter-group.tsx
- [x] T040 [US6] Update filter expression state on edit/delete in assets/js/dashboard/components/filter-builder/filter-builder.tsx
- [x] T041 [US6] Test edit condition value in assets/js/dashboard/components/filter-builder/filter-builder.test.tsx
- [x] T042 [US6] Test delete condition in assets/js/dashboard/components/filter-builder/filter-builder.test.tsx

## Phase 8: Polish & Cross-Cutting

- [x] T043 Add preview count display (debounced API query) in assets/js/dashboard/components/filter-builder/preview-count.tsx
- [x] T044 Add zero-results feedback message in assets/js/dashboard/components/filter-builder/filter-builder.tsx
- [x] T045 Add loading states during preview query in assets/js/dashboard/components/filter-builder/preview-count.tsx
- [x] T046 Verify accessibility (keyboard navigation, screen reader) for filter builder components
- [x] T047 Integrate filter builder into existing dashboard filter modal as advanced option
- [x] T048 End-to-end test complete user flow in assets/js/dashboard/components/filter-builder/filter-builder.e2e.test.tsx

## Dependencies

```
Phase 1 (Setup)
  └─> Phase 2 (Foundational)

Phase 2
  ├─> Phase 3 (US1)
  ├─> Phase 4 (US2 & US3)
  ├─> Phase 5 (US4)
  ├─> Phase 6 (US5)
  └─> Phase 7 (US6)

Phase 3, 4, 5, 6, 7 -> Phase 8 (Polish)
```

## Parallel Execution

| User Story | Can Run In Parallel With | Reason |
|------------|--------------------------|--------|
| US2 (AND) | US3 (OR) | Share same multi-condition UI |
| US4 (Nested Groups) | US5 (Save Segments) | Different feature areas |
| US5 (Save Segments) | US6 (Edit/Delete) | Different feature areas |

## Task Count Summary

| Phase | Task Count |
|-------|------------|
| Phase 1: Setup | 4 |
| Phase 2: Foundational | 6 |
| Phase 3: US1 (Single Condition) | 7 |
| Phase 4: US2+US3 (AND/OR) | 6 |
| Phase 5: US4 (Nested Groups) | 6 |
| Phase 6: US5 (Save Segments) | 7 |
| Phase 7: US6 (Edit/Delete) | 6 |
| Phase 8: Polish | 6 |
| **Total** | **48** |

## Suggested MVP Scope

For fastest time-to-value, implement only:
- Phase 1 (Setup)
- Phase 2 (Foundational)
- Phase 3 (US1 - Single Condition)

This delivers basic filter functionality and can be extended incrementally.
