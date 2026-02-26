# Data Model: SAML 2.0 SSO Authentication

## Overview

This document describes the data model for the SSO/SAML authentication feature. The model is implemented using Ecto schemas in Elixir.

## Entities

### SSO Integration

Represents the SAML configuration for a team.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `identifier` | UUID | Unique identifier for the integration (used in SAML metadata) |
| `config` | Polymorphic Embed | SAML configuration (idp_signin_url, idp_entity_id, idp_cert_pem) |
| `team_id` | UUID | Foreign key to team |
| `inserted_at` | Timestamp | Creation timestamp |
| `updated_at` | Timestamp | Last update timestamp |

**Relationships**:
- Belongs to: Team
- Has many: SSO Domains
- Has many: Users

### SSO Domain

Represents an email domain authorized for SSO with verification status.

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Primary key |
| `domain` | String | Email domain (e.g., "company.com") |
| `status` | Enum | Domain status: `:pending`, `:in_progress`, `:verified`, `:unverified` |
| `identifier` | String | Verification identifier for DNS/meta tag verification |
| `sso_integration_id` | UUID | Foreign key to SSO integration |
| `inserted_at` | Timestamp | Creation timestamp |
| `updated_at` | Timestamp | Last update timestamp |

**Relationships**:
- Belongs to: SSO Integration

### SSO Identity

Represents the link between a user and their IdP identity (extracted from SAML assertion).

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | SAML NameID from IdP |
| `integration_id` | UUID | SSO Integration identifier |
| `name` | String | User's name from IdP attributes |
| `email` | String | User's email from IdP attributes |
| `expires_at` | Timestamp | When this identity assertion expires |

### Team Policy (extended for SSO)

Contains SSO-specific settings at the team level.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `force_sso` | Enum | `:none` | Force SSO mode: `:none` or `:all_but_owners` |
| `sso_default_role` | Enum | `:viewer` | Default role for new SSO users |
| `sso_session_timeout_minutes` | Integer | 480 (8 hours) | Session timeout for SSO users |

### User (extended for SSO)

The User entity is extended with SSO-specific fields.

| Field | Type | Description |
|-------|------|-------------|
| `type` | Enum | User type: `:standard` or `:sso` |
| `sso_integration_id` | UUID (nullable) | Reference to SSO integration |
| `sso_identity_id` | String (nullable) | IdP identity identifier (SAML NameID) |
| `sso_domain_id` | UUID (nullable) | Reference to SSO domain |
| `last_sso_login` | Timestamp (nullable) | Last SSO login timestamp |

## State Transitions

### SSO Domain Status

```
pending → in_progress → verified
                 ↓
               unverified
```

- **pending**: Domain added but verification not started
- **in_progress**: Verification process ongoing
- **verified**: Domain ownership confirmed
- **unverified**: Verification failed or cancelled

### User Type

```
standard → sso (via SSO login with matching domain)
sso → standard (via deprovisioning)
```

## Validation Rules

### SAML Config
- `idp_signin_url`: Must be valid HTTPS URL
- `idp_entity_id`: Must not be blank
- `idp_cert_pem`: Must be valid PEM-encoded certificate

### SSO Domain
- `domain`: Must be valid domain format (e.g., "company.com")
- Must be unique within the integration

### Team Policy
- `sso_session_timeout_minutes`: Must be positive integer
- `sso_default_role`: Must be valid member role
- `force_sso`: Must be `:none` or `:all_but_owners`

## Database Migrations

Key migrations for this feature:

1. `20250520084130_add_sso_tables_columns.exs` - Adds SSO tables and user columns
2. `20250603125849_adjust_users_sso_constraints.exs` - Adjusts constraints
3. `20250604094230_add_unique_index_on_users_sso_identity_id.exs` - Adds unique index
4. `20250616121812_sso_domains_validation_to_verification_rename.exs` - Renames validation to verification
5. `20250616135937_sso_domains_validation_to_verification_rename_2.exs` - Continues rename
