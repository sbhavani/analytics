# Research: Webhook Notifications

**Feature**: Webhook Notifications (010-webhook-notifications)
**Date**: 2026-02-26

## Research Summary

No additional research required. This feature extends existing patterns already proven in the codebase:

## Existing Patterns Used

| Pattern | Location | Usage for Webhooks |
|---------|----------|-------------------|
| Site configuration | `lib/plausible/site/traffic_change_notification.ex` | Model for webhook config storage |
| Background job | `lib/workers/traffic_change_notifier.ex` | Oban worker pattern for trigger checking |
| HTTP client | `lib/plausible/http_client.ex` | Finch-based HTTP POST for webhook delivery |
| Settings UI | `lib/plausible_web/live/goal_settings/` | React LiveView pattern for settings forms |
| Delivery logging | Existing in traffic_change_notifier | Template for tracking delivery attempts |

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| PostgreSQL storage | Matches existing TrafficChangeNotification pattern, no need for ClickHouse |
| HMAC-SHA256 signing | Industry standard for webhook verification (Stripe, GitHub webhooks) |
| Oban queue: `webhooks` | Dedicated queue for webhook delivery processing |
| JSON payload format | Universal format supported by all webhook consumers |
| Exponential backoff | Standard retry pattern for transient failures |

## Alternatives Considered

- **ClickHouse for delivery logs**: Rejected - PostgreSQL sufficient for webhook delivery metadata (not analytics data)
- **Message queue (RabbitMQ)**: Rejected - Oban provides necessary reliability with simpler deployment
- **Synchronous delivery**: Rejected - Background processing required for retry logic and SC-006 (100 concurrent deliveries)

## Compliance with Constitution

- **TDD**: Tests will be written before implementation
- **Privacy-first**: Webhooks only send event metadata, no PII
- **Performance**: Target of 100 concurrent deliveries matches SC-006
- **Simplicity**: Reuses existing infrastructure, no new technologies introduced
