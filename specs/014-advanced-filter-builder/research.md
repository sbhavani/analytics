# Research: Advanced Filter Builder

## Decision 1: Filter Grammar for Nested Groups

**Selected Approach**: Extend existing filter syntax to support nested groups as container structures

### Current Filter Syntax
Filters are Elixir lists: `[operator, dimension, values]`
- Example: `[:is, "visit:country", ["US"]]`

### AND/OR Logic (Already Supported)
```elixir
[:and, [[:is, "visit:country", ["US"]], [:is, "visit:browser", ["Chrome"]]]]
[:or, [[:is, "visit:country", ["US"]], [:is, "visit:country", ["GB"]]]]
```

### Nested Groups Extension
For nested condition groups (e.g., "(Country=US AND Device=Mobile) OR Country=UK"), wrap groups with a container structure:

```elixir
[:or, [
  [:and, [
    [:is, "visit:country", ["US"]],
    [:is, "visit:device", ["Mobile"]]
  ]],
  [:is, "visit:country", ["GB"]]
]]
```

### Validation Considerations
- Maximum nesting depth: 3 levels (per spec assumptions)
- Maximum 20 conditions per segment
- Existing QueryBuilder validation handles:
  - Top-level only dimensions (event:goal, event:hostname)
  - Behavioral filter nesting restrictions
  - Custom property depth limits

**Rationale**: Reuses existing parser infrastructure without major changes. The filter syntax already supports AND/OR with nested lists - we just need to add UI for creating these structures.

**Alternatives Considered**:
1. Flatten nested groups to list of filters with explicit group IDs - rejected because it complicates query building
2. JSON-based filter structure - rejected because existing codebase uses Elixir lists

---

## Decision 2: UI Component Architecture

**Selected Approach**: New FilterBuilder component using React functional components with local state management

### Component Structure
```
FilterBuilder/
├── FilterBuilder.tsx      # Main modal/container
├── ConditionRow.tsx      # Single condition (field, operator, value)
├── ConditionGroup.tsx    # Group of conditions with AND/OR connector
├── FilterPreview.tsx     # Live visitor count preview
└── index.ts              # Exports
```

### State Management
- Local useState for filter tree structure
- URL sync for shareable filter configurations
- useCallback for memoized event handlers

**Rationale**: Simple feature scope doesn't require full Context. Local state keeps component self-contained. Reuses existing Modal pattern from filter-modal.js.

**Alternatives Considered**:
1. React Context for filter state - rejected for simplicity (only one component needs access)
2. URL-driven state - useful but not MVP scope

---

## Decision 3: Integration with Filter Suggestions

**Selected Approach**: Reuse existing `/api/stats/filter-suggestions` endpoint

### Available Dimensions
From research:
- `event:name`, `event:page`, `event:goal`, `event:hostname`
- `event:props:<property_name>`
- `visit:source`, `visit:channel`, `visit:referrer`, `visit:utm_*`
- `visit:device`, `visit:browser`, `visit:os`
- `visit:country`, `visit:region`, `visit:city`
- `visit:entry_page`, `visit:exit_page`

### Operators by Dimension Type
- **String dimensions**: is, is_not, contains, matches, matches_wildcard
- **Numeric dimensions**: is, is_not, greater_than, less_than
- **Boolean-like**: is, is_not (e.g., has_done)

**Rationale**: Already implemented, tested, and provides autocomplete values. No new API needed.

**Alternatives Considered**:
1. Create separate suggestions endpoint - rejected (duplication)
2. Hardcode dimension list - rejected (loses dynamic goals/props)

---

## Summary

| Area | Decision | Rationale |
|------|----------|-----------|
| Filter Grammar | Extend existing list syntax | Minimal parser changes needed |
| Nested Groups | Container wrappers with AND/OR | Matches existing query structure |
| UI Architecture | React functional components | Modern pattern, fits codebase |
| State | Local useState | Simplicity for feature scope |
| Autocomplete | Reuse existing API | No duplication needed |

---

## Key Files for Implementation

### Backend
- `lib/plausible/stats/api_query_parser.ex` - Filter parsing
- `lib/plausible/stats/query_builder.ex` - Query building and validation
- `lib/plausible/segments/segment.ex` - Segment schema

### Frontend
- `assets/js/dashboard/stats/modals/modal.js` - Modal pattern
- `assets/js/dashboard/components/combobox.js` - Autocomplete
- `assets/js/dashboard/components/popover.tsx` - Popover styling
- `assets/js/dashboard/filtering/segments-context.tsx` - Segment state
