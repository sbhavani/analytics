# Quickstart: Advanced Filter Builder

**Feature**: Advanced Filter Builder for visitor segments
**Date**: 2026-02-26

## Overview

This feature adds a visual filter builder UI component that allows users to create complex visitor segments using AND/OR logic and nested filter groups.

## Getting Started

### Prerequisites

- Elixir 1.18+ development environment
- Node.js 18+ for frontend
- PostgreSQL database
- ClickHouse instance (for analytics)
- Existing Plausible Analytics codebase

### Development Setup

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

3. **Access the application**: Open http://localhost:8000 (or configured port)

### Running Tests

```bash
# Backend tests
mix test

# Frontend tests
cd assets && npm test
```

## Key Components

### Backend

- **Segment Schema** (`lib/plausible/segments/segment.ex`): Existing schema extended with new filter structure
- **Filter Query Builder** (`lib/plausible/stats/sql/where_builder.ex`): Existing system for building filter queries

### Frontend

- **FilterBuilder Component** (`assets/js/dashboard/components/FilterBuilder/`): Main UI component
- **FilterCondition Component**: Individual condition row
- **FilterGroup Component**: Group container with AND/OR logic
- **SegmentList Component**: List of saved segments
- **useFilterBuilder Hook**: State management for filter building

## Filter Data Format

Filters are stored in the existing `segment_data` JSONB column:

```json
{
  "filters": [
    {
      "id": "group-1",
      "logic": "AND",
      "conditions": [
        {
          "id": "cond-1",
          "attribute": "visit:country",
          "operator": "equals",
          "value": "US"
        }
      ]
    }
  ]
}
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/sites/:site_id/segments` | GET | List saved segments |
| `/api/sites/:site_id/segments` | POST | Create new segment |
| `/api/sites/:site_id/segments/:id` | PUT | Update segment |
| `/api/sites/:site_id/segments/:id` | DELETE | Delete segment |
| `/api/stats/:site_id` | GET | Query stats with filters (existing) |

## Common Tasks

### Adding a New Filter Attribute

1. Add dimension to `priv/json-schemas/query-api-schema.json`
2. Add filter handler in `lib/plausible/stats/sql/where_builder.ex`
3. Add display configuration in frontend

### Testing a New Filter

1. Create unit test in `test/plausible/segments/`
2. Create integration test for API in `test/plausible_web/controllers/`
3. Add component test in `assets/js/dashboard/components/FilterBuilder/`

## Troubleshooting

### Filter Not Returning Expected Results

1. Check that filter format matches existing API schema
2. Verify dimension name is correct (e.g., `visit:country` not `country`)
3. Ensure operator is valid for the dimension type

### Real-time Count Not Updating

1. Check network tab for API requests
2. Verify debounce timeout is not too long
3. Ensure ClickHouse is responding to queries

## Next Steps

After implementation:
1. Run `/speckit.tasks` to generate task list
2. Run `/speckit.implement` to execute tasks
