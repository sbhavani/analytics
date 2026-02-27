# Tasks: Advanced Filter Builder for Visitor Segments

**Feature**: Advanced Filter Builder for Visitor Segments
**Branch**: `007-filter-builder`
**Generated**: 2026-02-27

## Summary

This feature implements a UI component for building custom visitor segments using AND/OR filter conditions with nested groupings. Tasks are organized by user story priority.

## Phase 1: Setup

- [X] T001 Create project structure for filter builder feature in `lib/plausible/segments/` and `assets/js/components/FilterBuilder/`
- [X] T002 Add database migration for `filter_templates` table in `priv/repo/migrations/`
- [X] T003 Create Ecto schema `Plausible.Segments.FilterTemplate` in `lib/plausible/segments/filter_template.ex`
- [X] T004 Add visitor fields configuration module in `lib/plausible/segments/fields.ex`

## Phase 2: Foundational

- [X] T005 Create filter tree types and validation in `lib/plausible/segments/filter_types.ex`
- [X] T006 Implement filter tree parser in `lib/plausible/segments/filter_parser.ex`
- [X] T007 Extend WhereBuilder to support new visitor fields in `lib/plausible/stats/sql/where_builder.ex`
- [X] T008 [P] Create API controller for segments in `lib/plausible_web/controllers/api/segment_controller.ex`
- [X] T009 [P] Add segment preview endpoint in `lib/plausible_web/controllers/api/segment_controller.ex`

## Phase 3: US1 - Simple Single-Condition Filter (P1)

**Goal**: Users can create a basic filter with a single condition

**Independent Test**: Create filter with "country equals US" and verify only US visitors are matched

- [X] T010 [US1] Create React FilterBuilder container component in `assets/js/components/FilterBuilder/FilterBuilder.tsx`
- [X] T011 [US1] [P] Create FieldSelect dropdown component in `assets/js/components/FilterBuilder/FieldSelect.tsx`
- [X] T012 [US1] [P] Create OperatorSelect dropdown component in `assets/js/components/FilterBuilder/OperatorSelect.tsx`
- [X] T013 [US1] Create ValueInput component for filter values in `assets/js/components/FilterBuilder/ValueInput.tsx`
- [X] T014 [US1] Create ConditionRow component for single condition in `assets/js/components/FilterBuilder/ConditionRow.tsx`
- [X] T015 [US1] Implement filter state management hook in `assets/js/lib/filterBuilder/useFilterState.ts`
- [X] T016 [US1] Add filter validation logic in `assets/js/lib/filterBuilder/filterValidator.ts`
- [X] T017 [US1] Test simple filter creation end-to-end

## Phase 4: US2 - AND Logic (P1)

**Goal**: Users can combine multiple conditions with AND logic

**Independent Test**: Create "Country = US AND Device = Mobile" filter and verify only matching visitors

- [X] T018 [US2] Update FilterBuilder to support multiple conditions in `assets/js/components/FilterBuilder/FilterBuilder.tsx`
- [X] T019 [US2] Add "Add Condition" button and AND connector UI in `assets/js/components/FilterBuilder/FilterBuilder.tsx`
- [X] T020 [US2] Implement backend AND filter evaluation in `lib/plausible/segments/filter_evaluator.ex`
- [X] T021 [US2] Test AND filter evaluation with multiple conditions

## Phase 5: US3 - OR Logic (P1)

**Goal**: Users can combine multiple conditions with OR logic

**Independent Test**: Create "Country = US OR Country = UK" filter and verify US or UK visitors

- [X] T022 [US3] Add OR connector toggle in UI in `assets/js/components/FilterBuilder/FilterBuilder.tsx`
- [X] T023 [US3] Implement backend OR filter evaluation in `lib/plausible/segments/filter_evaluator.ex`
- [X] T024 [US3] Test OR filter evaluation with multiple conditions

## Phase 6: US4 - Nested Groupings (P2)

