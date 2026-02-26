# Webhook Payload Contract

**Feature**: 008-webhook-notifications

This document describes the webhook payload format sent to configured endpoints.

## HTTP POST Request

| Property | Value |
|----------|-------|
| Method | POST |
| Content-Type | application/json |
| Header: X-Plausible-Signature | HMAC-SHA256 signature of body |
| Header: X-Plausible-Event | Event type (spike, drop, goal) |

## Payload: Traffic Spike

```json
{
  "event_type": "spike",
  "site_id": "abc123def456",
  "site_domain": "example.com",
  "timestamp": "2026-02-26T10:30:00Z",
  "current_visitors": 150,
  "threshold": 100,
  "change_type": "spike",
  "sources": [
    {"name": "Twitter", "visitors": 80},
    {"name": "Google", "visitors": 40}
  ],
  "pages": [
    {"path": "/blog/viral-post", "visitors": 60}
  ]
}
```

## Payload: Traffic Drop

```json
{
  "event_type": "drop",
  "site_id": "abc123def456",
  "site_domain": "example.com",
  "timestamp": "2026-02-26T10:30:00Z",
  "current_visitors": 5,
  "threshold": 20,
  "change_type": "drop"
}
```

## Payload: Goal Completion

```json
{
  "event_type": "goal",
  "site_id": "abc123def456",
  "site_domain": "example.com",
  "timestamp": "2026-02-26T10:30:00Z",
  "goal_id": "goal789xyz",
  "goal_name": "Signup",
  "count": 1
}
```

## Signature Verification

Receivers should verify the signature using:

```
signature = HMAC-SHA256(payload_body, secret)
```

The secret is configured in the webhook settings.

## Test Payload

```json
{
  "event_type": "test",
  "site_id": "test-site-id",
  "site_domain": "example.com",
  "timestamp": "2026-02-26T10:30:00Z",
  "message": "This is a test webhook from Plausible"
}
```
