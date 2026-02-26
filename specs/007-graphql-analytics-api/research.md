# Research: GraphQL Analytics API

**Date**: 2026-02-26
**Feature**: GraphQL Analytics API

## Findings

### Existing Infrastructure Analysis

**Analytics Query System**:
- `Plausible.Stats` module provides core query functions: `query/2`, `aggregate/3`, `breakdown/4`, `timeseries/3`
- `Plausible.Stats.Query` struct holds query parameters including date range, filters, dimensions, metrics, and pagination
- Filter system supports complex expressions with AND/OR/NOT operators
- Existing metrics: visitors, pageviews, events, bounce_rate, visit_duration, etc.

**API Patterns**:
- REST API in `lib/plausible_web/controllers/api/` with ExternalStatsController and ExternalQueryApiController
- API key authentication via `Plausible.Auth.ApiKey` schema
- Authorization plug: `PlausibleWeb.Plugs.AuthorizePublicAPI` with rate limiting
- Bearer token in Authorization header

**GraphQL**:
- No existing GraphQL infrastructure in codebase
- Absinthe is the standard GraphQL library for Elixir

## Technology Decision

**GraphQL Library**: Absinthe
- Mature, well-maintained Elixir GraphQL library
- Integrates well with Phoenix
- Supports schema-driven development with clear contracts

**Authentication**: Reuse existing API key infrastructure
- `Plausible.Auth.ApiKey` for authentication
- `PlausibleWeb.Plugs.AuthorizePublicAPI` for authorization and rate limiting

## Implementation Approach

1. Create GraphQL schema with types for Pageview, Event, CustomMetric
2. Create resolvers that bridge to existing Stats modules
3. Add GraphQL controller/router entry point
4. Reuse existing query parsing and execution infrastructure
5. Add ExUnit tests for schema and resolvers

## No Unresolved Clarifications

All technical questions resolved through codebase research:
- Authentication: Existing API key pattern
- Query execution: Existing Stats modules
- Filter syntax: Existing filter system
- Rate limiting: Existing API infrastructure
