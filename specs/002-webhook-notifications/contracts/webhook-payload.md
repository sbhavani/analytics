# Webhook Payload Contract

**Version**: 1.0
**Last Updated**: 2026-02-25

## Overview

This document defines the webhook payload format for Plausible Analytics webhook notifications. All payloads are sent as HTTP POST requests with JSON body.

## Authentication

Each webhook request includes a signature header for verification:

```
X-Webhook-Signature: sha256=<hmac_signature>
```

**Signature Computation**:
```
signature = HMAC-SHA256(payload_body, webhook_secret)
```

Recipients should verify the signature before processing the payload.

---

## Payload Structure

All webhook payloads follow this base structure:

```json
{
  "event": "goal_completion",
  "site_id": "example.com",
  "timestamp": "2026-02-25T12:00:00Z",
  "data": { }
}
```

| Field | Type | Description |
|-------|------|-------------|
| event | String | Event type (see Event Types) |
| site_id | String | Site domain or identifier |
| timestamp | ISO8601 DateTime | When the event occurred (UTC) |
| data | Object | Event-specific payload data |

---

## Event Types

### 1. goal_completion

Triggered when a visitor completes a configured goal.

```json
{
  "event": "goal_completion",
  "site_id": "example.com",
  "timestamp": "2026-02-25T12:00:00Z",
  "data": {
    "goal_id": "123",
    "goal_name": "Signup",
    "goal_type": "custom",
    "visitor_count": 1,
    "path": "/signup",
    "referrer": "https://google.com"
  }
}
```

| Data Field | Type | Description |
|------------|------|-------------|
| goal_id | String | Unique goal identifier |
| goal_name | String | Goal display name |
| goal_type | String | "custom" or "pageview" |
| visitor_count | Integer | Number of visitors who completed |
| path | String | URL path where goal triggered |
| referrer | String | Referrer URL (if available) |

---

### 2. visitor_spike

Triggered when current visitors exceed configured threshold.

```json
{
  "event": "visitor_spike",
  "site_id": "example.com",
  "timestamp": "2026-02-25T12:00:00Z",
  "data": {
    "current_visitors": 150,
    "threshold": 100,
    "change_type": "spike",
    "top_sources": [
      { "source": "google.com", "visitors": 45 },
      { "source": "twitter.com", "visitors": 30 }
    ],
    "top_pages": [
      { "page": "/", "visitors": 80 },
      { "page": "/pricing", "visitors": 40 }
    ]
  }
}
```

| Data Field | Type | Description |
|------------|------|-------------|
| current_visitors | Integer | Current visitor count |
| threshold | Integer | Configured threshold |
| change_type | String | "spike" (always this for this event) |
| top_sources | Array | Top 3 referrers with visitor counts |
| top_pages | Array | Top 3 pages with visitor counts |

---

### 3. custom_event

Triggered when a custom event occurs.

```json
{
  "event": "custom_event",
  "site_id": "example.com",
  "timestamp": "2026-02-25T12:00:00Z",
  "data": {
    "event_name": "button_click",
    "visitor_count": 1,
    "path": "/home",
    "props": {
      "button_id": "cta-primary",
      "color": "blue"
    }
  }
}
```

| Data Field | Type | Description |
|------------|------|-------------|
| event_name | String | Name of custom event |
| visitor_count | Integer | Number of event occurrences |
| path | String | URL path where event occurred |
| props | Object | Event properties (if any) |

---

### 4. error_condition

Triggered when an analytics error is detected.

```json
{
  "event": "error_condition",
  "site_id": "example.com",
  "timestamp": "2026-02-25T12:00:00Z",
  "data": {
    "error_type": "ingestion_failure",
    "message": "Failed to process event",
    "details": {
      "event_id": "abc123",
      "reason": "invalid_domain"
    }
  }
}
```

| Data Field | Type | Description |
|------------|------|-------------|
| error_type | String | Type of error |
| message | String | Error description |
| details | Object | Additional error context |

---

## Delivery Headers

Each webhook POST request includes these headers:

| Header | Example | Description |
|--------|---------|-------------|
| Content-Type | application/json | Request content type |
| X-Webhook-Signature | sha256=abc123... | HMAC signature |
| X-Webhook-Event | goal_completion | Event type |
| X-Webhook-Site-Id | example.com | Site identifier |

---

## Versioning

The payload format may evolve. Version is communicated via:
1. Initial release uses version 1.0 (no version in payload)
2. Future versions will include `version` field

Recipients should handle unknown fields gracefully (ignore them).

---

## Example: Full Request

```http
POST /webhook-endpoint HTTP/1.1
Host: example.com
Content-Type: application/json
X-Webhook-Signature: sha256=f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8
X-Webhook-Event: goal_completion
X-Webhook-Site-Id: example.com

{
  "event": "goal_completion",
  "site_id": "example.com",
  "timestamp": "2026-02-25T12:00:00Z",
  "data": {
    "goal_id": "123",
    "goal_name": "Signup",
    "goal_type": "custom",
    "visitor_count": 1,
    "path": "/signup",
    "referrer": "https://google.com"
  }
}
```
