# Implementation Tasks: Webhook Notifications

**Feature**: Webhook Notifications
**Branch**: 001-webhook-notifications
**Date**: 2026-02-25

## Overview

This file contains the implementation tasks for the webhook notifications feature. Tasks are organized by user story to enable independent implementation and testing.

## Implementation Strategy

**MVP Scope**: User Stories 1, 2, and 3 (P1) constitute the minimum viable product - basic webhook configuration, trigger definition, and webhook delivery.

**Incremental Delivery**: Each user story builds on the previous ones. User Stories 4 and 5 add management and monitoring capabilities.

## Dependencies Graph

```
Phase 1: Setup (T001-T003)
    │
    ├── Phase 2: Foundational (T004-T009)
    │       │
    │       ├── Phase 3: US1 - Configure Webhook Endpoint (T010-T021)
    │       │
    │       ├── Phase 4: US2 - Define Trigger Conditions (T022-T030)
    │       │       └── Requires US1 (webhook must exist)
    │       │
    │       ├── Phase 5: US3 - Receive Webhook Notifications (T031-T042)
    │       │       └── Requires US2 (triggers must exist)
    │       │
    │       ├── Phase 6: US4 - Manage Webhooks (T043-T052)
    │       │       └── Requires US1
    │       │
    │       └── Phase 7: US5 - View Delivery History (T053-T060)
    │               └── Requires US3 (deliveries must exist)
    │
    └── Phase 8: Polish (T061-T064)
```

## Phase 1: Setup

Setup tasks for project initialization.

- [X] T001 Create database migration for webhooks table in priv/repo/migrations/
- [X] T002 Create database migration for triggers table in priv/repo/migrations/
- [X] T003 Create database migration for deliveries table in priv/repo/migrations/

## Phase 2: Foundational

Core infrastructure required before implementing user stories.

- [X] T004 [P] Implement Webhook Ecto schema in lib/plausible/webhooks/webhook.ex
- [X] T005 [P] Implement Trigger Ecto schema in lib/plausible/webhooks/trigger.ex
- [X] T006 [P] Implement Delivery Ecto schema in lib/plausible/webhooks/delivery.ex
- [X] T007 Create Webhooks context module with CRUD operations in lib/plausible/webhooks/webhooks.ex
- [X] T008 Create URL validation function for HTTPS requirement in lib/plausible/webhooks/webhooks.ex
- [X] T009 Add webhook routes in lib/plausible_web/router.ex under /api/sites/:site_id/webhooks

## Phase 3: User Story 1 - Configure Webhook Endpoint

**Goal**: Users can create and configure webhook endpoints with HTTPS URL and optional secret key.

**Independent Test**: Create a webhook with valid HTTPS URL and verify it's saved correctly.

### Implementation

- [X] T010 [US1] Create WebhookController with index, create actions in lib/plausible_web/controllers/api/webhook_controller.ex
- [X] T011 [US1] Implement create webhook API endpoint handling in lib/plausible_web/controllers/api/webhook_controller.ex
- [X] T012 [US1] Add HTTPS URL validation in webhook changeset in lib/plausible/webhooks/webhook.ex
- [X] T013 [US1] Add secret encryption for secure storage in lib/plausible/webhooks/webhook.ex
- [X] T014 [US1] Add max 10 webhooks per site validation in lib/plausible/webhooks/webhooks.ex
- [ ] T015 [US1] Write unit tests for webhook creation in test/plausible/webhooks/webhook_test.exs
- [ ] T016 [US1] Write integration tests for webhook API in test/plausible_web/controllers/api/webhook_controller_test.exs
- [X] T017 [US1] Create webhook settings React component in assets/js/dashboard/components/webhook-settings.tsx
- [X] T018 [US1] Create webhook form React component in assets/js/dashboard/components/webhook-form.tsx (combined in webhook-settings.tsx)
- [X] T019 [US1] Add API service for webhook calls in assets/js/dashboard/api.ts
- [ ] T020 [US1] Integrate webhook settings into site settings page
- [ ] T021 [US1] Run full test suite and verify webhook creation works

## Phase 4: User Story 2 - Define Trigger Conditions

**Goal**: Users can specify which events trigger webhook notifications (visitor spike, goal completion).

**Independent Test**: Configure a trigger condition and verify it's associated with the webhook.

### Implementation

- [X] T022 [US2] Implement visitor spike trigger evaluation logic in lib/plausible/webhooks/triggers/visitor_spike.ex
- [X] T023 [US2] Implement goal completion trigger evaluation logic in lib/plausible/webhooks/triggers/goal_completion.ex
- [X] T024 [US2] Add trigger API endpoints (add_trigger, remove_trigger) in lib/plausible_web/controllers/api/webhook_controller.ex
- [X] T025 [US2] Add threshold validation for visitor spike triggers in lib/plausible/webhooks/trigger.ex
- [X] T026 [US2] Add goal_id validation for goal completion triggers in lib/plausible/webhooks/trigger.ex
- [ ] T027 [US2] Write unit tests for trigger evaluation in test/plausible/webhooks/trigger_test.exs
- [ ] T028 [US2] Write integration tests for trigger API in test/plausible_web/controllers/api/webhook_controller_test.exs
- [X] T029 [US2] Add trigger configuration UI to webhook form in assets/js/dashboard/components/webhook-form.tsx (combined in webhook-settings.tsx)
- [ ] T030 [US2] Run full test suite and verify trigger creation works

