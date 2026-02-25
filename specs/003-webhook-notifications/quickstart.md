# Quickstart: Webhook Notifications

## Overview

Enable HTTP POST notifications when specified events occur on your analytics site.

## Prerequisites

- Site admin access
- A server endpoint to receive webhooks

## Quick Setup

### 1. Configure a Webhook

Navigate to **Site Settings > Webhooks** and add a new webhook:

```
URL: https://your-server.com/webhook
Secret: (min 16 characters for HMAC signing)
```

### 2. Select Triggers

Choose which events should trigger notifications:

| Trigger | Description |
|---------|-------------|
| Goal Completion | Fires when a configured goal is completed |
| Visitor Spike | Fires when visitor count exceeds threshold |

### 3. Set Thresholds (Optional)

For visitor spike, configure the percentage threshold:

- Default: 50% increase
- Range: 10% - 500%

### 4. Verify

Test your webhook by:
1. Creating a test goal or generating traffic spike
2. Checking delivery status in the webhook history

## Payload Format

All webhooks are sent as HTTP POST with JSON body:

```json
{
  "event_id": "uuid",
  "event_type": "goal_completion|visitor_spike",
  "site_id": "uuid",
  "site_name": "string",
  "timestamp": "ISO8601",
  "data": { }
}
```

## Security

All payloads include HMAC-SHA256 signature in `X-Signature` header:

```
X-Signature: sha256=<signature>
```

Verify using: `HMAC-SHA256(payload, secret)`

## Retry Behavior

Failed deliveries retry up to 3 times with exponential backoff (1s, 2s, 4s).

## Monitoring

View delivery history at **Site Settings > Webhooks > History**

Each delivery shows:
- Status (success/failed)
- HTTP response code
- Error message (if failed)
- Retry attempt number
