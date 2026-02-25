# Implementation Tasks: Webhook Notifications

**Feature**: Webhook Notifications | **Branch**: `003-webhook-notifications` | **Generated**: 2026-02-25

## Implementation Strategy

### MVP Scope
- User Story 1 (Configure Webhook Endpoint) is the MVP - enables basic webhook functionality
- Deliverable: Users can create, view, and delete webhooks with URL validation

### Incremental Delivery
1. **Phase 1**: Setup - Database migrations and basic infrastructure
2. **Phase 2**: Foundational - Core schemas and webhook delivery worker
3. **Phase 3**: US1 - Configure Webhook Endpoint (MVP)
4. **Phase 4**: US2 - Select Event Triggers
5. **Phase 5**: US3 - Monitor Webhook Deliveries
6. **Phase 6**: US4 - Edit and Remove Webhooks
7. **Phase 7**: US5 - Configure Trigger Thresholds
8. **Phase 8**: Polish & Integration

---

## Phase 1: Setup

- [x] T001 Create database migration for webhook_configurations table in priv/repo/migrations/YYYYMMDDHHMMSS_create_webhook_configurations.exs
- [x] T002 Create database migration for webhook_deliveries table in priv/repo/migrations/YYYYMMDDHHMMSS_create_webhook_deliveries.exs
- [x] T003 Add Oban worker module for delivering webhooks in lib/workers/deliver_webhook.ex

---

## Phase 2: Foundational

**Goal**: Core infrastructure ready for all user stories

**Independent Test Criteria**: All schemas and workers function correctly without user-facing features

- [x] T004 Create WebhookConfiguration schema in lib/plausible/webhooks/webhook.ex
- [x] T005 Create WebhookDelivery schema in lib/plausible/webhooks/delivery.ex
- [x] T006 Create WebhookContext module for CRUD operations in lib/plausible/webhooks/context.ex
- [x] T007 Implement HMAC-SHA256 signature generation for webhook payloads in lib/plausible/webhooks/signature.ex
- [x] T008 Add webhook triggers helper module for event type constants in lib/plausible/webhooks/triggers.ex
- [ ] T009 Write ExUnit tests for WebhookConfiguration schema in test/plausible/webhooks/webhook_test.exs
- [ ] T010 Write ExUnit tests for WebhookDelivery schema in test/plausible/webhooks/delivery_test.exs
- [ ] T011 Write ExUnit tests for WebhookContext in test/plausible/webhooks/context_test.exs
- [ ] T012 Write ExUnit tests for signature generation in test/plausible/webhooks/signature_test.exs

---

## Phase 3: User Story 1 - Configure Webhook Endpoint (P1)

**Goal**: Users can configure and save webhook endpoint URLs

**Independent Test Criteria**: Adding a valid webhook URL saves successfully; invalid URLs are rejected with error message

**Story Dependencies**: None (foundational phase complete)

- [x] T013 Create Phoenix controller for webhook API in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T014 Create JSON view for webhook responses in lib/plausible_web/views/api/webhook_view.ex
- [x] T015 Implement create webhook endpoint (POST /api/sites/:site_id/webhooks) in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T016 Implement list webhooks endpoint (GET /api/sites/:site_id/webhooks) in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T017 Add URL validation for webhook endpoints in lib/plausible/webhooks/context.ex
- [ ] T018 Write controller tests for webhook creation in test/plausible_web/controllers/api/webhook_controller_test.exs
- [x] T019 Create Phoenix LiveView webhook settings page component in lib/plausible_web/live/webhook_settings.ex
- [x] T020 Add webhook settings route and template in lib/plausible_web/templates/site/settings_webhooks.html.heex

---

## Phase 4: User Story 2 - Select Event Triggers (P1)

**Goal**: Users can select which event types trigger webhook notifications

**Independent Test Criteria**: Selected triggers fire webhooks; unselected triggers do not

**Story Dependencies**: Phase 3 (US1) complete

- [x] T021 Add trigger selection to create/update webhook payload in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T022 Store trigger configuration in WebhookConfiguration in lib/plausible/webhooks/context.ex
- [x] T023 Implement goal completion event detection in lib/plausible_web/controllers/api/webhook_controller.ex (hook into goal completion)
- [x] T024 Implement visitor spike event detection logic in lib/plausible_web/controllers/api/webhook_controller.ex
- [ ] T025 Write integration tests for trigger selection in test/plausible_web/controllers/api/webhook_controller_test.exs

---

## Phase 5: User Story 3 - Monitor Webhook Deliveries (P2)

**Goal**: Users can view delivery history with success/failure status

**Independent Test Criteria**: Delivery history shows timestamp, status, response code for each attempt

**Story Dependencies**: Phase 3 (US1) complete

