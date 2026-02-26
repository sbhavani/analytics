# Webhook API Contract

**Feature**: Webhook Notifications (010-webhook-notifications)

## Overview

This document describes the webhook payload format sent to configured webhook endpoints.

## Webhook Payload

### Request

```
POST {configured_webhook_url}
Content-Type: application/json
X-Plausible-Signature: sha256={hmac_signature}
User-Agent: Plausible-Webhook/1.0
```

### Headers

| Header | Description |
|--------|-------------|
| Content-Type | Always `application/json` |
| X-Plausible-Signature | HMAC-SHA256 signature of payload using webhook secret |
| User-Agent | `Plausible-Webhook/1.0` |

### Payload Schema

```json
{
  "event_id": "uuid",
  "event_type": "visitor_spike | goal_completion",
  "site_id": "uuid",
  "site_domain": "string",
  "timestamp": "ISO8601 datetime",
  "trigger": {
    "id": "uuid",
    "type": "visitor_spike | goal_completion",
    "threshold": "integer (for visitor_spike)",
    "goal_id": "uuid (for goal_completion)",
    "goal_name": "string (for goal_completion)"
  },
  "data": {
    "current_visitors": "integer (for visitor_spike)",
    "goal_completions": "integer (for goal_completion)"
  }
}
```

### Example: Visitor Spike

```json
{
  "event_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "event_type": "visitor_spike",
  "site_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "site_domain": "example.com",
  "timestamp": "2026-02-26T14:30:00Z",
  "trigger": {
    "id": "b2c3d4e5-f6a7-8901-bcde-f23456789012",
    "type": "visitor_spike",
    "threshold": 100
  },
  "data": {
    "current_visitors": 150
  }
}
```

### Example: Goal Completion

```json
{
  "event_id": "f47ac10b-58cc-4372-a567-0e02b2c3d479",
  "event_type": "goal_completion",
  "site_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "site_domain": "example.com",
  "timestamp": "2026-02-26T14:30:00Z",
  "trigger": {
    "id": "c3d4e5f6-a7b8-9012-cdef-345678901234",
    "type": "goal_completion",
    "goal_id": "d4e5f6a7-b8c9-0123-def0-456789012345",
    "goal_name": "Sign Up"
  },
  "data": {
    "goal_completions": 5
  }
}
```

## Signature Verification

Receivers should verify the HMAC-SHA256 signature:

```python
# Python example
import hmac
import hashlib
import json

def verify_signature(payload: bytes, signature: str, secret: str) -> bool:
    expected = hmac.new(
        secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)
```

```javascript
// JavaScript example
const crypto = require('crypto');

function verifySignature(payload, signature, secret) {
  const expected = crypto
    .createHmac('sha256', secret)
    .update(payload)
    .digest('hex');
  return `sha256=${expected}` === signature;
}
```

## Test Webhook Payload

The test webhook sends a synthetic event with `event_type: "test"`:

```json
{
  "event_id": "test-event-12345",
  "event_type": "test",
  "site_id": "test-site-id",
  "site_domain": "test.example.com",
  "timestamp": "2026-02-26T14:30:00Z",
  "trigger": {
    "id": "test-trigger-id",
    "type": "test"
  },
  "data": {
    "message": "This is a test webhook from Plausible"
  }
}
```

## Retry Behavior

| Attempt | Delay |
|---------|-------|
| 1 | Immediate |
| 2 | 30 seconds |
| 3 | 2 minutes |
| 4 | 10 minutes |
| 5 | 1 hour |

After 5 failed attempts, the delivery is marked as failed and no more retries are attempted.
