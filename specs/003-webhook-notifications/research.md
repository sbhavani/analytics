# Research: Webhook Notifications Feature

## Unknowns Resolution

### Decision 1: Retry Policy

**Question**: FR-010 - How should the system handle delivery failures?

**Decision**: Retry 3 times with exponential backoff (1s, 2s, 4s)

**Rationale**:
- Exponential backoff is the industry standard for transient failures
- 3 retries balances reliability against excessive load on failing endpoints
- Short delays (max 7 seconds total) align with SC-002 (95% complete within 10 seconds)
- Matches patterns used in existing workers (e.g., email retry behavior)

**Alternatives Considered**:
- 5 retries with linear backoff: Too aggressive for webhook scenarios
- Single retry: Insufficient reliability
- No automatic retries: Requires manual monitoring, poor UX

---

### Decision 2: Webhook Security

**Question**: FR-011 - How should the system authenticate webhook requests?

**Decision**: HMAC-SHA256 signature in X-Signature header

**Rationale**:
- Industry standard (used by GitHub, Stripe, Slack)
- Allows recipients to verify the sender without exposing secrets
- Compatible with existing Elixir ecosystem (Plug/Crypto)
- Aligns with constitution security requirements (input validation, no sensitive data in logs)

**Alternatives Considered**:
- API key in header: Simpler but less secure (key exposed in every request)
- Bearer token: OAuth-like but overkill for webhook verification
- No auth: Only suitable for public data (violates privacy-first principle)

---

## Project Context

### Technology Stack
- **Backend**: Elixir/Phoenix (Phoenix framework conventions)
- **Database**: PostgreSQL (transactional), ClickHouse (analytics)
- **Frontend**: React with TypeScript, TailwindCSS
- **Testing**: ExUnit (Elixir), Jest (JavaScript)
- **Background Jobs**: Oban (workers directory pattern)

### Existing Patterns
- Workers live in `lib/workers/` with naming pattern `action_target.ex`
- Contexts in `lib/plausible/` for business logic
- Controllers in `lib/plausible_web/` for HTTP layer
- Settings pages likely in `lib/plausible_web/controllers/`

### Webhook Implementation Considerations
1. **Queue Delivery**: Use Oban worker for async HTTP requests
2. **Store Configuration**: New table in PostgreSQL for webhook configs
3. **Track Deliveries**: Delivery log table for history (FR-006)
4. **Trigger Sources**: Hook into existing goal completion and visitor spike detection logic