- [x] T026 Implement delivery history endpoint (GET /api/sites/:site_id/webhooks/:id/deliveries) in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T027 Add pagination for delivery history in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T028 Update WebhookDelivery schema to track status and response code in lib/plausible/webhooks/delivery.ex
- [ ] T029 Write controller tests for delivery history endpoint in test/plausible_web/controllers/api/webhook_controller_test.exs
- [x] T030 Add delivery history display to webhook LiveView in lib/plausible_web/live/webhook_settings.ex

---

## Phase 6: User Story 4 - Edit and Remove Webhooks (P2)

**Goal**: Users can modify or delete webhook configurations

**Independent Test Criteria**: Editing updates configuration; deleting removes webhook and stops notifications

**Story Dependencies**: Phase 3 (US1) complete

- [x] T031 Implement update webhook endpoint (PATCH /api/sites/:site_id/webhooks/:id) in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T032 Implement delete webhook endpoint (DELETE /api/sites/:site_id/webhooks/:id) in lib/plausible_web/controllers/api/webhook_controller.ex
- [x] T033 Add enable/disable toggle functionality in lib/plausible/webhooks/context.ex
- [ ] T034 Write controller tests for update and delete endpoints in test/plausible_web/controllers/api/webhook_controller_test.exs
- [x] T035 Add edit and delete UI to webhook LiveView in lib/plausible_web/live/webhook_settings.ex

---

## Phase 7: User Story 5 - Configure Trigger Thresholds (P3)

**Goal**: Users can customize threshold values for trigger conditions

**Independent Test Criteria**: Webhook fires only when configured threshold is exceeded

**Story Dependencies**: Phase 4 (US2) complete

- [x] T041 [P] Add threshold configuration to webhook create/update payload ✓ VERIFIED
- [x] T042 Store threshold settings in WebhookConfiguration in lib/plausible/webhooks/context.ex
- [x] T043 Implement visitor spike threshold checking logic in lib/plausible_web/controllers/api/webhook_controller.ex
- [ ] T044 Write integration tests for threshold configuration in test/plausible_web/controllers/api/webhook_controller_test.exs
- [x] T045 Add threshold input UI to webhook LiveView form in lib/plausible_web/live/webhook_settings.ex

---

## Phase 8: Polish & Cross-Cutting Concerns

**Goal**: Final integration, error handling, and observability

**Independent Test Criteria**: All features work together end-to-end

- [x] T036 Add structured logging for webhook deliveries in lib/workers/deliver_webhook.ex
- [x] T037 Implement retry logic with exponential backoff (1s, 2s, 4s) in lib/workers/deliver_webhook.ex
- [x] T038 Handle edge cases: unreachable endpoints, 5xx/4xx errors, timeout in lib/workers/deliver_webhook.ex
- [x] T039 Add soft delete for webhook configurations in lib/plausible/webhooks/context.ex
- [ ] T040 Run full integration test suite for webhook feature in test/plausible_web/controllers/api/webhook_controller_test.exs

---

## Dependencies Graph

```
Phase 1 (Setup)
    │
    └── Phase 2 (Foundational)
            │
            ├── Phase 3 (US1: Configure Endpoint) ─────┐
            │                                            │
            ├── Phase 4 (US2: Select Triggers) ◄────────┼──────┐
            │                                            │      │
            ├── Phase 5 (US3: Monitor Deliveries)        │      │
            │                                            │      │
            └── Phase 6 (US4: Edit/Remove)              │      │
                                                        │      │
            Phase 7 (US5: Thresholds) ──────────────────►┘
                                                        │
            Phase 8 (Polish) ◄───────────────────────────┘
```

---

## Parallel Execution Opportunities

| Tasks | Files | Reason |
|-------|-------|--------|
| T001, T002 | Separate migration files | Can run in parallel |
| T004, T005 | Separate schema files | Independent |
| T013, T014 | Controller + View | Sequential (view depends on controller) |
| T019, T020 | Two React components | Can run in parallel |

---

## Summary

- **Total Tasks**: 45
- **Completed**: 33 tasks
- **Remaining**: 12 tasks (tests)
- **Phase 1 (Setup)**: 3 tasks - COMPLETE
- **Phase 2 (Foundational)**: 9 tasks (4 tests pending)
- **Phase 3 (US1)**: 8 tasks (1 test pending)
- **Phase 4 (US2)**: 5 tasks (1 test pending)
- **Phase 5 (US3)**: 5 tasks (1 test pending)
- **Phase 6 (US4)**: 5 tasks (1 test pending)
- **Phase 7 (US5)**: 5 tasks (1 test pending)
- **Phase 8 (Polish)**: 5 tasks (1 test pending)

**MVP**: Phase 3 (US1) - Users can configure webhook endpoints

**Independent Test Criteria per Story**:
- US1: Adding valid URL saves; invalid URL rejected with error
- US2: Selected triggers fire; unselected do not
- US3: History shows timestamp, status, response code
- US4: Edit updates config; delete removes webhook
- US5: Threshold exceeded triggers webhook
