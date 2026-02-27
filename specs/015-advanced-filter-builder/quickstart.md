# Quickstart: Advanced Filter Builder

## Prerequisites

- Node.js 18+
- Elixir 1.14+ with Phoenix
- PostgreSQL and ClickHouse running

## Development Setup

### Frontend

1. **Install dependencies**:
   ```bash
   cd assets
   npm install
   ```

2. **Run the development server**:
   ```bash
   npm run dev
   ```

3. **Run tests**:
   ```bash
   npm test -- --testPathPattern="new-filter-builder"
   ```

### Backend

1. **Install dependencies**:
   ```bash
   mix deps.get
   ```

2. **Run the backend**:
   ```bash
   mix phx.server
   ```

3. **Run tests**:
   ```bash
   mix test test/plausible/segments/
   ```

## Key Files

### Frontend

| File | Purpose |
|------|---------|
| `assets/js/dashboard/filtering/new-filter-builder/FilterBuilder.tsx` | Main filter builder component |
| `assets/js/dashboard/filtering/new-filter-builder/filterTreeUtils.ts` | Filter tree manipulation utilities |
| `assets/js/dashboard/filtering/new-filter-builder/FilterGroup.tsx` | AND/OR group rendering |
| `assets/js/dashboard/filtering/new-filter-builder/FilterCondition.tsx` | Individual filter condition |

### Backend

| File | Purpose |
|------|---------|
| `lib/plausible/segments/filter_tree.ex` | Filter tree parsing and serialization |
| `lib/plausible/segments/segment.ex` | Segment schema and validation |

## Common Tasks

### Adding a New Filter Dimension

1. Add dimension to `FILTER_MODAL_TO_FILTER_GROUP` in `assets/js/dashboard/util/filters.js`
2. Add operators in `FILTER_OPERATIONS`
3. Update backend in `lib/plausible/stats/filters/api_query_parser.ex`

### Testing Filter Serialization

```bash
# Run utility tests
npm test -- --testPathPattern="filterTreeUtils"

# Test integration
mix test test/plausible/segments/filter_tree_test.exs
```

### Creating a Sample Filter

```typescript
import { createFilterTree, addCondition, addGroup } from './filterTreeUtils';

// Create a simple filter
const tree = createFilterTree();
const withCondition = addCondition(tree, {
  dimension: 'country',
  operator: 'is',
  values: ['US']
});

// Add an OR group
const withGroup = addGroup(withCondition, 'or');
```

## Debugging

### Frontend
- Use React DevTools to inspect FilterBuilder component state
- Check browser console for validation errors

### Backend
- Check `lib/plausible/segments/filter_tree.ex` for parsing logs
- Use `mix phx.routes` to see available endpoints

## Integration Points

- **Dashboard State**: Filter tree stored in `dashboardState.filterTree`
- **Segments**: Saved to `segment_data.filterTree` in database
- **API**: Serialized to flat filter array for query building
