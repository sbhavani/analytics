# Quickstart: Advanced Filter Builder

**Feature**: Advanced Filter Builder for Visitor Segments
**Date**: 2026-02-25
**Spec**: [spec.md](spec.md)

## Getting Started

This guide provides a quick overview for implementing the Advanced Filter Builder UI component.

## Prerequisites

- Elixir 1.15+ with Phoenix 1.7+
- Node.js with React 18
- PostgreSQL (for segment storage)
- ClickHouse (for analytics data)

## Implementation Overview

### 1. Backend (Elixir)

The backend already has segment infrastructure. Key modules:

- `Plausible.Segments.Segment` - Schema for segment storage
- `Plausible.Segments` - CRUD operations

**New additions needed**:
- Filter preview endpoint for real-time validation

### 2. Frontend (React/TypeScript)

New component structure:

```
assets/js/dashboard/components/
└── filter-builder/
    ├── FilterBuilder.tsx      # Main component
    ├── FilterGroup.tsx       # AND/OR group container
    ├── FilterCondition.tsx   # Single condition row
    ├── PropertySelect.tsx    # Property dropdown
    ├── OperatorSelect.tsx   # Operator dropdown
    ├── ValueInput.tsx       # Value input field
    └── index.ts             # Exports
```

### 3. Key Functions

**Filter conversion** (frontend):
- `convertToFlatFilters(groups: FilterGroup[]): Filter[]` - Convert visual groups to backend format
- `parseFlatFilters(filters: Filter[]): FilterGroup[]` - Convert backend format to visual groups

**Validation** (backend):
- `validate_filter_data(site, filters)` - Validate filter structure
- `get_filter_preview(site, filters)` - Get matching visitor count

## Testing

### Unit Tests (Elixir)
```bash
mix test test/plausible/segments_test.exs
```

### Integration Tests (JavaScript)
```bash
cd assets && npm test
```

## Common Patterns

### Adding a Condition
1. User clicks "Add Condition"
2. New FilterCondition added to current group
3. Filter preview updates (debounced)
4. Validation runs on each change

### Creating AND/OR Groups
1. User clicks "Add Group" or "Add Condition" within a group
2. Group type (AND/OR) can be toggled
3. Nested groups supported up to 5 levels

### Saving a Segment
1. User clicks "Save Segment"
2. Visual filter converted to flat format
3. Validation ensures at least one condition
4. POST to segments API endpoint

## Debugging

- Check browser console for React component errors
- Check Phoenix logs for API errors
- Use `Plausible.Segments` functions directly in IEx for backend debugging

## Performance Tips

- Debounce filter preview requests (300-500ms)
- Cache available properties list
- Lazy-load segment list
- Limit nested group depth to 5
