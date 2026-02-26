# Implementation Plan: SSO/SAML Authentication

**Branch**: `004-saml-sso-auth` | **Date**: 2026-02-26 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/004-saml-sso-auth/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

Enterprise SSO/SAML authentication is **already implemented** in the Plausible Analytics codebase. The implementation includes SAML 2.0 configuration, SP-initiated SSO login, Just-In-Time user provisioning, account linking, domain-based SSO routing, session management, and audit logging. The feature is located in the `extra/` directory, indicating it's an Enterprise Edition (EE) feature.

## Technical Context

**Language/Version**: Elixir 1.15+, Phoenix Framework
**Primary Dependencies**: SimpleSaml, X509, Ecto, PostgreSQL
**Storage**: PostgreSQL for SSO configurations and identities
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (self-hosted) or cloud (plausible.io)
**Project Type**: Web application (Elixir/Phoenix backend + React frontend)
**Performance Goals**: <5s SSO login completion, 95% success rate
**Constraints**: EE-only feature, requires valid SSL certificate
**Scale/Scope**: Multi-tenant enterprise deployments

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| Privacy-First (Principle I) | PASS | No personal data collection, SAML only processes email/name for auth |
| Test-Driven (Principle II) | PASS | Existing tests in `test/plausible/auth/sso_test.exs` |
| Performance (Principle III) | PASS | SSO is redirect-based, no heavy processing |
| Observability (Principle IV) | PASS | Audit logging for SSO events implemented |
| Simplicity (Principle V) | PASS | Uses existing auth patterns, no over-engineering |

**Post-Phase 1 Re-evaluation**: Confirmed - all gates still pass. Feature is already implemented.

## Project Structure

### Documentation (this feature)

```text
specs/004-saml-sso-auth/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (N/A - internal feature)
└── tasks.md             # Phase 2 output (NOT NEEDED - feature already implemented)
```

### Source Code (existing structure)

```text
# Enterprise Edition SSO implementation
extra/lib/plausible/auth/sso/
├── integration.ex       # SSO integration model (team-level config)
├── saml_config.ex       # SAML configuration schema
├── domain.ex            # SSO domain model
├── domains.ex           # Domain lookup logic
├── identity.ex          # SSO identity model
└── domain/
    ├── status.ex        # Domain verification status
    └── verification.ex  # Domain verification logic

extra/lib/plausible_web/
├── controllers/sso_controller.ex    # SSO endpoints
├── live/sso_management.ex           # SSO settings UI
├── sso/
│   ├── real_saml_adapter.ex        # Production SAML handler
│   └── fake_saml_adapter.ex        # Test SAML handler
└── templates/sso/                 # SSO templates
```

**Structure Decision**: The SSO feature is already fully implemented in the `extra/` directory (Enterprise Edition). No new code structure is needed.
