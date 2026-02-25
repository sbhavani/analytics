# Research: Webhook Notifications

**Feature**: Webhook Notifications
**Date**: 2026-02-25

## Phase 0: Research Summary

All technical decisions were resolved using project standards from the Constitution and existing codebase patterns. No external research needed.

### Decisions Made

| Decision | Rationale | Alternatives Considered |
|----------|-----------|----------------------|
| HTTP Client: HTTPoison | Already used in project for external HTTP calls (Paddle integration, GeoIP lookups) | Could use Tesla, but HTTPoison is already a dependency |
| Background Jobs: Oban | Already used extensively in project for async operations (email reports, imports, notifications) | Could use external queue, but Oban is already configured |
| Database: PostgreSQL | Already primary transactional DB; webhook configs are relational data | Could use separate DB, but unnecessary complexity |
| Analytics: ClickHouse | Already stores all analytics data; triggers need to query visitor counts and goal completions | Must use ClickHouse - it's where analytics data lives |

### Technical Stack

- **Language**: Elixir
- **HTTP Client**: HTTPoison (existing)
- **Background Jobs**: Oban (existing)
- **Storage**: PostgreSQL (webhook configs), ClickHouse (analytics)
- **Testing**: ExUnit

### Integration Points

1. **Trigger Evaluation**: Query ClickHouse for visitor stats and goal completions
2. **Webhook Delivery**: Use Oban worker with HTTPoison for HTTP POST
3. **Configuration Storage**: Ecto schemas in PostgreSQL
4. **UI**: React components following existing patterns

### Security Considerations

- HTTPS required for webhook endpoints (validated on save)
- Secret keys stored encrypted at rest (using existing encryption pattern)
- HMAC-SHA256 for payload signing (standard practice)
- Rate limiting can be added via existing Phoenix mechanisms

## Phase 0 Complete

All unknowns resolved. Proceeding to Phase 1: Design.