**Goal**: Users can create complex filters with nested AND/OR groups

**Independent Test**: Create "(Country = US AND Device = Mobile) OR Country = UK" and verify logic is correct

- [X] T025 [US4] Create FilterGroup component for nested groups in `assets/js/components/FilterBuilder/FilterGroup.tsx`
- [X] T026 [US4] Add group nesting UI with drag-and-drop in `assets/js/components/FilterBuilder/FilterGroup.tsx`
- [X] T027 [US4] Implement nested filter tree serialization in `assets/js/lib/filterBuilder/filterSerializer.ts`
- [X] T028 [US4] Add nested filter evaluation in `lib/plausible/segments/filter_evaluator.ex`
- [X] T029 [US4] Test nested filter evaluation with 3+ levels

## Phase 7: US5 - Filter Templates (P2)

**Goal**: Users can save and reuse filter configurations

**Independent Test**: Save filter as template, reload, verify all conditions restored

- [X] T030 [US5] Create template list component in `assets/js/components/FilterBuilder/TemplateList.tsx`
- [X] T031 [US5] [P] Add "Save as Template" button and modal in `assets/js/components/FilterBuilder/SaveTemplateModal.tsx`
- [X] T032 [US5] Implement template CRUD API handlers in `lib/plausible/segments/filter_template_repo.ex`
- [X] T033 [US5] Add template loading functionality in `assets/js/lib/filterBuilder/templateLoader.ts`
- [X] T034 [US5] Test template save/load cycle

## Phase 8: US6 - Real-Time Preview (P3)

**Goal**: Users see live visitor count while building filter

**Independent Test**: Modify filter value and see count update within 2 seconds

- [X] T035 [US6] Create PreviewPanel component in `assets/js/components/FilterBuilder/PreviewPanel.tsx`
- [X] T036 [US6] Implement debounced preview API calls in `assets/js/lib/filterBuilder/usePreview.ts`
- [X] T037 [US6] Add loading and empty state handling in `assets/js/components/FilterBuilder/PreviewPanel.tsx`
- [X] T038 [US6] Test real-time preview updates within 2 seconds

## Phase 9: Polish & Cross-Cutting

- [X] T039 Add filter deletion UI (delete individual conditions)
- [X] T040 Add condition reordering with drag-and-drop
- [X] T041 Implement filter editing for saved filters
- [X] T042 Add edge case handling for empty filters
- [X] T043 Handle special characters in filter values
- [X] T044 Test long condition lists (20+ conditions)
- [X] T045 Verify nested group max depth (5 levels)

## Dependencies

```
Phase 1 (Setup)
  └── Phase 2 (Foundational)
        └── Phase 3 (US1: Simple Filter)
              ├── Phase 4 (US2: AND Logic)
              └── Phase 5 (US3: OR Logic)
        └── Phase 6 (US4: Nested Groups) [depends on US1]
        └── Phase 7 (US5: Templates) [depends on US1]
        └── Phase 8 (US6: Preview) [depends on US1]
              └── Phase 9 (Polish)
```

## Parallel Execution Opportunities

| Tasks | Reason |
|-------|--------|
| T008, T009 | Both in same controller file, can be done together |
| T011, T012, T013 | Independent UI components |
| T030, T031 | Template UI components can be built in parallel |
| T035, T036, T037 | Preview feature components |

## MVP Scope

**Recommended MVP**: User Stories 1, 2, 3 (Phases 3-5)

This delivers:
- Single condition filters
- Multiple conditions with AND/OR
- Filter evaluation against ClickHouse

This is sufficient for initial release. Additional user stories can be delivered incrementally.

## Implementation Strategy

1. **MVP First** (US1-US3): Simple filter builder with AND/OR
2. **Templates** (US5): Add saving/loading after basic filters work
3. **Nesting** (US4): Add nested groups as users request them
4. **Preview** (US6): Add real-time preview once filter logic is stable
