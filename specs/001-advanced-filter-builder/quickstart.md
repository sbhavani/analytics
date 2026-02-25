# Quickstart: Advanced Filter Builder

## Prerequisites

- Elixir ~> 1.18 environment
- Node.js with npm
- PostgreSQL database
- ClickHouse instance (for analytics queries)
- Docker (for local development)

## Development Setup

### 1. Start Development Environment

```bash
# Start PostgreSQL and ClickHouse
docker-compose up -d postgres clickhouse

# Install dependencies
mix deps.get
cd assets && npm install

# Create and migrate database
mix ecto.setup

# Start Phoenix server
mix phx.server
```

### 2. Access the Application

Open http://localhost:8000 in your browser. Create a test site to access the dashboard.

## Key Files and Locations

### Frontend

| File | Purpose |
|------|---------|
| `assets/js/dashboard/components/filter-builder.js` | **NEW** Advanced filter builder UI component |
| `assets/js/dashboard/filtering/filter-context.js` | React context for filter state management |
| `assets/js/dashboard/util/filters.js` | Existing filter utilities (extend for nested groups) |
| `assets/js/dashboard/stats/modals/filter-modal.js` | Existing filter modal (base for new component) |

### Backend

| File | Purpose |
|------|---------|
| `lib/plausible/segments.ex` | Segment business logic |
| `lib/plausible_web/controllers/api/segment_controller.ex` | **NEW** Segment CRUD API |
| `lib/plausible/analytics/filters.ex` | Filter parsing and validation |

### Tests

| File | Purpose |
|------|---------|
| `test/plausible/segments_test.exs` | **NEW** Segment unit tests |
| `assets/js/dashboard/filtering/filter-builder.test.js` | **NEW** Filter builder component tests |

## Common Development Tasks

### Run Tests

```bash
# Elixir tests
mix test

# JavaScript tests
cd assets && npm test

# Run specific test file
mix test test/plausible/segments_test.exs
```

### Run Linting

```bash
# Elixir (Credo)
mix credo --strict

# JavaScript (ESLint)
cd assets && npm run eslint

# TypeScript
cd assets && npm run typecheck
```

### Adding a New Filter Dimension

1. Add dimension to `lib/plausible/analytics/filters.ex`
2. Add to frontend dimension list in `assets/js/dashboard/util/filters.js`
3. Add operator compatibility mapping

## Debugging Tips

- Use `mix phx.routes` to see available routes
- Use `iex -S mix phx.server` for interactive Elixir debugging
- Browser DevTools for React component state
- Check ClickHouse queries in development logs
