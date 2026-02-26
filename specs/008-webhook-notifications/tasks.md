---

description: "Task list for webhook notifications feature implementation"
---

# Tasks: Webhook Notifications

**Input**: Design documents from `/specs/008-webhook-notifications/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), data-model.md, contracts/

**Tests**: TDD is required per Constitution - test tasks included for each user story

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Database & Infrastructure)

**Purpose**: Database schema and migrations for webhook tables

- [x] T001 Create database migration for webhooks table in priv/repo/migrations/[timestamp]_create_webhooks.exs
- [x] T002 Create database migration for webhook_events table in priv/repo/migrations/[timestamp]_create_webhook_events.exs
- [x] T003 Create database migration for webhook_delivery_logs table in priv/repo/migrations/[timestamp]_create_webhook_delivery_logs.exs
- [ ] T004 Run database migrations to create tables

---

## Phase 2: Foundational (Shared Components)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 [P] Create Webhook configuration schema in lib/plausible/site/webhook.ex
- [x] T006 [P] Create Webhook.Event schema in lib/plausible/site/webhook_event.ex
- [x] T007 [P] Create Webhook.DeliveryLog schema in lib/plausible/site/webhook_delivery_log.ex
- [x] T008 Create Webhook context module in lib/plausible/webhooks.ex with CRUD operations
- [x] T009 Create WebhookDelivery Oban worker in lib/workers/webhook_delivery.ex
- [x] T010 Add webhook signature generation helper in lib/plausible/webhook_auth.ex

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Traffic Spike Notifications (Priority: P1) 🎯 MVP

**Goal**: Users can configure webhook notifications for traffic spike events

**Independent Test**: Configure webhook with spike alerts enabled, trigger spike condition, verify HTTP POST received with correct payload

### Tests for User Story 1 (TDD) ⚠️

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [x] T011 [P] [US1] Test webhook schema validation for URL format in test/plausible/site/webhook_test.exs
- [x] T012 [P] [US1] Test spike event payload generation in test/plausible/webhooks_test.exs
- [ ] T013 [US1] Test TrafficChangeNotifier integration with webhooks in test/workers/webhook_delivery_test.exs

### Implementation for User Story 1

- [x] T014 [P] [US1] Implement spike event trigger logic in lib/plausible/webhooks.ex
- [x] T015 [P] [US1] Extend TrafficChangeNotifier to trigger webhook events in lib/workers/traffic_change_notifier.ex
- [x] T016 [US1] Implement HTTP POST delivery in WebhookDelivery worker
- [x] T017 [US1] Add HMAC signature header to webhook requests

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently

---

## Phase 4: User Story 2 - Goal Completion Notifications (Priority: P1)

**Goal**: Users receive webhook notifications when goals are completed

**Independent Test**: Create goal, configure webhook for goal events, trigger goal conversion, verify HTTP POST received

### Tests for User Story 2 (TDD) ⚠️

- [x] T018 [P] [US2] Test goal event payload generation in test/plausible/webhooks_test.exs
- [ ] T019 [US2] Test goal completion webhook trigger in test/plausible/goal_test.exs

### Implementation for User Story 2

- [x] T020 [P] [US2] Implement goal event trigger logic in lib/plausible/webhooks.ex
- [ ] T021 [US2] Add goal completion webhook trigger at analytics ingestion point
- [x] T022 [US2] Implement goal-specific payload structure per contract

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - Webhook Configuration Management (Priority: P2)

**Goal**: Users can manage webhook configurations through UI

**Independent Test**: Navigate to site settings, add/edit/delete webhooks, verify settings persist

### Tests for User Story 3 (TDD) ⚠️

- [x] T023 [P] [US3] Test webhook CRUD operations in test/plausible/webhooks_test.exs

### Implementation for User Story 3

- [x] T024 [P] [US3] Create webhook settings LiveView in lib/plausible_web/live/webhook_settings_live.ex
- [x] T025 [P] [US3] Add webhook routes in lib/plausible_web/router.ex
- [x] T026 [US3] Create webhook form components in assets/js/dashboard/settings/webhooks/
- [x] T027 [US3] Add webhook management to site settings navigation

**Checkpoint**: User Stories 1, 2, AND 3 should all work independently

---

## Phase 6: User Story 4 - Webhook Testing (Priority: P2)

**Goal**: Users can test webhook endpoint before relying on it

**Independent Test**: Configure webhook, click Test button, verify test payload received at endpoint

### Tests for User Story 4 (TDD) ⚠️

- [ ] T028 [US4] Test test webhook delivery in test/workers/webhook_delivery_test.exs

### Implementation for User Story 4

- [x] T029 [P] [US4] Implement test webhook endpoint in WebhookDelivery worker
- [x] T030 [US4] Add test webhook button to settings UI
- [x] T031 [US4] Display test result feedback in UI

**Checkpoint**: All P1 and P2 stories complete

---

## Phase 7: User Story 5 - Traffic Drop Notifications (Priority: P3)

**Goal**: Users receive webhook notifications when traffic drops below threshold

**Independent Test**: Configure webhook with drop alerts, trigger drop condition, verify notification received

### Tests for User Story 5 (TDD) ⚠️

- [x] T032 [P] [US5] Test drop event payload generation in test/plausible/webhooks_test.exs

### Implementation for User Story 5

- [x] T033 [P] [US5] Implement drop event trigger logic in lib/plausible/webhooks.ex
- [x] T034 [US5] Extend TrafficChangeNotifier drop handling for webhooks
- [x] T035 [US5] Implement drop-specific payload structure per contract

**Checkpoint**: All user stories should now be independently functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T036 [P] Implement webhook retry logic with exponential backoff
- [x] T037 [P] Add webhook delivery logging for debugging
- [x] T038 Add webhook delivery status to settings UI
- [x] T039 Security: Validate webhook URLs (no internal URLs)
- [x] T040 Performance: Add rate limiting for webhook deliveries
- [ ] T041 Run Credo and fix any issues
- [ ] T042 Run all tests and ensure passing

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3+)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (P1 → P2 → P3)
- **Polish (Final Phase)**: Depends on all desired user stories being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories, can run parallel with US1
- **User Story 3 (P2)**: Can start after Foundational (Phase 2) - UI dependencies on US1/US2 components
- **User Story 4 (P2)**: Can start after Foundational (Phase 2) - Depends on US3 for UI
- **User Story 5 (P3)**: Can start after Foundational (Phase 2) - Similar to US1 pattern

### Within Each User Story

- Tests (TDD) MUST be written and FAIL before implementation
- Models before services
- Services before endpoints
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks (T001-T004) can run in parallel
- All Foundational tasks marked [P] (T005-T007) can run in parallel
- Once Foundational phase completes, User Stories 1 and 2 can start in parallel
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel

---

## Parallel Example: User Story 1 and 2

```bash
# Launch all tests for User Story 1 together:
Task: "Test webhook schema validation in test/plausible/site/webhook_test.exs"
Task: "Test spike event payload generation in test/plausible/webhooks_test.exs"

# Launch User Story 1 implementation:
Task: "Implement spike event trigger logic in lib/plausible/webhooks.ex"

# Launch User Story 2 implementation in parallel:
Task: "Implement goal event trigger logic in lib/plausible/webhooks.ex"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T004)
2. Complete Phase 2: Foundational (T005-T010)
3. Complete Phase 3: User Story 1 (T011-T017)
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 2 → Test independently → Deploy/Demo
4. Add User Story 3 → Test independently → Deploy/Demo
5. Add User Story 4 → Test independently → Deploy/Demo
6. Add User Story 5 → Test independently → Deploy/Demo
7. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Traffic Spike)
   - Developer B: User Story 2 (Goal Completion)
   - Developer C: User Story 5 (Traffic Drop - similar to US1)
3. Stories complete and integrate independently

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- TDD: Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
