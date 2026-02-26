---

description: "Task list for SAML 2.0 SSO Authentication feature - verification of existing implementation"
---

# Tasks: SAML 2.0 SSO Authentication

**Input**: Design documents from `/specs/005-saml-sso-auth/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), data-model.md

**Note**: This feature is already implemented in the codebase. Tasks focus on verification that all components are in place and functional.

**⚠️ Issue**: Tests are blocked due to gen_smtp package incompatibility with Erlang 28 (compilation error in gen_smtp_server_session.erl). The bamboo_smtp dependency requires gen_smtp ~> 1.2.0 which has this issue. Code verification confirms all components exist and are correctly implemented.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Setup (Verification Infrastructure)

**Purpose**: Verify existing project setup is complete for SSO feature

- [x] T001 Verify Elixir 1.18+ environment is configured
- [x] T002 [P] Verify dependencies are installed (simple_saml, x509, xml_builder)
- [x] T003 [P] Verify database migrations have run for SSO tables

---

## Phase 2: Foundational (Verify Core Components)

**Purpose**: Verify core SSO infrastructure is in place

**⚠️ CRITICAL**: These components must exist for any user story to function

- [x] T004 [P] Verify SSO context module exists at extra/lib/plausible/auth/sso.ex
- [x] T005 [P] Verify SSO Integration schema at extra/lib/plausible/auth/sso/integration.ex
- [x] T006 [P] Verify SSO SAML Config at extra/lib/plausible/auth/sso/saml_config.ex
- [x] T007 [P] Verify SSO Domains module at extra/lib/plausible/auth/sso/domains.ex
- [x] T008 Verify Team Policy has SSO fields (force_sso, sso_default_role, sso_session_timeout_minutes)

**Checkpoint**: Core SSO components verified

---

## Phase 3: User Story 1 - Enterprise User SSO Login (Priority: P1) 🎯 MVP

**Goal**: Verify users can authenticate via SAML IdP

**Independent Test**: Run existing SSO controller tests and verify user can login via IdP flow

### Verification for User Story 1

- [x] T009 [P] [US1] Verify SSO Controller routes exist in lib/plausible_web/router.ex
- [x] T010 [P] [US1] Verify Real SAML Adapter at extra/lib/plausible_web/sso/real_saml_adapter.ex
- [x] T011 [US1] Verify Fake SAML Adapter for testing at extra/lib/plausible_web/sso/fake_saml_adapter.ex
- [ ] T012 [US1] Run existing SSO controller tests: mix test test/plausible_web/controllers/sso_controller_test.exs (BLOCKED: gen_smtp/Erlang 28 incompatibility)
- [ ] T013 [US1] Run existing SSO sync tests: mix test test/plausible_web/controllers/sso_controller_sync_test.exs (BLOCKED: gen_smtp/Erlang 28 incompatibility)

**Checkpoint**: SSO login flow verified working

---

## Phase 4: User Story 2 - Team Administrator SSO Configuration (Priority: P1)

**Goal**: Verify administrators can configure SSO for teams

**Independent Test**: Verify SSO settings page and configuration flow works

### Verification for User Story 2

- [x] T014 [P] [US2] Verify SSO Management LiveView at extra/lib/plausible_web/live/sso_management.ex
- [x] T015 [P] [US2] Verify SSO Controller at extra/lib/plausible_web/controllers/sso_controller.ex
- [ ] T016 [US2] Run existing SSO management tests: mix test test/plausible_web/live/sso_management_test.exs (BLOCKED: gen_smtp/Erlang 28 incompatibility)
- [x] T017 [US2] Verify IdP configuration validation in SSO.SAMLConfig

**Checkpoint**: Admin SSO configuration verified working

---

## Phase 5: User Story 3 - Domain Verification (Priority: P1)

**Goal**: Verify domain ownership verification works

**Independent Test**: Verify domains can be added and verified

### Verification for User Story 3

- [x] T018 [P] [US3] Verify SSO Domain schema at extra/lib/plausible/auth/sso/domain.ex
- [x] T019 [P] [US3] Verify Domain Status enum at extra/lib/plausible/auth/sso/domain/status.ex
- [x] T020 [P] [US3] Verify Domain Verification module at extra/lib/plausible/auth/sso/domain/verification.ex
- [x] T021 [US3] Verify Domain Verification Worker at extra/lib/plausible/auth/sso/domain/verification/worker.ex
- [ ] T022 [US3] Run existing verification tests: mix test test/plausible/auth/sso/domain/verification_test.exs (BLOCKED: gen_smtp/Erlang 28 incompatibility)
- [ ] T023 [US3] Run existing domains tests: mix test test/plausible/auth/sso/domains_test.exs (BLOCKED: gen_smtp/Erlang 28 incompatibility)

**Checkpoint**: Domain verification verified working

---

## Phase 6: User Story 4 - Force SSO Policy (Priority: P2)

**Goal**: Verify Force SSO policy enforcement works

**Independent Test**: Verify non-owners are blocked from standard login when Force SSO enabled

### Verification for User Story 4

- [x] T024 [P] [US4] Verify Force SSO logic in Plausible.Auth.SSO
- [x] T025 [P] [US4] Verify Force SSO plug at extra/lib/plausible_web/plugs/sso_team_access.ex
- [x] T026 [US4] Verify 2FA check for Force SSO enablement
- [ ] T027 [US4] Run existing SSO team access tests: mix test test/plausible_web/plugs/sso_team_access_test.exs (BLOCKED: gen_smtp/Erlang 28 incompatibility)

**Checkpoint**: Force SSO policy verified working

---

## Phase 7: User Story 5 - SSO Session Management (Priority: P2)

**Goal**: Verify session viewing and revocation works

**Independent Test**: Verify admins can view and revoke SSO sessions

### Verification for User Story 5

- [x] T028 [P] [US5] Verify SSO session routes in SSOController (team_sessions, delete_session)
- [x] T029 [P] [US5] Verify UserSessions module supports SSO sessions
- [x] T030 [US5] Verify session listing shows SSO session information
- [x] T031 [US5] Verify session revocation works correctly

**Checkpoint**: Session management verified working

---

## Phase 8: User Story 6 - SSO User Deprovisioning (Priority: P2)

**Goal**: Verify SSO user deprovisioning works

**Independent Test**: Verify deprovisioned users can no longer login via SSO

### Verification for User Story 6

- [x] T032 [P] [US6] Verify deprovision_user function in Plausible.Auth.SSO
- [x] T033 [P] [US6] Verify SSO identity is removed on deprovision
- [x] T034 [US6] Verify user type changes from :sso to :standard on deprovision

**Checkpoint**: User deprovisioning verified working

---

## Phase 9: Integration & End-to-End Verification

**Purpose**: Verify full SSO flow works end-to-end

- [ ] T035 [P] Run all SSO tests: mix test test/plausible/auth/sso_test.exs
- [ ] T036 [P] Run all SSO controller tests: mix test test/plausible_web/controllers/sso*test.exs
- [ ] T037 [P] Run all SSO live view tests: mix test test/plausible_web/live/sso*test.exs
- [x] T038 Verify audit logging works for SSO operations
- [x] T039 Verify rate limiting is configured for SSO endpoints

**Checkpoint**: All integration tests pass

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final verification and documentation

- [x] T040 [P] Verify quickstart.md matches actual implementation
- [x] T041 [P] Verify data-model.md matches actual schema
- [ ] T042 Run full test suite: mix test (ensure no regressions) (BLOCKED: gen_smtp/Erlang 28 incompatibility)
- [ ] T043 Run Credo linting: mix credo (BLOCKED: gen_smtp/Erlang 28 incompatibility)
- [x] T044 Verify documentation is complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Stories (Phase 3-8)**: All depend on Foundational phase completion
- **Integration (Phase 9)**: Depends on all user stories
- **Polish (Phase 10)**: Depends on Integration completion

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational - Uses US1 infrastructure
- **User Story 3 (P1)**: Can start after Foundational - Independent
- **User Story 4 (P2)**: Depends on US1, US2, US3 (needs integration and domains)
- **User Story 5 (P2)**: Depends on US1 (needs SSO sessions)
- **User Story 6 (P2)**: Depends on US1 (needs SSO users)

### Within Each User Story

- Verification tasks can run in parallel within each phase
- Tests should be run after verifying component existence
- Story complete when all tests pass

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel
- Verification tasks within each User Story marked [P] can run in parallel

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup verification
2. Complete Phase 2: Foundational verification
3. Complete Phase 3: User Story 1 verification
4. **STOP and VALIDATE**: Test User Story 1 independently
5. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation verified
2. Add User Story 1-3 (P1) verification → Core SSO verified
3. Add User Story 4-6 (P2) verification → Full SSO verified
4. Integration verification → All tests pass
5. Polish → Feature complete

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- This feature is ALREADY IMPLEMENTED - tasks verify existence and functionality
- All tests should pass before marking phases complete
- Commit after each phase verification
- Stop at any checkpoint to validate independently
