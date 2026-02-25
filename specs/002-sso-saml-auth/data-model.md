# Data Model: SSO/SAML Authentication

**Feature**: SSO/SAML Authentication
**Date**: 2026-02-25

## Entities

### SSO Integration

Represents a SAML Identity Provider configuration for a team.

| Field | Type | Constraints | Description |
|-------|------|------------|-------------|
| `id` | UUID | Primary Key | Unique identifier |
| `team_id` | UUID | Foreign Key, Required | Team owning this integration |
| `identifier` | String | Unique, Required | Public identifier for the integration |
| `config` | Embedded Struct | Required | SAML configuration |
| `created_at` | DateTime | Required | Creation timestamp |
| `updated_at` | DateTime | Required | Last update timestamp |

**SAMLConfig Embedded Struct**:
| Field | Type | Constraints | Description |
|-------|------|------------|-------------|
| `idp_entity_id` | String | Required | IdP's entity ID |
| `idp_signin_url` | String | Required | IdP's SSO URL |
| `idp_cert_pem` | Text | Required | IdP's X.509 certificate (PEM) |

### SSO Identity

Represents a user's SSO identity from a SAML assertion.

| Field | Type | Constraints | Description |
|-------|------|------------|-------------|
| `id` | String | Primary Key | NameID from SAML assertion |
| `integration_id` | UUID | Foreign Key, Required | Link to SSO Integration |
| `email` | String | Required | User's email address |
| `name` | String | Optional | User's display name |
| `expires_at` | DateTime | Optional | Identity expiry time |
| `inserted_at` | DateTime | Required | Creation timestamp |
| `updated_at` | DateTime | Required | Last update timestamp |

### SSO Domain

Represents a domain associated with an SSO integration for email domain-based routing.

| Field | Type | Constraints | Description |
|-------|------|------------|-------------|
| `id` | UUID | Primary Key | Unique identifier |
| `integration_id` | UUID | Foreign Key, Required | Link to SSO Integration |
| `domain` | String | Required | Email domain (e.g., "example.com") |
| `verification_code` | String | Required | Domain ownership verification |
| `verified_at` | DateTime | Optional | When domain was verified |
| `status` | Enum | Required | Domain status (pending, verified, failed) |
| `inserted_at` | DateTime | Required | Creation timestamp |
| `updated_at` | DateTime | Required | Last update timestamp |

### User Schema Extension

Existing `Auth.User` table extended with SSO fields:

| Field | Type | Constraints | Description |
|-------|------|------------|-------------|
| `type` | Enum | Required | User type (standard, sso) |
| `sso_identity_id` | String | Optional | Link to SSO Identity |
| `sso_integration_id` | UUID | Optional | Link to SSO Integration |
| `sso_domain_id` | UUID | Optional | Link to SSO Domain |

## Relationships

```
Team (1) ─────< SSO Integration (1) ─────< SSO Identity (M)
                     │
                     └────< SSO Domain (M)

User ───────────< SSO Identity (M)
User ───────────< SSO Integration (1, optional)
User ───────────< SSO Domain (1, optional)
```

## Validation Rules

1. **SSO Integration**
   - `identifier`: Must be unique, alphanumeric with hyphens
   - `idp_entity_id`: Must be valid URI or URN
   - `idp_signin_url`: Must be valid HTTPS URL
   - `idp_cert_pem`: Must be valid X.509 certificate PEM format

2. **SSO Domain**
   - `domain`: Must be valid domain format (no protocol, no path)
   - `domain`: Must be unique across all integrations

3. **SSO Identity**
   - `email`: Must be valid email format
   - `expires_at`: Must be in the future when set

## State Transitions

### SSO Domain Status

```
pending -> verified    (via domain verification)
pending -> failed     (verification timeout or failure)
verified -> pending   (re-verification triggered)
```

## Indexes

| Table | Index Fields | Purpose |
|-------|--------------|---------|
| `sso_integrations` | team_id | Query by team |
| `sso_identities` | integration_id, email | Query by integration |
| `sso_domains` | domain (unique) | Domain lookup |

## Migrations Required

1. `create_sso_integrations` - Create SSO integrations table
2. `create_sso_identities` - Create SSO identities table
3. `create_sso_domains` - Create SSO domains table
4. `alter_users_add_sso_fields` - Add SSO fields to users table

---

**Note**: This data model is derived from the existing implementation in `extra/lib/plausible/auth/sso/`.
