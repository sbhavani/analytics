# Research: Advanced Filter Builder

**Feature**: Advanced Filter Builder for custom visitor segments
**Date**: 2026-02-26

## Existing System Analysis

### Current Filter Implementation

The current Plausible Analytics system uses a flat filter model:

- **Filter Storage**: Filters stored as arrays of `[operation, dimension, clauses]` tuples
- **Filter Operations**: `is`, `is_not`, `contains`, `contains_not`, `has_not_done`
- **Filter Types**: page, source, location, screen, browser, os, utm, goal, props, hostname, segment

### Current Segment Implementation

- **Segment Schema**: Stored in PostgreSQL with fields: `name`, `type` (personal/site), `segment_data` (JSON map with `filters` and `labels`)
- **Segment Data Structure**:
  ```elixir
  %{
    "filters" => [[operation, dimension, clauses], ...],
    "labels" => %{...}
  }
  ```
- **API**: REST endpoints for CRUD operations on segments
- **Frontend**: Existing segment modals and segment context

## Decision: Filter Data Structure for Advanced Builder

### Chosen Approach: Nested Filter Groups

The feature will extend the existing flat filter array to support nested groups with AND/OR operators.

**New Filter Structure**:
```typescript
type FilterCondition = [operation: string, dimension: string, clauses: unknown[]]

type FilterGroup = {
  filter_type: 'and' | 'or'
  children: (FilterCondition | FilterGroup)[]
}
```

### Rationale

1. **Backward Compatibility**: The new structure can represent the old flat array as a single AND group with individual conditions
2. **Database Schema Unchanged**: Segment storage already uses JSON, so only the filter parsing logic needs updating
3. **Frontend Integration**: Existing filter components can be reused by wrapping them in a recursive group renderer

### Alternatives Considered

1. **Separate Tables for Groups**: Rejected - premature optimization, adds unnecessary schema complexity
2. **Filter Query String Encoding**: Rejected - would break existing URL sharing compatibility
3. **New Dedicated JSON Column**: Rejected - would require migration and dual-maintenance of old/new formats

## Implementation Approach

### Backend Changes (Elixir)

1. Update `ApiQueryParser.parse_filters/1` to handle nested filter structures
2. Update `QueryBuilder` to build ClickHouse queries from nested filters
3. Add validation for maximum filter depth (2 levels as per requirements)
4. Update Segment schema validation for new filter structure

### Frontend Changes (React/TypeScript)

1. Create new `FilterBuilder` component with recursive group rendering
2. Update `FilterModal` to support group operations
3. Extend `segments-context.tsx` to handle nested filter serialization
4. Add new UI components: `FilterGroup`, `FilterConnector`, `NestedGroupIndicator`

## Key Dependencies

- **Elixir**: Phoenix (controller/context), Ecto (schema), ClickHouse (analytics queries)
- **React**: Existing dashboard components, segment context, filter utilities
- **Testing**: ExUnit for backend, Jest for frontend

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| ClickHouse query performance with nested filters | Use explicit parentheses in SQL generation, add query plan validation |
| Breaking existing segment URLs | Maintain backward compatibility - old flat format still works |
| Maximum nesting depth validation | Add server-side validation, show UI warning when approaching limit |

## Conclusion

The advanced filter builder is a natural extension of the existing filter system. No major unknowns remain. Implementation can proceed with:
- Phase 1: Backend filter parsing and query building for nested structures
- Phase 2: Frontend filter builder UI components
- Phase 3: Integration testing and backward compatibility verification
