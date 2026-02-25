# Implementation Plan: [FEATURE]

**Branch**: `[###-feature-name]` | **Date**: [DATE] | **Spec**: [link]
**Input**: Feature specification from `/specs/[###-feature-name]/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/plan-template.md` for the execution workflow.

## Summary

**Primary Requirement**: Add support for enterprise single sign-on (SSO) with SAML 2.0 identity providers, enabling enterprise users to authenticate using their corporate credentials.

**Technical Approach**: The project already contains a comprehensive SSO implementation in the `extra/` directory using the `simple_saml` library. This implementation provides full SAML 2.0 Web Browser SSO Profile support including SP-initiated and IdP-initiated login, HTTP-POST binding, signature validation, and attribute mapping. The feature will integrate this existing implementation into the main codebase, requiring database migrations, routing updates, and UI integration.

## Technical Context

**Language/Version**: Elixir 1.18+ (Phoenix framework)
**Primary Dependencies**: Phoenix, Ecto, PostgreSQL, React/TypeScript frontend
**Storage**: PostgreSQL for transactional data
**Testing**: ExUnit (Elixir), Jest (JavaScript)
**Target Platform**: Linux server (web application)
**Project Type**: web-service (Phoenix-based SaaS analytics platform)
**Performance Goals**: Per spec - 10,000+ users, <30s auth, 95% success rate
**Constraints**: Privacy-first (per constitution), must maintain existing auth flow
**Scale/Scope**: Multi-tenant SaaS with enterprise customers

**Technical Implementation Notes**:
- SAML 2.0 Web Browser SSO Profile (SP-initiated and IdP-initiated)
- HTTP-POST binding for SAML assertions
- Need to select SAML library for Elixir (research required)
- Integrate with existing Phoenix authentication system
- Session management via existing user session mechanism

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Privacy Impact Assessment
- [x] **PRIVACY-001**: No personal data beyond what's in SAML assertion (email, name, department)
- [x] **PRIVACY-002**: User data stays within existing data handling policies
- [x] **PRIVACY-003**: No additional data collection beyond authentication needs

### Test Requirements
- [x] **TEST-001**: Unit tests for SAML validation logic
- [x] **TEST-002**: Integration tests for full authentication flow
- [x] **TEST-003**: Contract tests for API boundaries

### Security Requirements
- [x] **SEC-001**: SAML signature validation required
- [x] **SEC-002**: Certificate expiry checking
- [x] **SEC-003**: Audit logging for all auth events (per FR-012)

### Observability
- [x] **OBS-001**: Structured logging for SSO auth events
- [x] **OBS-002**: Error tracking with SAML-specific context
- [x] **OBS-003**: Metrics for SSO login success/failure rates

**Gate Status**: PASS (all requirements align with constitution)

## Project Structure

### Documentation (this feature)

```text
specs/002-sso-saml-auth/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
lib/
├── plausible/
│   ├── auth/                    # Existing auth context
│   │   ├── auth.ex              # Main auth functions
│   │   ├── user.ex              # User schema
│   │   └── user_sessions.ex     # Session management
│   └── [other contexts]
└── plausible_web/
    ├── controllers/
    │   └── auth_controller.ex   # Auth web controllers
    ├── plugs/
    │   └── auth_plug.ex         # Auth plugs
    └── views/

test/plausible/
└── auth/                        # Auth tests

priv/repo/migrations/            # Database migrations
```

**Structure Decision**: Add SAML support in existing `Plausible.Auth` context with new modules:
- `lib/plausible/auth/saml_idp.ex` - IdP configuration schema
- `lib/plausible/auth/saml.ex` - SAML authentication logic
- `lib/plausible_web/controllers/saml_controller.ex` - SAML endpoints
- Tests in `test/plausible/auth/`

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
