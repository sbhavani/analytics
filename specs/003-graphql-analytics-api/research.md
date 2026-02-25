# Research: GraphQL Analytics API

## Decisions Made

### Technology Selection

| Decision | Choice | Rationale |
|----------|--------|-----------|
| GraphQL Library | Absinthe | Standard Elixir GraphQL library, well-maintained, integrates with Phoenix |
| Data Source | ClickHouse via existing Stats context | Leverages existing analytics queries, avoids duplication |
| Authentication | Reuse existing API key auth | Consistent with existing API patterns |
| Rate Limiting | Plug-based | Follows Phoenix conventions |

### GraphQL Implementation Approach

**Decision**: Use Absinthe with existing Stats context

- **Rationale**: The existing `Plausible.Stats` module already handles ClickHouse queries. GraphQL resolvers will delegate to these existing functions rather than reimplementing query logic.
- **Alternatives considered**:
  - Building raw SQL queries - Rejected: Would duplicate existing logic and miss optimizations
  - Using a different GraphQL library - Rejected: Absinthe is the standard for Elixir

### Schema Design

**Decision**: Flat query structure with filters as input types

- **Rationale**: Matches existing REST API filter patterns, familiar to users
- **Alternatives considered**:
  - Nested queries per entity - Rejected: More complex to implement, harder to filter across entities

### Performance Considerations

**Decision**: Leverage existing query optimization, add caching layer later if needed

- **Rationale**: Existing Stats queries are already optimized for ClickHouse
- **Alternatives considered**:
  - Aggressive pre-computation - Rejected: YAGNI - start simple

## Phase 0 Summary

No research tasks required - all technical decisions derived from codebase analysis and constitution constraints.
