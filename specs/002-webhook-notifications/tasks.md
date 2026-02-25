# Tasks: Webhook Notifications

**Feature**: Webhook Notifications
**Branch**: `002-webhook-notifications`
**Generated**: 2026-02-25

## Implementation Strategy

The feature is organized by user story to enable independent implementation and testing:

- **MVP Scope**: User Story 1 (Configure Webhook Endpoint) provides foundational CRUD that other stories depend on
- **Incremental Delivery**: Each user story phase is independently testable
- **Parallel Opportunities**: Database migrations can run in parallel with test setup

## Phases

### Phase 1: Setup

Database migrations and project initialization.

### Phase 2: Foundational

Core schemas and context module that all user stories depend on.

### Phase 3: User Story 1 - Configure Webhook Endpoint (P1)

CRUD operations for webhook configuration.

### Phase 4: User Story 2 - Receive Notifications (P1)

Event trigger system and HTTP delivery.

### Phase 5: User Story 3 - Verify Webhook Configuration (P2)

Test webhook functionality.

### Phase 6: User Story 4 - Manage Webhook Security (P2)

HMAC signature implementation.

### Phase 7: Polish & Integration

Cross-cutting concerns and final integration.

---

## Phase 1: Setup

**Goal**: Initialize database infrastructure for webhooks

**Independent Test**: Migrations can be verified by running `mix ecto.migrate` and checking tables exist

- [X] T001 Create database migration for webhooks table in priv/repo/migrations/20260225_create_webhooks.exs
- [X] T002 Create database migration for webhook_deliveries table in priv/repo/migrations/20260225_create_webhook_deliveries.exs
- [ ] T003 Run migrations to verify schema creation

---

## Phase 2: Foundational

**Goal**: Create core schemas and context module required by all user stories

**Independent Test**: Schemas and context compile and basic operations work

- [X] T004 Create Webhook schema in lib/plausible/site/webhook.ex
- [X] T005 Create WebhookDelivery schema in lib/plausible/site/webhook_delivery.ex
- [X] T006 Create Webhooks context module in lib/plausible/webhooks.ex
- [X] T007 Add basic CRUD operations to Webhooks context (create, list, get, delete)
- [ ] T008 Write unit tests for Webhooks context in test/plausible/webhooks_test.exs

---

## Phase 3: User Story 1 - Configure Webhook Endpoint (P1)

**Goal**: Allow users to create, view, and delete webhook configurations

**Independent Test**: User can create a webhook with URL and events, view list of webhooks, and delete a webhook

**Acceptance Criteria**:
- User can create webhook with valid URL and at least one event type
- User can view all webhooks for their site with status and event types
- User can delete a webhook and it stops sending notifications

**Dependencies**: Phase 2 (Foundational) must complete first

- [X] T009 [US1] Add URL validation to Webhook schema (valid HTTP/HTTPS, max 500 chars)
- [X] T010 [US1] Add events validation to Webhook schema (at least 1, valid event types)
- [X] T011 [US1] Add update operation to Webhooks context in lib/plausible/webhooks.ex
- [ ] T012 [US1] Create webhook list view in lib/plausible_web/live/webhook_settings_live.ex
- [ ] T013 [US1] Create webhook form component in lib/plausible_web/live/components/webhook_form.ex
- [ ] T014 [US1] Add webhook routes to router in lib/plausible_web/router.ex
- [ ] T015 [US1] Write integration tests for webhook CRUD in test/plausible_web/live/webhook_settings_test.exs

---

## Phase 4: User Story 2 - Receive Notifications (P1)

**Goal**: Send HTTP POST notifications when configured events occur

**Independent Test**: When a goal is completed or visitor spike detected, HTTP POST is sent to configured URL with correct payload

**Acceptance Criteria**:
- When goal completed, webhook receives payload with goal details
- When visitor spike detected, webhook receives payload with spike details
- Multiple webhooks for same event each receive notification

**Dependencies**: Phase 3 (US1) must complete first

