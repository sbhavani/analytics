# Research: GraphQL Analytics API Implementation

**Feature**: GraphQL Analytics API
**Date**: 2026-02-25
**Phase**: 0 - Research

## Research Questions

### 1. GraphQL in Elixir - Best Practices

**Decision**: Use Absinthe as the GraphQL library for Elixir/Phoenix

**Rationale**:
- Absinthe is the de facto standard for GraphQL in Elixir
- Well-maintained with excellent documentation
- Integrates cleanly with Phoenix via absinthe_phoenix
- Supports query complexity analysis for performance protection

**Alternatives Considered**:
- `graphql-elixir` - Less maintained, fewer features than Absinthe
- Manual GraphQL implementation - Too much boilerplate, reinventing the wheel

---

### 2. Connecting to Existing Business Logic

**Decision**: Resolvers act as thin translation layer to existing Stats modules

**Rationale**:
- Existing `Stats.breakdown/4`, `Stats.aggregate/3`, `Stats.timeseries/3` are already optimized for ClickHouse
- Reusing these modules ensures:
  - Consistent query behavior with existing REST API
  - Leverages existing query optimization (QueryOptimizer)
  - Maintains same filtering and authorization logic
- Resolvers only transform GraphQL inputs → Query struct → delegate to Stats modules

**Alternatives Considered**:
- Creating new data access layer - Would duplicate code and diverge from existing patterns
- Direct ClickHouse queries from resolvers - Loses existing optimization and authorization

---

### 3. Performance Patterns for Large Datasets

**Decision**: Use cursor-based pagination via Absinthe connections

**Rationale**:
- Cursor pagination handles large datasets (10,000+ records) better than offset-based
- Absinthe has built-in connection support
- Required for SC-005 (pagination for 10,000+ records)
- Existing codebase uses `{limit, page}` pattern - map to cursor-based internally

**Performance Protections**:
- Query complexity analysis middleware
- Leverage existing sampling cache (`Plausible.Stats.SamplingCache`)
- Reuse existing ClickHouse query optimization

**Alternatives Considered**:
- Offset-based pagination - Can be slow for large offsets
- No pagination - Would cause performance issues

---

### 4. Error Handling Patterns

**Decision**: Return empty arrays for no-data scenarios, structured errors for failures

**Rationale**:
- Matches existing REST API behavior (FR-010: "handle queries for date ranges with no data gracefully")
- GraphQL best practice: distinguish between "no data" (empty array) vs "error" (null with errors)
- Use existing error helper patterns from `PlausibleWeb.Api.Helpers`

**Error Response Pattern**:
- Validation errors: `{error, message: "...", field: "..."}`
- Not found: Return empty array (not error) per FR-010
- Server errors: Log and return generic message (don't leak internal details)

---

## Key Technical Decisions

### Project Structure

```
lib/plausible_web/graphql/
├── schema.ex              # Main GraphQL schema
├── resolvers/
│   ├── pageviews.ex       # Pageview query resolvers
│   ├── events.ex         # Event query resolvers
│   └── metrics.ex        # Custom metrics resolvers
├── types/
│   ├── pageview.ex       # Pageview type definitions
│   ├── event.ex         # Event type definitions
│   ├── metric.ex        # Custom metric type definitions
│   └── filters.ex       # Filter input types
└── middleware/
    └── authentication.ex # Auth middleware
```

### Dependencies to Add

```elixir
{:absinthe, "~> 1.7"},
{:absinthe_phoenix, "~> 2.0"},
{:dataloader, "~> 1.0"}  # For batch loading if needed
```

### Authentication

- Reuse existing `AuthorizeSiteAccess` plug
- Apply via custom pipeline in router.ex

---

## Existing Codebase Integration Points

| Existing Module | Purpose |
|----------------|---------|
| `Plausible.Stats.Query` | Build query from params |
| `Plausible.Stats.breakdown/4` | Get breakdown by dimension |
| `Plausible.Stats.aggregate/3` | Get aggregate metrics |
| `Plausible.Stats.timeseries/3` | Get time-series data |
| `Plausible.Stats.QueryOptimizer` | Optimize query selection |
| `Plausible.Stats.Metrics` | Available metrics definitions |
| `PlausibleWeb.Api.Helpers` | Standardized error responses |

---

## Testing Strategy

- Schema validation tests (unit)
- Resolver tests using existing factory patterns (unit)
- Integration tests with populated test data (integration)
- Follow existing test patterns in `test/plausible_web/controllers/`
