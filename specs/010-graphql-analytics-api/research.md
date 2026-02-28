# Research: GraphQL Analytics API

**Feature**: GraphQL Analytics API
**Date**: 2026-02-27

## Research Questions

### RQ-001: GraphQL Library for Elixir

**Question**: What is the standard GraphQL library for Elixir and how is it used?

**Finding**: Absinthe is the de facto standard GraphQL library for Elixir. It provides:
- Schema definition language (SDL)
- Query resolution with plugs
- Middleware for authentication/authorization
- Subscription support for real-time (not needed for this feature)

**Decision**: Use Absinthe for GraphQL implementation
**Rationale**: Industry standard for Elixir, well-maintained, good integration with Phoenix

---

### RQ-002: Reusing Existing Stats Queries

**Question**: How can we leverage existing ClickHouse stats queries for GraphQL?

**Finding**: The existing `Plausible.Stats` module provides:
- `aggregate/3` - for aggregated metrics
- `breakdown/3` - for paginated data
- `timeseries/3` - for time-series data

These functions accept a query struct and return results that can be mapped to GraphQL types.

**Decision**: Create GraphQL resolvers that call existing Stats functions
**Rationale**: Avoids duplicating query logic; leverages existing optimization

---

### RQ-003: Authentication and Authorization

**Question**: How should the GraphQL API handle authentication?

**Finding**:
- Existing system uses API keys via `PlausibleWeb.Api.Helpers`
- Existing `AuthorizePublicApi` plug handles scope checking
- GraphQL can use Phoenix plugs for authentication

**Decision**: Reuse existing API key authentication and add scope for GraphQL access
**Rationale**: Consistent with existing API patterns, leverages existing security

---

## Alternatives Considered

### Alt-1: Custom GraphQL-to-SQL Solution
- Build GraphQL parser from scratch
- Rejected: High effort, error-prone, reinvents wheel

### Alt-2: REST API Enhancement Only
- Add more endpoints to existing REST stats API
- Rejected: User specifically requested GraphQL; less flexible for consumers

---

## Summary

The GraphQL API will use Absinthe, reuse existing Stats queries from ClickHouse, and integrate with existing API key authentication. This approach:
- Minimizes new code by reusing existing business logic
- Maintains consistency with existing API patterns
- Satisfies privacy and performance requirements through existing infrastructure
