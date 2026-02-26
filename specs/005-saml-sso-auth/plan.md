# Implementation Plan: SAML 2.0 SSO Authentication

**Branch**: `005-saml-sso-auth` | **Date**: 2026-02-26 | **Spec**: [link](spec.md)
**Input**: Feature specification from `/specs/005-saml-sso-auth/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

This feature implements enterprise Single Sign-On (SSO) using SAML 2.0 protocol. It allows teams to configure their own identity providers (IdPs) and enforce SSO authentication for team members. The implementation includes:

- SAML 2.0 authentication flow with service provider (SP) and identity provider (IdP) integration
- Domain verification via DNS TXT, HTTP URL, or meta tag methods
- User provisioning/deprovisioning based on SSO identity
- Force SSO policy to enforce corporate authentication
- Session management with audit logging

## Technical Context

**Language/Version**: Elixir 1.18+ (Phoenix framework)
**Primary Dependencies**:
- `simple_saml` (SAML parsing/validation)
- `x509` (certificate handling)
- `xml_builder` (SAML request generation)
**Storage**: PostgreSQL (using Ecto for ORM)
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (Phoenix web application)
**Project Type**: Web service / SaaS platform
**Performance Goals**:
- SSO authentication: <30 seconds end-to-end
- Domain verification: <5 minutes
- User provisioning: <10 seconds
**Constraints**:
- Multi-tenant isolation (team-level)
- Rate limiting on login endpoints
- Audit logging required for all SSO operations
**Scale/Scope**:
- Multi-team support with isolated SSO configurations
- Each team can have multiple verified domains

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First Development | PASS | SSO does not collect personal data beyond authentication; IdP handles identity |
| Test-Driven Development | PASS | Existing test files in `test/plausible/auth/sso_test.exs` |
| Performance as Feature | PASS | Performance goals defined in spec (SC-001, SC-008) |
| Observability | PASS | Audit logging implemented via `Plausible.Audit.Entry` |
| Simplicity/YAGNI | PASS | Uses existing patterns; minimal abstraction |

## Project Structure

### Documentation (this feature)

```text
specs/005-saml-sso-auth/
├── plan.md              # This file
├── research.md          # Not needed - implementation already exists
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # N/A - internal API
└── tasks.md            # Phase 2 output (NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Backend - Elixir/Phoenix
extra/lib/
├── plausible/
│   └── auth/
│       └── sso/
│           ├── sso.ex                    # Main SSO context
│           ├── integration.ex            # SSO Integration schema
│           ├── saml_config.ex            # SAML configuration
│           ├── identity.ex                # SSO Identity
│           ├── domain.ex                  # SSO Domain
│           ├── domains.ex                # Domain management
│           └── domain/
│               ├── status.ex              # Domain status enum
│               ├── verification.ex        # Verification logic
│               └── verification/
│                   └── worker.ex          # Background verification worker
└── plausible_web/
    ├── controllers/
    │   └── sso_controller.ex              # SSO routes
    ├── live/
    │   └── sso_management.ex              # SSO settings UI
    └── sso/
        ├── real_saml_adapter.ex           # Real SAML implementation
        └── fake_saml_adapter.ex           # Test SAML implementation

# Database
priv/repo/migrations/
├── 20250520084130_add_sso_tables_columns.exs
├── 20250603125849_adjust_users_sso_constraints.exs
├── 20250604094230_add_unique_index_on_users_sso_identity_id.exs
├── 20250616121812_sso_domains_validation_to_verification_rename.exs
└── 20250616135937_sso_domains_validation_to_verification_rename_2.exs

# Tests
test/
├── plausible/auth/sso_test.exs
├── plausible/auth/sso/
│   ├── domain/
│   │   └── verification_test.exs
│   └── domains_test.exs
├── plausible_web/
│   ├── controllers/
│   │   ├── sso_controller_test.exs
│   │   └── sso_controller_sync_test.exs
│   └── live/
│       └── sso_management_test.exs
```

**Structure Decision**: Feature is implemented as part of the main Phoenix application in the `extra/` directory, following the existing pattern for enterprise features.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| None | N/A | N/A |

## Phase 0: Research

Since the SSO/SAML feature is already implemented in the codebase, no additional research is needed. All technical decisions have been made based on existing implementation.

## Phase 1: Design

### Data Model

Based on the existing implementation, the data model consists of:

#### SSO Integration
- `id`: Primary key
- `identifier`: UUID for the integration
- `config`: Polymorphic embed (SAML config)
- `team_id`: Foreign key to team
- `inserted_at`, `updated_at`: Timestamps

#### SSO Domain
- `id`: Primary key
- `domain`: Email domain (e.g., "company.com")
- `status`: Domain verification status (pending, in_progress, verified, unverified)
- `identifier`: Verification identifier
- `sso_integration_id`: Foreign key to SSO integration
- `inserted_at`, `updated_at`: Timestamps

#### Team Policy (extended)
- `force_sso`: Force SSO mode (:none, :all_but_owners)
- `sso_default_role`: Default role for SSO users (:viewer, :member, :admin)
- `sso_session_timeout_minutes`: Session timeout in minutes

#### User (extended)
- `type`: User type (:standard, :sso)
- `sso_integration_id`: Reference to SSO integration
- `sso_identity_id`: IdP identity identifier
- `sso_domain_id`: Reference to SSO domain
- `last_sso_login`: Timestamp of last SSO login

### Quickstart

For administrators setting up SSO:

1. Navigate to Team Settings > Single Sign-On
2. Click "Start Configuring SSO"
3. Configure IdP details:
   - SSO URL / Sign-on URL / Login URL
   - Entity ID / Issuer / Identifier
   - Signing Certificate in PEM format
4. Add email domain(s) for your team
5. Verify domain ownership using one of:
   - DNS TXT record
   - HTTP URL
   - Meta tag
6. Configure SSO policy (optional):
   - Default role for new SSO users
   - Session timeout
   - Force SSO mode

### API/Interface Contracts

Internal interfaces (not external APIs):

- `Plausible.Auth.SSO` - Main SSO context module
- `Plausible.Auth.SSO.Integration` - Integration schema
- `Plausible.Auth.SSO.SAMLConfig` - SAML configuration validation
- `Plausible.Auth.SSO.Domains` - Domain management
- `Plausible.Auth.SSO.Domain.Verification` - Domain verification
- `PlausibleWeb.SSOController` - HTTP endpoints
- `PlausibleWeb.Live.SSOManagement` - LiveView for settings
