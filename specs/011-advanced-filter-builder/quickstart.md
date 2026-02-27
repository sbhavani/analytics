# Quickstart: Advanced Filter Builder

## Getting Started

This guide helps developers start working with the Advanced Filter Builder feature.

## Prerequisites

- Elixir 1.15+ with Phoenix 1.7+
- Node.js 18+ with npm
- PostgreSQL and ClickHouse running locally
- Existing Plausible Analytics setup

## Development Setup

1. **Start the backend**:
   ```bash
   mix deps.get
   mix ecto.setup
   mix phx.server
   ```

2. **Start the frontend**:
   ```bash
   cd assets
   npm install
   npm run dev
   ```

3. **Access the application**: http://localhost:8000

## Key Files

### Backend

| File | Purpose |
|------|---------|
| `lib/plausible_web/controllers/segment_controller.ex` | API endpoints for segment CRUD |
| `lib/plausible/segments.ex` | Business logic for segment operations |
| `lib/plausible/stats/filter_query_builder.ex` | Converts filter tree to ClickHouse query |
| `lib/plausible_web/views/segment_view.ex` | JSON serialization |

### Frontend

| File | Purpose |
|------|---------|
| `assets/js/components/FilterBuilder.tsx` | Main filter builder component |
| `assets/js/components/FilterGroup.tsx` | Group editor with AND/OR toggle |
| `assets/js/components/ConditionEditor.tsx` | Single condition editor |
| `assets/js/hooks/useFilterBuilder.ts` | State management hook |
| `assets/js/lib/filterTree.ts` | Filter tree utilities |

## Testing

### Backend Tests

```bash
# Run all segment tests
mix test test/plausible/segments_test.exs

# Run filter parsing tests
mix test test/plausible/stats/filter_query_builder_test.exs
```

### Frontend Tests

```bash
# Run React component tests
npm test -- --testPathPattern=FilterBuilder

# Run with coverage
npm test -- --coverage
```

## Creating Your First Segment

1. Navigate to the Analytics dashboard
2. Click "Segments" in the sidebar
3. Click "New Segment"
4. Add conditions using the UI:
   - Select attribute (e.g., "Country")
   - Choose operator (e.g., "equals")
   - Enter value (e.g., "US")
5. Click "Preview" to see matching visitors
6. Click "Save" and enter a name

## Common Issues

| Issue | Solution |
|-------|----------|
| Preview returns no results | Check that attribute names match visit:/event: prefixes |
| Save fails with validation error | Ensure segment name is 1-100 characters |
| Nested groups not working | Verify nesting depth is ≤ 5 levels |
| Slow preview for large datasets | Enable sampling for segments >100k visitors |

## API Examples

### Save a segment via curl

```bash
curl -X POST http://localhost:8000/api/sites/demo/segments \
  -H "Content-Type: application/json" \
  -d '{
    "name": "US Mobile Users",
    "filter_tree": {
      "version": 1,
      "root": {
        "id": "root-1",
        "operator": "and",
        "children": [
          {"id": "c1", "type": "condition", "attribute": "visit:country", "operator": "is", "value": "US", "negated": false},
          {"id": "c2", "type": "condition", "attribute": "visit:device", "operator": "is", "value": "Mobile", "negated": false}
        ]
      }
    }
  }'
```

### Get preview results

```bash
curl -X POST http://localhost:8000/api/sites/demo/segments/preview \
  -H "Content-Type: application/json" \
  -d '{
    "filter_tree": {
      "version": 1,
      "root": {
        "id": "root-1",
        "operator": "and",
        "children": [
          {"id": "c1", "type": "condition", "attribute": "visit:country", "operator": "is", "value": "US", "negated": false}
        ]
      }
    },
    "metrics": ["visitors", "pageviews"],
    "date_range": {"period": "7d"}
  }'
```
