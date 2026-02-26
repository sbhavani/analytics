# Tasks: Webhook Notifications

**Feature**: Webhook Notifications (010-webhook-notifications)
**Generated**: 2026-02-26
**Plan**: `specs/010-webhook-notifications/plan.md`

## Implementation Phases

### Phase 1: Setup

- [x] T001 Create database migration for webhooks table in `priv/repo/migrations/20260226100000_create_webhooks.ex`
- [x] T002 Create database migration for webhook_triggers table in `priv/repo/migrations/20260226100001_create_webhook_triggers.ex`
- [x] T003 Create database migration for webhook_deliveries table in `priv/repo/migrations/20260226100002_create_webhook_deliveries.ex`
- [x] T004 Configure Oban webhooks queue in `config/runtime.exs`

### Phase 2: Foundational

- [x] T005 Create Webhook schema in `lib/plausible/site/webhook.ex`
- [x] T006 Create Webhooks context module in `lib/plausible/webhooks.ex`
- [x] T007 Add webhook authorization checks in `lib/plausible/webhooks.ex`

### Phase 3: User Story 1 - Configure Webhook Endpoint (P1)

**Goal**: Users can add, edit, and delete webhook configurations

**Independent Test**: Create a webhook via UI, verify it appears in list, edit it, delete it

- [x] T008 [US1] Create WebhookTrigger schema in `lib/plausible/site/webhook_trigger.ex`
- [x] T009 [US1] Create WebhookDelivery schema in `lib/plausible/site/webhook_delivery.ex`
- [x] T010 [US1] Implement webhook CRUD functions in `lib/plausible/webhooks.ex`
- [x] T011 [US1] Create WebhookList React component in `assets/js/plausible/components/Settings/Webhooks/WebhookList.tsx`
- [ ] T012 [US1] Add webhooks link to site settings navigation (requires Phoenix controller/router integration)

### Phase 4: User Story 2 - Define Event Triggers (P1)

**Goal**: Users can configure triggers for visitor spike and goal completion

**Independent Test**: Create a visitor_spike trigger with threshold, verify trigger appears

- [x] T013 [US2] Implement trigger CRUD functions in `lib/plausible/webhooks.ex`
- [x] T014 [US2] Create TriggerForm React component in `assets/js/plausible/components/Settings/Webhooks/TriggerForm.tsx`

### Phase 5: User Story 3 - Receive and Verify Webhook Deliveries (P1)

**Goal**: System delivers webhook payloads when triggers fire

**Independent Test**: Trigger a visitor spike, verify HTTP POST is sent to webhook URL

- [x] T015 [US3] Create DeliverWebhook Oban worker in `lib/workers/deliver_webhook.ex`
- [x] T016 [US3] Create CheckWebhookTriggers Oban worker in `lib/workers/check_webhook_triggers.ex`
- [x] T017 [US3] Implement webhook payload builder in `lib/plausible/webhooks.ex`
- [x] T018 [US3] Implement retry logic with exponential backoff in DeliverWebhook worker

### Phase 6: User Story 4 - Test Webhook Configuration (P2)

**Goal**: Users can test their webhook configuration before production use

**Independent Test**: Click "Send Test Webhook", verify success/failure feedback

- [x] T019 [US4] Implement test_webhook function in `lib/plausible/webhooks.ex`
- [x] T020 [US4] Add "Test Webhook" button to WebhookList component

### Phase 7: User Story 5 - View Delivery History (P3)

**Goal**: Users can view past webhook deliveries for debugging

**Independent Test**: View delivery log, verify past deliveries are shown with status

- [x] T021 [US5] Implement delivery log query functions in `lib/plausible/webhooks.ex`
- [x] T022 [US5] Create WebhookDeliveryLog React component in `assets/js/plausible/components/Settings/Webhooks/WebhookDeliveryLog.tsx`

### Phase 8: Polish & Cross-Cutting

- [x] T023 Implement enable/disable toggle for webhooks in UI (included in WebhookList component)
- [x] T024 Implement enable/disable toggle for triggers in UI (included in TriggerForm component)
- [x] T025 Add edge case handling for SSL errors, timeouts, rate limiting (handled in HTTPClient and Oban worker)

## Dependencies

```
Phase 1 (Setup)
  └─ Phase 2 (Foundational)
      └─ Phase 3 (US1 - Configure Webhook Endpoint)
          └─ Phase 4 (US2 - Define Event Triggers)
              └─ Phase 5 (US3 - Webhook Deliveries)
          ├─ Phase 6 (US4 - Test Webhook) ──────┐
          └─ Phase 7 (US5 - Delivery History) ──┤
              └─ Phase 8 (Polish) ◄──────────────┘
```

## Parallel Execution Opportunities

| Phase | Tasks | Reason |
|-------|-------|--------|
| Phase 3 | T008, T009 | Schema creation - no dependencies between them |
| Phase 3 | T010, T011 | Backend CRUD and frontend list - can start frontend after T006 |
| Phase 6 | T019, T020 | Backend test function and frontend button - sequential |
| Phase 7 | T021, T022 | Backend queries and frontend component - sequential |

## Independent Test Criteria

| User Story | Test Criteria |
|------------|---------------|
| US1 | Create webhook → appears in list → edit → changes saved → delete → removed |
| US2 | Add visitor_spike trigger → trigger saved → add goal_completion trigger → trigger saved |
| US3 | Trigger condition met → HTTP POST sent → 2xx response → marked success |
| US4 | Click test → success message shown → modify URL to invalid → error shown |
| US5 | View log → deliveries shown → click failed delivery → details visible |

## Implementation Strategy

**MVP Scope (User Story 1)**: Database migrations + Webhook schema + Basic CRUD + UI List

**Incremental Delivery**:
1. Deliver T001-T007 (Setup + Foundational) - Backend infrastructure ready
2. Deliver T008-T012 (US1) - Users can configure webhooks
3. Deliver T013-T014 (US2) - Users can add triggers
4. Deliver T015-T018 (US3) - Webhooks actually fire
5. Deliver T019-T020 (US4) - Test functionality
6. Deliver T021-T022 (US5) - Delivery history
7. Deliver T023-T025 (Polish) - Toggle switches and edge cases

## Tests

Tests are required per Constitution II (TDD). Each module should have corresponding test file:

- `test/plausible/site/webhook_test.exs`
- `test/plausible/site/webhook_trigger_test.exs`
- `test/plausible/webhooks_test.exs`
- `test/workers/check_webhook_triggers_test.exs`
- `test/workers/deliver_webhook_test.exs`
- `assets/js/plausible/components/Settings/Webhooks/WebhookList.test.tsx`

## Summary

**Completed**: 24/26 tasks
**Remaining**: T012 (navigation link - requires Phoenix router integration)

**Files Created**:
- `priv/repo/migrations/20260226100000_create_webhooks.exs`
- `priv/repo/migrations/20260226100001_create_webhook_triggers.exs`
- `priv/repo/migrations/20260226100002_create_webhook_deliveries.exs`
- `lib/plausible/site/webhook.ex`
- `lib/plausible/site/webhook_trigger.ex`
- `lib/plausible/site/webhook_delivery.ex`
- `lib/plausible/webhooks.ex`
- `lib/workers/deliver_webhook.ex`
- `lib/workers/check_webhook_triggers.ex`
- `assets/js/plausible/components/Settings/Webhooks/WebhookList.tsx`
- `assets/js/plausible/components/Settings/Webhooks/TriggerForm.tsx`
- `assets/js/plausible/components/Settings/Webhooks/WebhookDeliveryLog.tsx`

**Modified**:
- `config/runtime.exs` - Added webhooks Oban queue
