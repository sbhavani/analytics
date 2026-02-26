# Research: Advanced Filter Builder

**Date**: 2026-02-26
**Feature**: Advanced Filter Builder (007-advanced-filter-builder)

## Research Questions

### 1. How are filters currently represented in the frontend?

**Finding**: Filters are represented as arrays of tuples `[operation, dimension, clauses]`. The `filters.js` utility provides operations like `is`, `isNot`, `contains`. Filter dimensions map to modal types (page, source, location, browser, os, utm, goal, props, hostname, segment).

**Decision**: Extend existing filter representation to include logical grouping metadata

### 2. What is the existing segments API structure?

**Finding**: Segments are stored in PostgreSQL via `Plausible.Segments` context. The frontend uses `SavedSegment` type with fields: `id`, `name`, `type` (site/personal), `filters` (JSON), `description`.

**Decision**: Reuse existing segments table; filter builder creates/modifies segment filter configurations

### 3. How do LiveView components handle complex UI state?

**Finding**: Plausible uses Phoenix LiveView for interactive components. Existing pattern in `segment-modals.tsx` shows React modal with routing.

**Decision**: Build filter builder as React component integrated with existing segment modals

### 4. What are the available filter fields/operators?

**Finding**:
- Fields: page, entry_page, exit_page, source, channel, referrer, country, region, city, screen, browser, browser_version, os, os_version, utm_medium, utm_source, utm_campaign, utm_term, utm_content, goal, props, hostname
- Operators: is, is_not, contains, contains_not, has_not_done

**Decision**: Use existing fields and operators; add grouping UI

## Architecture Decisions

### Decision: Filter Tree Data Structure

**Chosen Approach**: Nested tree structure for conditions

```typescript
interface FilterCondition {
  id: string
  dimension: string
  operator: string
  value: string | string[]
}

interface FilterGroup {
  id: string
  operator: 'and' | 'or'
  children: (FilterCondition | FilterGroup)[]
}
```

**Rationale**: Matches nested group requirement; extensible for future operators

### Decision: UI Component Architecture

**Chosen Approach**: React component with Context API for state management

**Rationale**: Consistent with existing React patterns in codebase; leverages @tanstack/react-query for API

### Decision: Backend Persistence

**Chosen Approach**: Store filter groups as JSON in existing `segments.filters` column

**Rationale**: Existing schema accommodates JSON; no migration needed for basic functionality

## Alternatives Considered

1. **Separate filter templates table**: Rejected - segments table sufficient for templates
2. **Query builder library**: Rejected - YAGNI, existing infrastructure adequate
3. **Backend-driven filter rendering**: Rejected - UI should be responsive; existing pattern is frontend-heavy

## Integration Points

- `assets/js/dashboard/filtering/segments.ts` - Segment types and context
- `assets/js/dashboard/segments/segment-modals.tsx` - Existing modal patterns
- `assets/js/dashboard/util/filters.js` - Filter operations and utilities
- `lib/plausible/segments/segment.ex` - Backend segment logic
- `lib/plausible_web/controllers/api/segments_controller.ex` - API endpoints
