# Research: Advanced Filter Builder

**Feature**: Advanced Filter Builder for Visitor Segments
**Date**: 2026-02-25
**Spec**: [spec.md](spec.md)

## Overview

This document captures research findings for implementing an Advanced Filter Builder UI component that enables users to combine multiple filter conditions with AND/OR logic for custom visitor segments.

## Existing Infrastructure

### Backend (Elixir/Phoenix)

**Segments Module** (`lib/plausible/segments/`):
- `Segment.ex` - Ecto schema for storing segments with filters
- `Segments.ex` - Context module with CRUD operations
- `Filters.ex` - Filter resolution logic for queries

**Key Findings**:
- Segment schema stores `segment_data` as JSON with `filters` and `labels` keys
- Filters are validated against the dashboard-compatible format
- Maximum 500 segments per site
- Support for personal and site-level segments
- Filters stored in legacy flat list format (not nested groups)

### Frontend (React/TypeScript)

**Segments Code** (`assets/js/dashboard/filtering/`):
- `segments.ts` - Type definitions and segment utilities
- `segments-context.tsx` - React context for segment management

**Key Findings**:
- Segment types: `personal` and `site`
- Segment data includes `filters` (array) and `labels` (map)
- Integration with dashboard state for filter management

## Technical Approach

### Decision: UI Component for Visual Filter Building

The existing system uses a flat filter list. The new feature adds:
1. **Visual filter builder component** - Interactive UI for creating nested filter groups
2. **AND/OR group support** - Ability to combine conditions with different logical operators
3. **Nested groups** - Support for groups within groups

### Architecture

```
Filter Builder Component
    │
    ├── FilterGroup (AND/OR container)
    │   ├── FilterCondition (property + operator + value)
    │   └── FilterGroup (nested)
    │
    └── FilterGroup
```

### Data Model

Filter structure to support the UI:
```typescript
interface FilterCondition {
  id: string           // unique identifier
  property: string     // e.g., "country", "device"
  operator: string     // e.g., "equals", "contains"
  value: string | string[]
}

interface FilterGroup {
  id: string           // unique identifier
  logic: 'AND' | 'OR'  // group operator
  conditions: FilterCondition[]
  groups: FilterGroup[]  // nested groups
}
```

### API Integration

The backend already supports segments with flat filters. Need to:
1. Add endpoint for filter preview/count (real-time validation)
2. Convert visual filter structure to backend-compatible format
3. Use existing segment CRUD endpoints

### Alternatives Considered

| Alternative | Rationale |
|-------------|-----------|
| Flat filter only | Rejected - doesn't meet requirement for AND/OR combination |
| Raw SQL builder | Rejected - security risk, complex to maintain |
| Third-party query builder | Rejected - adds dependency, doesn't fit UI requirements |

## Performance Considerations

- Filter preview queries must complete within 2 seconds (SC-004)
- Support at least 20 simultaneous conditions (SC-006)
- Use debouncing for real-time preview updates
- Consider caching for property/operator options

## Dependencies

- Existing Segment schema and CRUD operations
- Existing filter parsing in `Plausible.Stats.Filters`
- React with TypeScript for frontend
- TailwindCSS for styling (per project standards)

## Next Steps

1. Create React component for filter builder UI
2. Implement filter group rendering with AND/OR toggles
3. Add real-time preview using existing query infrastructure
4. Integrate with segment save/load workflow