- [X] T016 [US2] Create DeliverWebhook Oban worker in lib/workers/deliver_webhook.ex
- [X] T017 [US2] Implement HTTP POST delivery with HTTPoison in DeliverWebhook worker
- [X] T018 [US2] Implement retry logic with exponential backoff (1min, 5min, 15min)
- [X] T019 [US2] Add delivery status logging to webhook_deliveries table
- [ ] T020 [US2] Integrate goal completion trigger in lib/plausible/goals.ex
- [ ] T021 [US2] Integrate visitor spike trigger in lib/workers/traffic_change_notifier.ex
- [X] T022 [US2] Add payload builder for goal_completion events in lib/plausible/webhooks/payload_builder.ex
- [X] T023 [US2] Add payload builder for visitor_spike events in lib/plausible/webhooks/payload_builder.ex
- [ ] T024 [US2] Write tests for DeliverWebhook worker in test/workers/deliver_webhook_test.exs

---

## Phase 5: User Story 3 - Verify Webhook Configuration (P2)

**Goal**: Allow users to test webhook endpoints before activating

**Independent Test**: User can click "Send Test" and verify endpoint receives test notification

**Acceptance Criteria**:
- Test notification is sent to verify connectivity
- Clear error message shown if endpoint unreachable

**Dependencies**: Phase 4 (US2) must complete first

- [X] T025 [US3] Add test webhook action to Webhooks context in lib/plausible/webhooks.ex
- [ ] T026 [US3] Create test webhook button in webhook form component
- [ ] T027 [US3] Display success/error feedback from test in UI
- [ ] T028 [US3] Write tests for test webhook functionality

---

## Phase 6: User Story 4 - Manage Webhook Security (P2)

**Goal**: Add HMAC signature verification for webhook payloads

**Independent Test**: Payload signature can be verified using configured secret

**Acceptance Criteria**:
- Each payload includes X-Webhook-Signature header
- Updating secret maintains backward compatibility for grace period

**Dependencies**: Phase 3 (US1) must complete first

- [X] T029 [US4] Add secret field to webhook schema with validation (8-64 chars)
- [X] T030 [US4] Implement HMAC-SHA256 signature generation in lib/plausible/webhooks/signature.ex
- [X] T031 [US4] Add signature header to all webhook deliveries
- [ ] T032 [US4] Add secret rotation support with grace period in Webhooks context
- [ ] T033 [US4] Write tests for signature generation in test/plausible/webhooks/signature_test.exs

---

## Phase 7: Polish & Integration

**Goal**: Final integration, error handling, and edge cases

**Independent Test**: All user stories work together end-to-end

- [X] T034 Add auto-disable webhook after failure threshold exceeded
- [ ] T035 Add webhook delivery history view in UI
- [ ] T036 Add rate limiting for webhook requests per site
- [X] T037 Add structured logging for all webhook operations
- [ ] T038 Run full integration test suite for webhooks

---

## Dependencies Graph

```
Phase 1: Setup
    │
    ▼
Phase 2: Foundational
    │
    ├──► Phase 3: US1 (Configure Webhook)
    │           │
    │           └──► Phase 4: US2 (Notifications)
    │                       │
    │                       └──► Phase 5: US3 (Test Webhook)
    │
    └──► Phase 6: US4 (Security)
                │
                ▼
        Phase 7: Polish
```

---

## Parallel Execution Examples

### Example 1: Independent Setup Tasks
```bash
# Can run migrations and write tests in parallel
mix ecto.migrate &
mix test test/plausible/webhooks_test.exs &
```

### Example 2: Schema and Context (Phase 2)
```bash
# Can write schema and tests in parallel before integration
mix phx.gen.schema Webhook & \
mix test test/plausible/webhooks_test.exs &
```

---

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 38 |
| Setup Phase | 3 |
| Foundational Phase | 5 |
| User Story 1 (P1) | 7 |
| User Story 2 (P1) | 9 |
| User Story 3 (P2) | 4 |
| User Story 4 (P2) | 5 |
| Polish Phase | 5 |

### Suggested MVP Scope

Implement **Phases 1-4** (User Stories 1 & 2) to deliver the core value:
- Users can configure webhook endpoints
- Users receive notifications when events occur

This provides a complete, usable feature while deferring test functionality and security enhancements to a follow-up iteration.

### Independent Test Criteria

Each user story phase can be tested independently:
- **US1**: Create webhook, list webhooks, delete webhook
- **US2**: Trigger goal completion, verify HTTP POST received with correct payload
- **US3**: Click test button, verify test notification received
- **US4**: Generate signature, verify HMAC matches expected value
