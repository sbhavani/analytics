# Webhook Payload Contract

## Overview

This document defines the HTTP POST payload format sent to configured webhook endpoints when trigger events occur.

## HTTP Request

```
POST {configured_webhook_url}
Content-Type: application/json
X-Webhook-Signature: sha256={hmac_signature}
X-Webhook-Event: {event_type}
User-Agent: Plausible-Analytics-Webhook/1.0
```

## Payload Schemas

### Goal Completion Event

```json
{
  "event": "goal_completion",
  "site_id": "octo-123-abc",
  "site_domain": "example.com",
  "timestamp": "2026-02-25T14:30:00Z",
  "data": {
    "goal_id": "g-456-def",
    "goal_name": "Sign up",
    "visitor_id": "v-789-ghi",
    "visitor_country": "US",
    "visitor_referrer": "google.com",
    "pathname": "/pricing",
    "properties": {
      "plan": "enterprise"
    }
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| event | String | Always "goal_completion" for this event type |
| site_id | String | Unique site identifier |
| site_domain | String | Site domain name |
| timestamp | ISO8601 | When the event occurred |
| data.goal_id | String | Goal identifier |
| data.goal_name | String | Goal display name |
| data.visitor_id | String | Anonymous visitor identifier |
| data.visitor_country | String (nullable) | Country code |
| data.visitor_referrer | String (nullable) | Referrer URL |
| data.pathname | String | Page path where goal completed |
| data.properties | Object (nullable) | Custom event properties |

---

### Visitor Spike Event

```json
{
  "event": "visitor_spike",
  "site_id": "octo-123-abc",
  "site_domain": "example.com",
  "timestamp": "2026-02-25T14:30:00Z",
  "data": {
    "current_visitors": 150,
    "previous_visitors": 80,
    "threshold": 100,
    "percentage_increase": 87.5,
    "sources": [
      {"name": "google.com", "visitors": 45},
      {"name": "twitter.com", "visitors": 30},
      {"name": "Direct / None", "visitors": 75}
    ],
    "top_pages": [
      {"path": "/", "visitors": 60},
      {"path": "/pricing", "visitors": 45},
      {"path": "/features", "visitors": 30}
    ]
  }
}
```

| Field | Type | Description |
|-------|------|-------------|
| event | String | Always "visitor_spike" for this event type |
| site_id | String | Unique site identifier |
| site_domain | String | Site domain name |
| timestamp | ISO8601 | When the spike was detected |
| data.current_visitors | Integer | Current visitor count |
| data.previous_visitors | Integer | Visitor count before spike |
| data.threshold | Integer | Configured spike threshold |
| data.percentage_increase | Float | Percentage increase |
| data.sources | Array (nullable) | Top traffic sources |
| data.top_pages | Array (nullable) | Top pages by visitors |

---

### Test Event

```json
{
  "event": "test",
  "site_id": "octo-123-abc",
  "site_domain": "example.com",
  "timestamp": "2026-02-25T14:30:00Z",
  "data": {
    "message": "This is a test webhook from Plausible Analytics",
    "webhook_id": "wh-789-xyz"
  }
}
```

---

## Signature Verification

### Generating Signature

The signature is generated using HMAC-SHA256:

```
signature = HMAC-SHA256(secret, payload_body)
```

Where:
- `secret`: The webhook's configured secret key
- `payload_body`: Raw JSON string of the payload

### Verifying Signature

```python
import hmac
import hashlib

def verify_signature(payload_body, signature_header, secret):
    expected = hmac.new(
        secret.encode('utf-8'),
        payload_body.encode('utf-8'),
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(expected, signature_header.replace('sha256=', ''))
```

```javascript
const crypto = require('crypto');

function verifySignature(payloadBody, signatureHeader, secret) {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payloadBody, 'utf8')
    .digest('hex');

  const provided = signatureHeader.replace('sha256=', '');

  return crypto.timingSafeEqual(
    Buffer.from(expected),
    Buffer.from(provided)
  );
}
```

## Error Responses

Webhook endpoints should return:

| Status Code | Meaning |
|-------------|---------|
| 200-299 | Success - event acknowledged |
| 400 | Bad request - check payload format |
| 401 | Unauthorized - invalid signature |
| 404 | Not found - endpoint doesn't exist |
| 429 | Rate limited - will retry with longer backoff |
| 500+ | Server error - will retry |

## Retry Behavior

- 3 retries with exponential backoff: 1s, 2s, 4s
- 429 responses get extended backoff (60s)
- After all retries exhausted, mark as failed in delivery log
