# Research: SSO/SAML Authentication Implementation

**Date**: 2026-02-25
**Feature**: SSO/SAML Authentication for Plausible Analytics
**Status**: Complete

## Executive Summary

The project already has a comprehensive SSO/SAML implementation in the `extra/` directory (enterprise feature). This implementation uses the `simple_saml` library and provides full SAML 2.0 Web Browser SSO Profile support. The feature specification focuses on integrating this into the main codebase and ensuring all requirements from the spec are met.

## Existing Implementation Analysis

### Technology Stack

| Component | Technology | Version |
|-----------|------------|---------|
| SAML Library | `simple_saml` | ~> 1.2 |
| Certificate Handling | `x509` | (OTP built-in) |
| Framework | Phoenix | (existing) |
| Database | PostgreSQL | (existing) |

### Current Architecture

```
extra/lib/plausible/auth/sso/
├── sso.ex                    # Main SSO context
├── integration.ex            # Integration schema
├── saml_config.ex            # SAML configuration
├── identity.ex               # SSO identity
└── domain/
    ├── domain.ex             # SSO domain
    ├── status.ex             # Domain status
    └── verification.ex      # Domain verification

extra/lib/plausible_web/sso/
├── real_saml_adapter.ex      # Real SAML implementation
├── fake_saml_adapter.ex      # Test SAML implementation
└── saml_signin.html.heex     # SAML login UI
```

### SAML Features Implemented

1. **SP-initiated SSO** - User starts from login page
2. **IdP-initiated SSO** - IdP sends unsolicited response
3. **HTTP-POST binding** - SAML assertions via POST
4. **Signature validation** - X.509 certificate validation
5. **Attribute extraction** - Email, firstName, lastName
6. **Session management** - Configurable session timeout
7. **Audit logging** - Success/failure events

## Integration Requirements

### What Exists (extra/)
- SAML authentication flow
- Integration management
- Domain verification
- Fake SAML adapter for testing

### What Needs Integration

1. **Move SSO modules from `extra/` to `lib/`**
   - `extra/lib/plausible/auth/sso/` → `lib/plausible/auth/sso/`
   - `extra/lib/plausible_web/sso/` → `lib/plausible_web/sso/`

2. **Database migrations**
   - Create `sso_integrations` table
   - Create `sso_identities` table
   - Create `sso_domains` table

3. **UI Integration**
   - Add SSO button to login page
   - Add SSO settings management UI

4. **Feature Flag**
   - Add enterprise/EE feature flag for SSO

## Decision: Library Selection

**Decision**: Use existing `simple_saml` library (~> 1.2)

**Rationale**:
- Already integrated in codebase
- Supports SAML 2.0 Web Browser SSO Profile
- Handles XML parsing, signature validation, and attribute extraction
- Well-tested with existing test suite

**Alternatives Considered**:
- `saml2` - More recent but less documentation
- Custom implementation - Rejected due to security complexity

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Certificate expiry | High | Automated expiry checking in integration UI |
| IdP unavailable | Medium | Clear error message, fallback to password auth |
| Malformed assertions | High | Robust validation, secure parsing |
| Session hijacking | Critical | Signature validation required |

## Next Steps

1. Create database migrations for SSO tables
2. Move SSO modules from `extra/` to main codebase
3. Add SSO routes to main router
4. Create UI components for SSO management
5. Add tests for full coverage

---

**Researcher**: Claude (AI Assistant)
**Sources**: Codebase analysis, existing test suite, library documentation