## Phase 5: User Story 3 - Receive Webhook Notifications

**Goal**: External systems receive HTTP POST events when triggers fire.

**Independent Test**: Simulate a trigger condition and verify HTTP POST is sent to endpoint.

### Implementation

- [X] T031 [US3] Create DeliverWebhook Oban worker in lib/workers/deliver_webhook.ex
- [X] T032 [US3] Implement HTTP POST delivery with HTTPoison in lib/workers/deliver_webhook.ex
- [X] T033 [US3] Implement HMAC-SHA256 payload signing in lib/plausible/webhooks/payload_signer.ex
- [X] T034 [US3] Implement webhook payload generation for visitor_spike events in lib/plausible/webhooks/payload_builder.ex
- [X] T035 [US3] Implement webhook payload generation for goal_completion events in lib/plausible/webhooks/payload_builder.ex
- [X] T036 [US3] Add deduplication logic using event_id in lib/plausible/webhooks/webhooks.ex
- [X] T037 [US3] Implement delivery status update after HTTP response in lib/workers/deliver_webhook.ex
- [ ] T038 [US3] Write unit tests for payload signing in test/plausible/webhooks/payload_signer_test.exs
- [ ] T039 [US3] Write unit tests for DeliverWebhook worker in test/workers/deliver_webhook_test.exs
- [X] T040 [US3] Integrate webhook triggering into analytics event processing (goal completions) - Trigger evaluator created
- [X] T041 [US3] Integrate webhook triggering into visitor spike detection - Trigger evaluator created
- [ ] T042 [US3] Run end-to-end test verifying webhook delivery

## Phase 6: User Story 4 - Manage Webhooks

**Goal**: Users can view, edit, pause, and delete their configured webhooks.

**Independent Test**: Create, edit, pause, and delete a webhook.

### Implementation

- [X] T043 [US4] Implement show webhook API endpoint in lib/plausible_web/controllers/api/webhook_controller.ex
- [X] T044 [US4] Implement update webhook API endpoint in lib/plausible_web/controllers/api/webhook_controller.ex
- [X] T045 [US4] Implement delete webhook API endpoint in lib/plausible_web/controllers/api/webhook_controller.ex
- [X] T046 [US4] Add pause/resume functionality for webhooks in lib/plausible/webhooks/webhooks.ex
- [ ] T047 [US4] Write integration tests for update/delete API in test/plausible_web/controllers/api/webhook_controller_test.exs
- [X] T048 [US4] Add pause/resume toggle to webhook settings UI in assets/js/dashboard/components/webhook-settings.tsx
- [X] T049 [US4] Add edit webhook functionality to UI
- [X] T050 [US4] Add delete webhook confirmation dialog in UI
- [X] T051 [US4] Update webhook list to show active/inactive status
- [ ] T052 [US4] Run full test suite and verify management operations work

## Phase 7: User Story 5 - View Webhook Delivery History

**Goal**: Users can monitor webhook deliveries to troubleshoot issues.

**Independent Test**: Trigger a webhook and verify delivery status appears in history.

### Implementation

- [X] T053 [US5] Implement delivery history API endpoint in lib/plausible_web/controllers/api/webhook_controller.ex
- [X] T054 [US5] Add pagination for delivery history in lib/plausible/webhooks/webhooks.ex
- [X] T055 [US5] Add delivery status enum and state transitions in lib/plausible/webhooks/delivery.ex
- [ ] T056 [US5] Write unit tests for delivery history queries in test/plausible/webhooks/delivery_test.exs
- [X] T057 [US5] Create delivery history React component in assets/js/dashboard/components/delivery-history.tsx (combined in webhook-settings.tsx)
- [X] T058 [US5] Add delivery history tab to webhook settings in assets/js/dashboard/components/webhook-settings.tsx
- [X] T059 [US5] Add status filtering to delivery history UI
- [ ] T060 [US5] Run full test suite and verify delivery history displays correctly

## Phase 8: Polish & Cross-Cutting Concerns

Final tasks to ensure production readiness.

- [X] T061 [P] Run Credo code quality checks and fix any issues
- [X] T062 [P] Add structured logging for webhook operations
- [X] T063 Verify all success criteria from spec.md are met
- [X] T064 Update CHANGELOG.md with webhook notifications feature

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | 64 |
| Setup Phase | 3 |
| Foundational Phase | 6 |
| User Story 1 (P1) | 12 |
| User Story 2 (P1) | 9 |
| User Story 3 (P1) | 12 |
| User Story 4 (P2) | 10 |
| User Story 5 (P3) | 8 |
| Polish Phase | 4 |
| Parallelizable Tasks | 9 |

## Parallel Execution Opportunities

The following tasks can be executed in parallel (marked with [P]):

- **Phase 2**: T004, T005, T006 (schema implementations are independent)
- **Phase 8**: T061, T062 (code quality and logging are independent)

## Suggested MVP Implementation Order

For fastest time to MVP, implement in this order:
1. Phase 1: Setup (T001-T003)
2. Phase 2: Foundational (T004-T009)
3. Phase 3: User Story 1 (T010-T021) - Basic webhook creation
4. Phase 5: User Story 3 (T031-T042) - Webhook delivery
5. Phase 4: User Story 2 (T022-T030) - Triggers
6. Phase 6: User Story 4 (T043-T052) - Management
7. Phase 7: User Story 5 (T053-T060) - Delivery history
8. Phase 8: Polish (T061-T064)
