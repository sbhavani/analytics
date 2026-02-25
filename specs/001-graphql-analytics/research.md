# Research: GraphQL Analytics API

## Overview

This document captures the research findings and decisions made for implementing the GraphQL Analytics API feature.

## Decisions Made

### Decision 1: Pagination Default Page Size

**Chosen**: 100 items per page

**Rationale**:
- Industry standard for REST/GraphQL APIs is typically 20-100 items
- 100 items provides a good balance between reducing request overhead and keeping response sizes manageable
- Aligns with common pagination patterns in analytics dashboards
- Can be customized via query parameters if needed

**Alternatives considered**:
- 50 items: More conservative, better for mobile clients, but increases number of requests
- 1000 items: Better for bulk export use cases, but larger response payloads

---

### Decision 2: Authentication Method

**Chosen**: Bearer token with API keys (existing pattern)

**Rationale**:
- The project already has a robust API key authentication system (`AuthorizePublicAPI` plug)
- Uses Bearer token format in Authorization header
- Supports scoped API keys with fine-grained permissions
- Already integrates with rate limiting
- No need to implement new authentication infrastructure

**Alternatives considered**:
- OAuth 2.0: Industry standard but adds complexity; overkill for server-to-server API
- JWT tokens: Stateless but requires additional infrastructure; current API key system works well

**Reference**: `lib/plausible_web/plugs/authorize_public_api.ex`

---

### Decision 3: Rate Limit Thresholds

**Chosen**:
- Default: 600 requests/hour per API key
- Burst limit: 60 requests per 10 seconds

**Rationale**:
- Existing system defaults to 600/hour with 60/10s burst (configurable in `config/config.exs`)
- Enterprise plans support up to 1,000,000 requests/hour
- These limits have been battle-tested in production
- Align with existing API behavior to provide consistent experience
- Burst limit prevents sudden spikes while hourly limit prevents sustained high usage

**Reference**:
- Config: `config/config.exs` lines 91-94
- Implementation: `lib/plausible/auth/api_key.ex`

---

## Existing Project Patterns

### API Structure

The project uses Phoenix controllers under `lib/plausible_web/controllers/api/`:
- `/api/v1/stats` - Stats API v1
- `/api/v2` - Stats API v2
- `/api/plugins` - Plugin APIs

### Data Storage

- **PostgreSQL**: Transactional data, user data, site configuration
- **ClickHouse**: Analytics data (pageviews, events)

### Testing

- ExUnit for Elixir (backend)
- Jest for JavaScript (frontend)

---

## Technology Recommendations (from Constitution)

- **Backend**: Elixir/Phoenix - follow Phoenix conventions for controllers, contexts, and schemas
- **Database**: ClickHouse for analytics queries (already used)
- **Testing**: ExUnit with contract tests for API boundaries
- **Observability**: Structured logging, OpenTelemetry integration

---

## GraphQL Implementation Considerations

Based on the feature requirements and project constraints:

1. **Use Absinthe**: The standard GraphQL library for Elixir/Phoenix
2. **Integrate with existing auth**: Reuse `AuthorizePublicAPI` for GraphQL endpoint
3. **Query ClickHouse efficiently**: Leverage existing query patterns in `Plausible.Stats` context
4. **Add structured logging**: Follow project conventions for observability
5. **Write tests first**: Per constitution - Red-Green-Refactor cycle
