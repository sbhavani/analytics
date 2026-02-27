# Quickstart: Advanced Filter Builder

**Feature**: Advanced Filter Builder
**Date**: 2026-02-26

## Developer Setup Guide

This guide helps developers get started with implementing the Advanced Filter Builder feature.

## Prerequisites

- Elixir 1.16+ with Phoenix framework
- Node.js 20+ with pnpm
- PostgreSQL 14+
- ClickHouse (for analytics queries)
- Docker (for local development)

## Local Development Setup

### 1. Start the Development Environment

```bash
# Start PostgreSQL and ClickHouse via Docker
docker-compose up -d postgres clickhouse

# Install Elixir dependencies
mix deps.get

# Setup database
mix ecto.setup

# Install frontend dependencies
cd assets && pnpm install
```

### 2. Start the Application

```bash
# Start Phoenix server (backend)
mix phx.server

# In another terminal, start Vite dev server (frontend)
cd assets && pnpm run dev
```

The application will be available at `http://localhost:8000`.

### 3. Running Tests

```bash
# Run all tests
mix test

# Run backend tests only
mix test

# Run frontend tests
cd assets && pnpm test

# Run specific test file
mix test test/plausible/segments/segment_test.exs
```

## Project Structure

### Key Files to Modify

#### Backend (Elixir)

| File | Purpose |
|------|---------|
| `lib/plausible/stats/filters/filter_parser.ex` | Parse nested filter structures |
| `lib/plausible/stats/query_builder.ex` | Build ClickHouse queries from nested filters |
| `lib/plausible/segments/segment.ex` | Validate nested filter data |
| `lib/plausible_web/controllers/api/internal/segments_controller.ex` | Handle segment CRUD API |

#### Frontend (React/TypeScript)

| File | Purpose |
|------|---------|
| `assets/js/dashboard/filtering/filter-builder/` | New filter builder components |
| `assets/js/dashboard/filtering/filter-context.tsx` | State management for filter builder |
| `assets/js/dashboard/util/filter-serializer.ts` | Convert between flat and nested formats |
| `assets/js/dashboard/stats/modals/filter-modal.tsx` | Update to support group operations |

### New Component Structure

```
assets/js/dashboard/filtering/filter-builder/
├── index.tsx              # Main filter builder container
├── filter-group.tsx       # Renders a group with AND/OR connector
├── filter-condition.tsx   # Renders individual condition
├── filter-connector.tsx  # AND/OR toggle component
├── nested-group.tsx      # Visual indicator for nested groups
└── filter-builder.css    # Styles (if needed beyond Tailwind)
```

## Working with Filter Data

### Creating a Simple Filter

```typescript
import { FilterBuilder } from './filter-builder'

// Simple AND filter (backward compatible)
const simpleFilter = {
  filter_type: 'and',
  children: [
    ['is', 'country', ['US']],
    ['is', 'device', ['mobile']]
  ]
}

// Complex nested filter
const nestedFilter = {
  filter_type: 'or',
  children: [
    {
      filter_type: 'and',
      children: [
        ['is', 'country', ['US']],
        ['is', 'device', ['mobile']]
      ]
    },
    {
      filter_type: 'and',
      children: [
        ['is', 'country', ['UK']],
        ['is', 'device', ['desktop']]
      ]
    }
  ]
}
```

### Converting Between Formats

```typescript
import { flatToNested, nestedToFlat } from '../util/filter-serializer'

// Old flat format to new nested format
const flatFilters = [['is', 'country', ['US']], ['is', 'device', ['mobile']]]
const nested = flatToNested(flatFilters)

// New nested format back to flat (for backward compatibility)
const backToFlat = nestedToFlat(nested)
```

## Common Development Tasks

### Adding a New Filter Dimension

1. Update `FILTER_MODAL_TO_FILTER_GROUP` in `assets/js/dashboard/util/filters.js`
2. Add dimension metadata in the backend `Plausible.Stats.Filters` module
3. Update `availableDimensions` in the filter builder context

### Modifying Filter Operations

1. Update `FILTER_OPERATIONS` constant in `assets/js/dashboard/util/filters.js`
2. Update backend filter validation in `lib/plausible/stats/filters/`
3. Add operation to dimension support mapping

### Testing Filter Queries

```bash
# Test a filter query via curl
curl "http://localhost:8000/api/stats/example.com?period=7d&filters=%5B%5B%22is%22%2C%22country%22%2C%5B%22US%22%5D%5D%5D"
```

## Debugging Tips

### Backend

- Add `IO.inspect` to filter parsing functions
- Check ClickHouse query logs in development
- Use `mix phx.routes` to see available routes

### Frontend

- React DevTools for component state inspection
- Network tab for API request/response debugging
- `console.log` filter state in development

## Related Documentation

- [Feature Specification](./spec.md)
- [Data Model](./data-model.md)
- [API Contracts](./contracts/api-contracts.md)
- [Research Notes](./research.md)
