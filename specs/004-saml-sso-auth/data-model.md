# Data Model: SSO/SAML Authentication

## Overview

This document describes the existing data models for the SSO/SAML authentication feature. These models are already implemented in the codebase.

## Entities

### 1. SSO Integration (`sso_integrations` table)

Represents a SAML SSO configuration for a team.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| identifier | UUID | Unique, not null | Public identifier for IdP configuration |
| config | Polymorphic | Embedded | SAML configuration (type: `:saml`) |
| team_id | Integer | Foreign Key | Reference to team |
| inserted_at | DateTime | Not Null | Creation timestamp |
| updated_at | DateTime | Not Null | Last update timestamp |

**Relationships**:
- Belongs to `Team`
- Has many `Users` via `sso_integration_id`
- Has many `SSODomains` via `sso_integration_id`

### 2. SAML Config (Embedded)

Embedded within SSO Integration.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| idp_signin_url | String | Required, Valid URL | IdP SSO URL |
| idp_entity_id | String | Required | IdP Entity ID |
| idp_cert_pem | String | Required, Valid PEM | IdP signing certificate |
| idp_metadata | String | Optional | Raw IdP metadata XML |

**Validation Rules**:
- `idp_signin_url` must be a valid HTTPS URL
- `idp_cert_pem` must be a valid X.509 certificate in PEM format

### 3. SSO Domain (`sso_domains` table)

Maps email domains to SSO integrations for automatic routing.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | UUID | Primary Key | Unique identifier |
| domain | String | Unique, not null | Email domain (e.g., "example.com") |
| verification_code | String | Not null | DNS TXT record code for verification |
| verified_at | DateTime | Nullable | When domain was verified |
| sso_integration_id | UUID | Foreign Key | Reference to SSO integration |
| inserted_at | DateTime | Not Null | Creation timestamp |
| updated_at | DateTime | Not Null | Last update timestamp |

**Relationships**:
- Belongs to `SSOIntegration`
- Has many `SSODomainStatuses`

### 4. SSO Identity (`sso_identities` table)

Represents a user's SSO identity.

| Field | Type | Constraints | Description |
|-------|------|-------------|-------------|
| id | String | Primary Key | NameID from SAML assertion |
| email | String | Not null | User's email address |
| name | String | Nullable | User's display name |
| integration_id | UUID | Foreign Key | Reference to SSO integration |
| expires_at | DateTime | Not null | When this identity expires |
| inserted_at | DateTime | Not Null | Creation timestamp |
| updated_at | DateTime | Not Null | Last update timestamp |

**Relationships**:
- Belongs to `SSOIntegration`

### 5. User (Extended)

The User schema includes SSO-related fields.

| Field | Type | Description |
|-------|------|-------------|
| type | Enum (`:standard`, `:sso`) | User authentication type |
| sso_identity_id | String | Reference to SSO identity |
| last_sso_login | DateTime | Last SSO login timestamp |
| sso_integration_id | UUID | Linked SSO integration |
| sso_domain_id | UUID | Linked SSO domain |

**Relationships**:
- Belongs to `SSOIntegration` (optional)
- Belongs to `SSODomain` (optional)

## State Transitions

### SSO Integration States

```
[No SSO] -> [SSO Configured] -> [SSO Enabled]
     |              |                  |
     v              v                  v
  Initial     Domain Setup      Active/Managed
```

### SSO Domain States

```
[Pending] -> [Verifying] -> [Verified] -> [Active]
   |            |              |            |
   v            v              v            v
 DNS Setup   Challenge    Verified     Working
```

## Indexes

- `sso_integrations.identifier` (unique)
- `sso_integrations.team_id` (unique)
- `sso_domains.domain` (unique)
- `sso_domains.sso_integration_id`
- `sso_identities.integration_id`
- `sso_identities.email`

## Security Considerations

1. **Certificate Validation**: IdP certificates are validated on save
2. **Signature Verification**: SAML responses are verified using IdP certificate
3. **Session Expiry**: SSO sessions have configurable timeout
4. **Audit Logging**: All SSO events are logged to audit trail
