# Research: Webhook Notifications Feature

## Decisions and Rationale

### Decision 1: Retry Strategy for Failed Webhook Deliveries

**Chosen**: 3 retries with exponential backoff (starting at 1 second, doubling each time: 1s, 2s, 4s)

**Rationale**: This is the industry standard pattern for webhook deliveries:
- GitHub, Stripe, and other major platforms use similar patterns
- Exponential backoff prevents overwhelming failing endpoints
- 3 retries balances reliability with avoiding excessive load on problematic endpoints

**Alternatives considered**:
- Linear backoff (simpler but less effective at preventing overload)
- Fixed retry count without backoff (can cause immediate hammering)
- Infinite retries (dangerous for persistent failures)

---

### Decision 2: Webhook Scope - Per-Site vs Account-Wide

**Chosen**: Per-site configuration

**Rationale**: Based on existing codebase patterns:
- `TrafficChangeNotification` is per-site (see `lib/plausible/site/traffic_change_notification.ex`)
- Site-level settings follow this pattern throughout Plausible
- Users typically manage webhooks at the website level in analytics platforms

**Alternatives considered**:
- Account-wide: Would require different permission model, more complex UI
- Per-site aligns with existing user mental model

---

### Decision 3: HTTP Client for Webhook Delivery

**Chosen**: Use existing HTTP client pattern in codebase

**Rationale**:
- Existing code uses `Req` for HTTP requests (modern Elixir HTTP client)
- Mix tasks use `HTTPoison` in some places
- Should follow existing patterns for consistency

**Implementation note**: Will use `Req` similar to other parts of the codebase

---

### Decision 4: Delivery Queue

**Chosen**: Separate Oban queue (e.g., `:webhooks`)

**Rationale**:
- Existing traffic notifications use `:spike_notifications` queue
- Webhooks should be in their own queue for independent scaling/failure handling
- Allows different retry policies from email notifications

---

### Decision 5: Payload Signing

**Chosen**: HMAC-SHA256 signature in `X-Webhook-Signature` header

**Rationale**:
- Industry standard (used by Stripe, GitHub, etc.)
- Easy for webhook consumers to verify
- Uses site-specific secret stored in database

---

## Existing Codebase Patterns

### Site-Level Configuration Pattern
- Schema file: `lib/plausible/site/traffic_change_notification.ex`
- Associated with site via `belongs_to :site`
- CRUD handled in site controller

### Background Job Pattern
- Oban workers in `lib/workers/`
- Example: `traffic_change_notifier.ex` - handles similar notification logic
- Uses site associations to fetch configurations

### Settings UI Pattern
- Site controller: `lib/plausible_web/controllers/site_controller.ex`
- Actions for enable/disable/update of notification settings

## Edge Cases to Handle

1. **Webhook URL unreachable**: Use retry with exponential backoff, log failures
2. **Non-2xx response**: Treat as failure, trigger retry
3. **Redirects**: Follow redirects (max 3 hops), then treat as failure
4. **Rate limiting (429)**: Use special backoff (longer wait)
5. **Multiple webhooks per site**: Allow multiple, fire all enabled on trigger

## Dependencies

- Existing visitor/goal tracking (already exists)
- Site management infrastructure (already exists)
- Oban background jobs (already in use)
