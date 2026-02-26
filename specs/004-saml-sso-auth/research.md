# Research: SSO/SAML Authentication

## Executive Summary

The SSO/SAML authentication feature is **already substantially implemented** in the Plausible Analytics codebase. The feature exists in the `extra/` directory, indicating it's an Enterprise Edition (EE) feature.

## Existing Implementation

### Backend Components

| Component | Location | Status |
|-----------|----------|--------|
| SSO Integration Model | `extra/lib/plausible/auth/sso/integration.ex` | Implemented |
| SAML Config | `extra/lib/plausible/auth/sso/saml_config.ex` | Implemented |
| SSO Domain | `extra/lib/plausible/auth/sso/domain.ex` | Implemented |
| SSO Identity | `extra/lib_plausible/auth/sso/identity.ex` | Implemented |
| SSO Domains | `extra/lib/plausible/auth/sso/domains.ex` | Implemented |
| SSO Main Module | `extra/lib/plausible/auth/sso.ex` | Implemented |

### Web Controllers & Views

| Component | Location | Status |
|-----------|----------|--------|
| SSO Controller | `extra/lib/plausible_web/controllers/sso_controller.ex` | Implemented |
| Real SAML Adapter | `extra/lib/plausible_web/sso/real_saml_adapter.ex` | Implemented |
| Fake SAML Adapter | `extra/lib/plausible_web/sso/fake_saml_adapter.ex` | Implemented |
| SSO Management LiveView | `extra/lib/plausible_web/live/sso_management.ex` | Implemented |
| SSO Settings Template | `extra/lib/plausible_web/templates/sso/sso_settings.html.heex` | Implemented |

### User Model Integration

The User schema already includes SSO-related fields:
- `type` (`:standard` or `:sso`)
- `sso_identity_id`
- `last_sso_login`
- `sso_integration` association
- `sso_domain` association

### Key Features Already Implemented

1. **SAML Configuration**: IdP entity ID, SSO URL, certificate management
2. **SAML Authentication Flow**: SP-initiated SSO login
3. **Just-In-Time Provisioning**: Automatic user creation from SAML assertions
4. **Account Linking**: Match users by email address
5. **Domain-based SSO**: SSO domains for email-based routing
6. **Session Management**: SSO session timeouts
7. **Force SSO**: Option to require SSO for team members
8. **Audit Logging**: SAML authentication events logged

## Technical Details

### SAML Protocol

- Uses SAML 2.0
- Supports SP-initiated SSO
- HTTP-POST binding for SAML Response
- DEFLATE compression for SAML Request
- X.509 certificates for signature verification

### Dependencies

- `SimpleSaml` - SAML parsing and validation
- `X509` - Certificate handling

### Routes

```
/sso/login              - SSO login form
/sso/login              - POST SSO login
/sso/saml/:idp_id      - SAML sign-in redirect
/sso/saml/:idp_id/consume - SAML response consumer
/sso/info               - SSO settings page
/sso/general            - SSO general settings
/sso/sessions           - Team SSO sessions
/sso/notice             - Provision notice
/sso/issue              - Provision issue page
```

## What the Spec Describes

The feature specification (`spec.md`) accurately describes the already-implemented functionality:

- **User Story 1** (Admin configures SAML): Covered by SSO Management LiveView
- **User Story 2** (User authenticates via SSO): Covered by SSO Controller + SAML Adapter
- **User Story 3** (Admin manages SSO users): Covered by team sessions management

## Conclusion

The SSO/SAML authentication feature is complete and ready for use. No further implementation is required - the feature matches the specification exactly.

## Recommendations

1. **Testing**: Ensure SSO works with common IdPs (Okta, Azure AD, OneLogin)
2. **Documentation**: Update user-facing docs with IdP-specific guides
3. **Monitoring**: Ensure SAML authentication events are properly logged
