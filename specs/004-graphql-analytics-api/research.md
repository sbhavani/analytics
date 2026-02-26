# Research: GraphQL Analytics API Implementation

**Feature**: GraphQL Analytics API
**Date**: 2026-02-25
**Phase**: 0 - Research

## Technology Selection

### GraphQL Library for Elixir

**Decision**: Absinthe

**Rationale**:
- Most mature and widely-used GraphQL library for Elixir
- Strong community support and active maintenance
- Integrates well with Phoenix and Ecto
- Supports schema-based validation and query complexity analysis
- Has built-in support for subscriptions (future-proofing)

**Alternatives Considered**:
- **Nerve** - Less mature, limited community adoption
- **GraphQL (plain)** - No high-level DSL, requires more boilerplate

### GraphQL Framework Pattern

**Decision**: Use Phoenix controller + Absinthe Plug

**Rationale**:
- Follows existing project patterns (REST controllers in PlausibleWeb)
- Leverages existing authentication and authorization middleware
- Allows reuse of site lookup plugs and query building utilities

## Architecture Decisions

### Query Pattern

**Decision**: Reuse existing Stats.Query building infrastructure

**Rationale**:
- Existing ClickHouse query builders already handle filtering, date ranges, and aggregations efficiently
- Avoids duplicating business logic
- Maintains consistency with existing REST API behavior

### Authentication

**Decision**: Reuse existing API authentication (API keys / session-based)

**Rationale**:
- Consistent with existing API patterns
- Users can use existing API keys
- Respects existing site access controls

## Privacy Considerations

- GraphQL queries will only return aggregate data (not raw events)
- Access control enforced at site level (users can only query their own sites)
- No personal data exposure (following privacy-first principles)
- Query complexity limits to prevent abuse

## Performance Strategy

- Leverage existing ClickHouse query optimizations
- Implement query complexity analysis to prevent expensive queries
- Add pagination (max 1000 records per request)
- Cache frequently-accessed aggregated data where appropriate
- Add instrumentation for monitoring query performance
