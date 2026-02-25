# Tasks: Webhook Notifications

**Feature**: Webhook Notifications | **Branch**: `004-webhook-notifications` | **Generated**: 2026-02-25
**Spec**: [spec.md](spec.md) | **Plan**: [plan.md](plan.md)

## Implementation Strategy

**MVP Scope**: User Story 1 (Configure Webhook Endpoint) - This delivers foundational value as users cannot receive any notifications without first configuring a webhook.

**Incremental Delivery**: Each user story phase is independently testable and delivers incremental value:
- US1: Core webhook CRUD
- US2: Actual notification delivery
- US3: Trigger configuration
- US4: Edit/delete lifecycle
- US5: Testing/troubleshooting

## Dependencies

```
US1 (P1): Configure Webhook Endpoint
  └─ US2 (P1): Receive Notifications (depends on: US1 - needs webhook to exist)
     ├─ US3 (P2): Select Triggers (depends on: US2 - needs delivery logic)
     ├─ US4 (P3): Manage Configs (depends on: US1 - needs CRUD foundation)
     └─ US5 (P3): Test Webhook (depends on: US1 - needs webhook to test)
```

**Parallel Opportunities**:
- US3, US4, US5 can run in parallel after US1 completes (all depend only on having a webhook)

## Phase 1: Setup

- [x] T001 Create database migration for webhooks table in priv/repo/migrations/20260225100000_create_webhooks.exs
- [x] T002 Create database migration for webhook_triggers table in priv/repo/migrations/20260225100001_create_webhook_triggers.exs
- [x] T003 Create database migration for webhook_deliveries table in priv/repo/migrations/20260225100002_create_webhook_deliveries.exs

## Phase 2: Foundational

- [x] T004 Create Webhook schema in lib/plausible/site/webhook.ex
- [x] T005 Create WebhookTrigger schema in lib/plausible/site/webhook_trigger.ex
- [x] T006 Create WebhookDelivery schema in lib/plausible/site/webhook_delivery.ex
- [x] T007 Create Webhook context module in lib/plausible/webhook.ex with CRUD functions

## Phase 3: User Story 1 - Configure Webhook Endpoint (P1)

**Goal**: Allow users to create and list webhook configurations for their sites

**Independent Test**: Create webhook with test URL, verify it saves and appears in list

### Implementation

- [x] T008 [US1] Add webhook actions to site controller in lib/plausible_web/controllers/site_controller.ex
- [x] T009 [US1] Create webhook HTML template in lib/plausible_web/templates/site/settings_webhooks.html.heex
- [x] T010 [US1] Add webhook routes in lib/plausible_web/router.ex
- [x] T011 [US1] Create webhook context functions for site binding in lib/plausible/webhook.ex

### Acceptance Criteria

- User can enter valid HTTPS URL and save webhook
- User sees existing webhooks in list
- Invalid URL shows error message

## Phase 4: User Story 2 - Receive Notifications on Trigger Events (P1)

**Goal**: Send HTTP POST when triggers fire (goal completion, visitor spike)

**Independent Test**: Trigger an event and verify HTTP POST sent with correct payload

### Implementation

- [x] T012 [US2] Create DeliverWebhook Oban worker in lib/workers/deliver_webhook.ex
- [x] T013 [US2] Implement HTTP delivery with Req in lib/workers/deliver_webhook.ex
- [x] T014 [US2] Add HMAC-SHA256 signature generation in lib/plausible/webhook.ex
- [x] T015 [US2] Create goal completion trigger integration in lib/plausible/webhook.ex
- [x] T016 [US2] Create visitor spike trigger integration extending existing TrafficChangeNotifier in lib/workers/traffic_change_notifier.ex

### Acceptance Criteria

- Goal completion sends HTTP POST with payload per contract
- Visitor spike sends HTTP POST with payload per contract
- Disabled webhooks do not send notifications

## Phase 5: User Story 3 - Select and Configure Triggers (P2)

**Goal**: Allow users to enable/disable individual trigger types per webhook

**Independent Test**: Enable specific triggers, verify only those fire

### Implementation

- [x] T017 [US3] Add trigger management UI to webhook form in lib/plausible_web/templates/site/settings_webhooks.html.heex
- [x] T018 [US3] Add trigger update actions to site controller in lib/plausible_web/controllers/site_controller.ex
- [x] T019 [US3] Implement trigger threshold configuration in lib/plausible/site/webhook_trigger.ex

### Acceptance Criteria

- Users can view available triggers (goal_completion, visitor_spike)
- Users can enable/disable individual triggers
- Multiple enabled triggers each fire independently

## Phase 6: User Story 4 - Manage Webhook Configurations (P3)

**Goal**: Edit and delete webhook configurations

**Independent Test**: Edit webhook URL, verify change; delete webhook, verify removal

### Implementation

- [x] T020 [US4] Add webhook edit/update actions to site controller in lib/plausible_web/controllers/site_controller.ex
- [x] T021 [US4] Add webhook delete action to site controller in lib/plausible_web/controllers/site_controller.ex
- [x] T022 [US4] Implement soft delete with archival in lib/plausible/webhook.ex

### Acceptance Criteria

- Edit webhook URL and save works
- Delete webhook removes from list
- No further notifications sent after deletion

## Phase 7: User Story 5 - Test Webhook Delivery (P3)

**Goal**: Send test notification to verify endpoint connectivity

**Independent Test**: Click "Send Test", verify test payload arrives

### Implementation

- [x] T023 [US5] Add test webhook action to site controller in lib/plausible_web/controllers/site_controller.ex
- [x] T024 [US5] Implement test event payload generation in lib/plausible/webhook.ex
- [x] T025 [US5] Add test button to webhook UI in lib/plausible_web/templates/site/settings_webhooks.html.heex

### Acceptance Criteria

- Test webhook sends with test event type
- Unreachable endpoints show clear error

## Phase 8: Polish & Cross-Cutting Concerns

- [x] T026 Add delivery log UI to view webhook history in lib/plausible_web/templates/site/settings_webhooks.html.heex
- [x] T027 Implement retry logic with exponential backoff (3 retries: 1s, 2s, 4s) in lib/workers/deliver_webhook.ex
- [x] T028 Add webhook delivery rate limiting in lib/plausible/webhook.ex
- [x] T029 Implement redirect handling (max 3 hops) in lib/workers/deliver_webhook.ex

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 29 |
| Setup Tasks | 3 |
| Foundational Tasks | 4 |
| User Story 1 (P1) | 4 |
| User Story 2 (P1) | 5 |
| User Story 3 (P2) | 3 |
| User Story 4 (P3) | 3 |
| User Story 5 (P3) | 3 |
| Polish Phase | 4 |

**MVP (US1 only)**: Tasks T001-T011 (11 tasks) - Core webhook creation and listing

**Parallel Execution**: After US1, US3/US4/US5 can run in parallel (different aspects of the feature)
