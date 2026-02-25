# Tasks: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Date**: 2026-02-25
**Spec**: [spec.md](spec.md)
**Plan**: [plan.md](plan.md)

## Implementation Strategy

This feature implements a visual filter builder UI for creating custom visitor segments. The MVP scope includes User Stories 1-3 (single conditions, AND/OR logic), providing immediate value for basic segmentation needs. User Stories 4-6 (nested groups, save/reuse, edit) build on this foundation.

**MVP Scope**: User Stories 1, 2, 3 - Basic filter building with single conditions and AND/OR logic
**Incremental Delivery**: Each user story phase is independently testable

## Phase 1: Setup

- [x] T001 Create FilterBuilder component directory in assets/js/dashboard/components/filter-builder/
- [x] T002 Add FilterBuilder module exports to assets/js/dashboard/index.ts

## Phase 2: Foundational

- [x] T003 Define TypeScript interfaces for FilterCondition and FilterGroup in assets/js/dashboard/components/filter-builder/types.ts
- [x] T004 Create filter utility functions (convertToFlatFilters, parseFlatFilters) in assets/js/dashboard/components/filter-builder/filter-utils.ts
- [x] T005 Add visitor properties configuration in assets/js/dashboard/components/filter-builder/properties.ts

## Phase 3: User Story 1 - Single-Condition Segment (P1)

**Goal**: Users can create a simple single-condition segment
**Independent Test**: Open filter builder, add one condition, verify segment returns only matching visitors

- [x] T006 [P] [US1] Create PropertySelect dropdown component in assets/js/dashboard/components/filter-builder/PropertySelect.tsx
- [x] T007 [P] [US1] Create OperatorSelect dropdown component in assets/js/dashboard/components/filter-builder/OperatorSelect.tsx
- [x] T008 [P] [US1] Create ValueInput component with type-aware input in assets/js/dashboard/components/filter-builder/ValueInput.tsx
- [x] T009 [US1] Create FilterCondition row component in assets/js/dashboard/components/filter-builder/FilterCondition.tsx
- [x] T010 [US1] Integrate FilterCondition with existing dashboard state in assets/js/dashboard/components/filter-builder/FilterBuilder.tsx

## Phase 4: User Story 2 - AND Logic (P1)

**Goal**: Users can combine multiple conditions with AND logic
**Independent Test**: Create AND-group with multiple conditions, verify only visitors meeting all criteria are included

- [x] T011 [P] [US2] Create FilterGroup container component in assets/js/dashboard/components/filter-builder/FilterGroup.tsx
- [x] T012 [US2] Implement AND logic toggle in FilterGroup component
- [x] T013 [US2] Add multiple condition support to FilterBuilder

## Phase 5: User Story 3 - OR Logic (P1)

**Goal**: Users can combine multiple conditions with OR logic
**Independent Test**: Create OR-group with multiple conditions, verify visitors matching any condition are included

- [x] T014 [US3] Implement OR logic toggle in FilterGroup component
- [x] T015 [US3] Add OR group to filter builder UI

## Phase 6: User Story 4 - Nested Filter Groups (P2)

**Goal**: Users can build nested groups with AND/OR at different levels
**Independent Test**: Create nested groups, verify correct visitors are included

- [x] T016 [P] [US4] Add nested FilterGroup rendering support
- [x] T017 [US4] Implement add nested group functionality
- [x] T018 [US4] Add group collapse/expand UI for readability
- [x] T019 [US4] Enforce maximum nesting depth of 5 levels

## Phase 7: User Story 5 - Save and Reuse Segments (P2)

**Goal**: Users can save filter configurations as named segments
**Independent Test**: Save segment with name, verify it appears in saved segments list

- [X] T020 [P] [US5] Create SaveSegmentModal component in assets/js/dashboard/components/filter-builder/SaveSegmentModal.tsx
- [x] T021 [US5] Implement segment name validation (1-255 bytes, sanitize special characters)
- [x] T022 [US5] Integrate with existing segment CRUD API endpoints
- [x] T023 [US5] Add saved segments list dropdown to FilterBuilder
- [x] T024 [US5] Implement load segment into filter builder

## Phase 8: User Story 6 - Edit and Modify Filters (P2)

**Goal**: Users can modify existing filters without starting from scratch
**Independent Test**: Load existing filter, modify condition, verify updated segment

- [x] T025 [P] [US6] Implement condition removal functionality
- [x] T026 [US6] Add operator/value change handling
- [x] T027 [US6] Implement undo functionality for filter changes
- [x] T028 [US6] Add clear all conditions button

## Phase 9: Polish & Cross-Cutting Concerns

- [x] T029 Add real-time filter preview with debouncing (300-500ms)
- [x] T030 Add loading states and error handling for API calls
- [x] T031 Add responsive styling for mobile/tablet views
- [x] T032 Add validation error messages for invalid inputs
- [x] T033 Add empty state handling (no conditions)
- [x] T034 Add no-matches message when segment matches zero visitors

## Dependencies

```
Phase 1 (Setup)
    │
    ├── Phase 2 (Foundational)
    │       │
    │       ├── Phase 3 (US1 - Single Condition)
    │       │
    │       ├── Phase 4 (US2 - AND Logic) ──► Depends on: Phase 3
    │       │
    │       └── Phase 5 (US3 - OR Logic) ──► Depends on: Phase 3
    │
    ├── Phase 6 (US4 - Nested Groups) ──► Depends on: Phase 4, Phase 5
    │
    ├── Phase 7 (US5 - Save/Reuse) ──► Depends on: Phase 3
    │
    ├── Phase 8 (US6 - Edit/Modify) ──► Depends on: Phase 3
    │
    └── Phase 9 (Polish)
```

## Parallel Opportunities

| Tasks | Reason |
|-------|--------|
| T006, T007, T008 | Different components, no dependencies between them |
| T011, T014 | Different logic types, can be implemented in parallel after T009 |
| T016, T020 | Independent UI components |
| T025, T026 | Both edit operations, different handlers |

## Task Summary

| Phase | User Story | Task Count |
|-------|------------|------------|
| Phase 1 | Setup | 2 |
| Phase 2 | Foundational | 3 |
| Phase 3 | US1 - Single Condition | 5 |
| Phase 4 | US2 - AND Logic | 3 |
| Phase 5 | US3 - OR Logic | 2 |
| Phase 6 | US4 - Nested Groups | 4 |
| Phase 7 | US5 - Save/Reuse | 5 |
| Phase 8 | US6 - Edit/Modify | 4 |
| Phase 9 | Polish | 6 |
| **Total** | | **34** |

## Suggested MVP Scope

The MVP (Minimum Viable Product) should include:
- Phase 1 (Setup): T001-T002
- Phase 2 (Foundational): T003-T005
- Phase 3 (US1): T006-T010
- Phase 4 (US2): T011-T013
- Phase 5 (US3): T014-T015

This provides basic single-condition and AND/OR logic - the most common use cases per the spec's success criteria (SC-001: create simple segment in under 30 seconds).
