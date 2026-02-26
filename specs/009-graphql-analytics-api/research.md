# Research: GraphQL Analytics API

**Date**: 2026-02-26
**Feature**: GraphQL Analytics API
**Branch**: 009-graphql-analytics-api

## Research Questions

### 1. GraphQL Library for Elixir

**Question**: What is the recommended GraphQL library for Elixir/Phoenix?

**Finding**: **Absinthe** is the de facto standard GraphQL library for Elixir. It provides:
- Schema definition with DSL
- Query execution
- Middleware support for cross-cutting concerns
- Subscription support for real-time
- Integration with Phoenix

**Decision**: Use Absinthe

**Rationale**:
- Well-maintained and widely adopted in Elixir community
- Phoenix integration is straightforward
- Matches the Constitution's "follow community conventions" principle

---

### 2. GraphQL Authentication Pattern

**Question**: How to integrate GraphQL with existing API key authentication?

**Finding**: Common patterns:
1. **HTTP Header Authentication**: Pass API key in `Authorization: Bearer <token>` header
2. **Context Injection**: Extract token in middleware/plug, add user to GraphQL context
3. **Directive-based**: Use GraphQL directives for field-level auth

**Existing Pattern**: The codebase already has `AuthorizePublicApi` plug that handles API key validation. This can be used as a before_send hook or as a Plug.

**Decision**: Use Plug-based authentication with Absinthe's `context` callback

**Rationale**:
- Follows existing patterns (same as REST APIs)
- Centralizes auth logic in a plug
- Clean separation of concerns

---

### 3. Rate Limiting for GraphQL

**Question**: How to implement rate limiting for GraphQL endpoints?

**Finding**: Options:
1. **Guardian + Redis**: Token-based with Redis backend
2. **Phoenix RateLimiter**: Built-in rate limiting
3. **Custom Plug**: Use existing rate limiting patterns

**Decision**: Create a custom Plug using existing rate limiting infrastructure

**Rationale**:
- Avoid adding new dependencies if possible
- Follow Constitution's YAGNI principle
- Can leverage any existing rate limiting the project already has

---

### 4. Schema Design for Analytics

**Question**: How should the GraphQL schema map to existing analytics queries?

**Finding**: The existing Stats API (`lib/plausible_web/controllers/api/stats_controller.ex`) provides:
- `/aggregate` - Aggregate metrics
- `/breakdown` - Breakdown by dimension
- `/timeseries` - Time series data

**Decision**: Mirror these capabilities in GraphQL:
- `Query.aggregate` - for totals
- `Query.breakdown` - for grouped data
- `Query.timeseries` - for trends
- `Query.events` - for raw event data

**Rationale**:
- Reuses existing query logic
- Familiar to users of REST API
- Simpler than designing entirely new structure

---

## Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| GraphQL Library | Absinthe | Community standard, Phoenix integration |
| Authentication | Plug-based with context | Matches existing API patterns |
| Rate Limiting | Custom Plug | Leverage existing infrastructure |
| Schema Structure | Mirror REST API | Reuse existing logic, familiar UX |

## Next Steps

1. Add Absinthe to dependencies
2. Create GraphQL schema with types mirroring existing stats
3. Implement resolvers using existing stats query modules
4. Add authentication plug
5. Write tests following ExUnit patterns
