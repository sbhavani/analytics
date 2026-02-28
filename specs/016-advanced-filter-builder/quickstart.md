# Developer Quickstart: Advanced Filter Builder

This guide helps developers start working on the Advanced Filter Builder feature.

## Prerequisites

- Node.js 18+
- Elixir 1.15+
- PostgreSQL (local development)
- ClickHouse (local development)

## Quick Setup

```bash
# Install frontend dependencies
npm install

# Run development server
npm run dev

# In another terminal, run backend
mix phx.server
```

## Project Structure

```
assets/js/dashboard/
├── components/filter-builder/
│   ├── FilterBuilder.tsx       # Main container component
│   ├── FilterGroup.tsx         # Group rendering (AND/OR)
│   ├── ConditionRow.tsx        # Single condition editor
│   ├── ConditionEditor.tsx     # Dropdown for attribute/operator/value
│   ├── NestedGroup.tsx        # Nested group wrapper
│   ├── SegmentPreview.tsx     # Visitor count preview
│   ├── SaveSegmentModal.tsx   # Save segment dialog
│   ├── FilterSummary.tsx      # Visual filter representation
│   └── index.ts               # Exports
├── contexts/
│   └── filter-builder-context.tsx
└── util/
    └── filter-tree.ts          # Tree manipulation utilities
```

## Key Concepts

### Filter Tree Structure

The filter builder uses a tree structure to represent complex AND/OR logic:

```
FilterTree
└── rootGroup (AND/OR connector)
    ├── Condition 1
    ├── Condition 2
    └── NestedGroup (OR connector)
        ├── Condition 3
        └── Condition 4
```

### Integration Points

1. **Dashboard State**: Filter builder reads/writes to existing `DashboardState.filters`
2. **Segment Context**: Uses existing `SegmentsContext` for saved segments
3. **API**: Extends existing `/api/{site}/segments` endpoints

## Common Tasks

### Adding a New Attribute

1. Add to attribute list in `FilterGroup.tsx`
2. Add validation in `ConditionEditor.tsx`
3. Update `filter-tree.ts` if attribute requires special handling

### Adding a New Operator

1. Add to `FilterOperator` type in `data-model.md`
2. Add UI option in `ConditionEditor.tsx`
3. Add to filter conversion utilities

### Modifying Preview Query

1. Update `SegmentPreview.tsx`
2. Adjust query in backend (if needed): `lib/plausible_web/controllers/api/stats_controller.ex`

## Testing

```bash
# Run frontend tests
npm test -- --testPathPattern=filter-builder

# Run specific test file
npm test -- FilterBuilder.test.tsx

# Run with coverage
npm test -- --coverage --testPathPattern=filter-builder
```

## Useful Commands

```bash
# Type checking
npx tsc --noEmit

# Linting
npm run lint

# Build for production
npm run build
```

## Related Documentation

- [Data Model](./data-model.md) - TypeScript types and API structures
- [API Contracts](./contracts/) - Endpoint specifications
- [Spec](./spec.md) - Feature requirements
