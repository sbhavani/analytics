# Quickstart: Webhook Notifications

**Feature**: 008-webhook-notifications
**Date**: 2026-02-26

## Overview

This document provides a high-level guide for implementing webhook notifications in Plausible Analytics.

## Implementation Steps

### 1. Database Migration

Create tables for webhook configuration and delivery logging:

- `webhooks` - Site webhook configurations
- `webhook_events` - Pending/delivered/failed events
- `webhook_delivery_logs` - Delivery attempt records

### 2. Backend Components

**Schema** (`lib/plausible/site/webhook.ex`):
- Webhook configuration with URL, secret, enabled events, threshold

**Worker** (`lib/workers/webhook_delivery.ex`):
- Oban worker for async delivery
- Retry logic with exponential backoff
- Signature generation using HMAC-SHA256

**Context** (`lib/plausible/webhooks.ex`):
- CRUD operations for webhook configs
- Event triggering logic

### 3. Frontend Components

**Settings Page**:
- List existing webhooks
- Add/Edit/Delete webhook form
- Test webhook button

### 4. Integration Points

**Traffic Spike/Drop**:
- Extend existing `TrafficChangeNotifier` to also trigger webhook events
- Use same threshold checking logic

**Goal Completions**:
- Query goals via existing Goal schema
- Trigger webhook on goal completion events

## Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| `webhook_min_interval` | Min hours between spike/drop notifications | 12 |
| `webhook_max_retries` | Maximum retry attempts | 3 |
| `webhook_timeout` | HTTP request timeout (ms) | 5000 |

## Testing Checklist

- [ ] Unit tests for Webhook schema
- [ ] Unit tests for WebhookDelivery worker
- [ ] Integration tests for end-to-end delivery
- [ ] Manual test with real webhook endpoint
- [ ] Test retry logic with failing endpoint
- [ ] Verify signature header generation

## Security Considerations

- Store webhook secrets encrypted at rest
- Never log webhook secrets
- Validate webhook URL format (no internal URLs)
- Rate limit webhook configuration changes
