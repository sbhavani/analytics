# Implementation Plan: Advanced Filter Builder

**Branch**: `015-advanced-filter-builder` | **Date**: 2026-02-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/015-advanced-filter-builder/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

The Advanced Filter Builder provides a UI component that allows users to combine multiple filter conditions using AND/OR logic for custom visitor segments. This extends the existing flat filter system to support hierarchical filter trees.

**Key Technical Approach**:
- Implement a filter tree data structure that supports nested AND/OR groups
- Create React components for the visual filter builder UI
- Extend the existing segment backend to handle the new filter tree format
- Maintain backward compatibility with the existing flat filter format

## Technical Context

**Language/Version**: TypeScript (React), Elixir 1.14+ (Phoenix)
**Primary Dependencies**: @headlessui/react, @heroicons/react, @tanstack/react-query, React 18
**Storage**: PostgreSQL (segments table), ClickHouse (analytics queries)
**Testing**: Jest, React Testing Library, ExUnit
**Target Platform**: Web dashboard (modern browsers)
**Project Type**: Web analytics platform
**Performance Goals**: Filter updates in <500ms, handle 10+ filter conditions without degradation
**Constraints**: Must integrate with existing dashboard state, backward compatible with existing segments
**Scale/Scope**: 6 user stories, ~15 functional requirements

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| TDD Required | PASS | Tests will be written before implementation per Constitution II |
| Privacy Impact | PASS | Filter builder is UI-only; no new personal data collection |
| Performance Considered | PASS | Performance requirements specified in Success Criteria |
| Simplicity First | PASS | Start with flat filters, add nesting as needed |

**Constitution II (TDD)**: All new components require tests written before implementation.
- Frontend: Jest tests for all React components in `assets/js/dashboard/filtering/new-filter-builder/`
- Backend: ExUnit tests for segment parsing in `lib/plausible/segments/`

## Project Structure

### Documentation (this feature)

```text
specs/015-advanced-filter-builder/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Frontend - Filter Builder UI
assets/js/dashboard/filtering/new-filter-builder/
├── FilterBuilder.tsx           # Main container component
├── FilterGroup.tsx            # Group component (AND/OR)
├── FilterCondition.tsx        # Individual filter condition
├── FilterDimensionSelect.tsx  # Dimension picker
├── FilterOperatorSelect.tsx   # Operator picker
├── FilterValueInput.tsx       # Value input field
├── filterTreeUtils.ts         # Filter tree manipulation utilities
├── filterTreeUtils.test.ts    # Tests for utilities
├── FilterBuilder.test.tsx     # Component tests
└── index.ts                   # Export entry point

# Backend - Segment Enhancement
lib/plausible/segments/
├── filter_tree.ex              # Filter tree parsing (new)
└── segments.ex                 # Existing - add filter tree support

# Integration Points
assets/js/dashboard/
├── dashboard-state.ts          # Add filterTree to state
├── util/filters.js             # Add serialization for filter tree
└── filtering/segments.ts       # Enhance segment loading/saving
```

**Structure Decision**: New filter builder follows existing dashboard patterns. React components go in `assets/js/dashboard/filtering/new-filter-builder/`. Backend filter tree support extends existing segment modules in `lib/plausible/segments/`.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

---

## Phase 0: Research & Clarifications

### Research Findings

**Current System Analysis**:

1. **Filter Format**: Current filters use flat array format `[FilterOperator, FilterKey, FilterClause[]]`
   - Example: `['is', 'country', ['US']]`
   - All filters are implicitly ANDed together

2. **Segment Backend**: Already supports nested filter resolution with `:and` and `:or` operators
   - Located in `lib/plausible/segments/filters.ex`
   - Uses `Filters.traverse()` for filter processing

3. **Existing UI**: Filter modal (`filter-modal.js`) handles individual filter groups by category
   - Groups filters by modal type (page, goal, custom event, etc.)
   - Does not support AND/OR grouping at UI level

4. **Segment Storage**: Segments store `segment_data: { filters: [...], labels: {...} }`
   - Currently expects flat filter format
   - Max filter depth validation exists (restricted for dashboard)

### Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| Filter Tree Data Structure | Supports nested AND/OR groups naturally | Flat format with implicit grouping |
| Component-Based UI | Follows React patterns in codebase | Single complex component |
| Backend Filter Tree Parser | Reuses existing segment infrastructure | New dedicated module |
| Backward Compatible | Existing segments continue working | Breaking change (rejected) |

---

## Phase 1: Design & Contracts

### Design Decisions

**Data Structure - Filter Tree**:

```
FilterTree = FilterGroup
FilterGroup = {
  operator: 'and' | 'or',
  children: (FilterGroup | FilterCondition)[]
}
FilterCondition = {
  dimension: string,
  operator: string,
  value: string[]
}
```

**UI Component Architecture**:
- `FilterBuilder`: Main container managing state
- `FilterGroup`: Renders group with operator toggle
- `FilterCondition`: Individual filter row
- `filterTreeUtils`: Pure functions for tree manipulation

**API Serialization**:
- Frontend to Backend: Convert filter tree to flat array with explicit `:and`/`:or` operators
- Backend to Frontend: Parse flat array back to tree structure

### Contracts

**Frontend → Dashboard State**:
- `filterTree`: Hierarchical filter structure
- Serialization to legacy `filters` array for API compatibility

**Segment Storage**:
- `segment_data.filters`: Extended to support nested filter arrays
- Validation: Reuse existing segment validation with filter tree support

---

## Phase 2: Implementation Tasks

*To be generated by /speckit.tasks command*
