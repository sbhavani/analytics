# SSO Endpoints Contract

**Feature**: SSO/SAML Authentication
**Date**: 2026-02-25

## Public Endpoints (No Authentication Required)

### GET /sso/login
Display SSO login form (if SSO is enabled).

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| return_to | string | No | URL to redirect after successful login |
| prefer | string | No | Preferred login method |

**Response**: HTML page

---

### POST /sso/login
Submit email for SSO authentication.

**Form Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| email | string | Yes | User's email address |
| return_to | string | No | URL to redirect after successful login |

**Response**: 302 Redirect to IdP or error

**Errors**:
- 302: Redirect to SSO login form with error

---

### GET /sso/saml/signin/:integration_id
Initiate SAML authentication with specific IdP.

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| integration_id | string | Yes | SSO Integration identifier |

**Query Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| email | string | No | User's email (login hint) |
| return_to | string | No | URL to redirect after successful login |

**Response**: 302 Redirect to IdP

---

### POST /sso/saml/consume/:integration_id
Consume SAML assertion from IdP.

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| integration_id | string | Yes | SSO Integration identifier |

**Form Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| SAMLResponse | string | Yes | Base64-encoded SAML response |
| RelayState | string | Yes | Relay state from AuthRequest |

**Response**: 302 Redirect to dashboard or error

**Errors**:
- Invalid signature
- Expired assertion
- Invalid assertion conditions

---

## Authenticated Endpoints (Admin Only)

### GET /sso/settings
Display SSO configuration settings (team owner only).

**Access**: Requires team owner role

**Response**: HTML page with:
- List of configured IdPs
- IdP configuration form
- Domain management

---

### POST /sso/integration
Create new SSO integration.

**Access**: Requires team owner role

**Form Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| idp_entity_id | string | Yes | IdP entity ID |
| idp_signin_url | string | Yes | IdP SSO URL |
| idp_cert_pem | text | Yes | IdP certificate (PEM) |

**Response**: 302 Redirect to settings

---

### GET /sso/team-sessions
List active SSO sessions for team.

**Access**: Requires team admin role

**Response**: HTML page with list of sessions

---

### DELETE /sso/sessions/:session_id
Revoke an SSO session.

**Access**: Requires team admin role

**Path Parameters**:
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| session_id | string | Yes | Session ID |

**Response**: 302 Redirect to sessions page

---

## SP Metadata

### GET /sso/saml/metadata
Return Service Provider metadata XML.

**Response**: XML (application/xml)

Contains:
- Entity ID
- ACS URL
- SLO URL (if enabled)
- Supported bindings

---

## Internal API

### Domain Lookup
Used internally to find IdP for user's email domain.

**Logic**:
1. Extract domain from email
2. Look up domain in SSO domains table
3. Return associated integration

**Flow**:
```
User enters email -> /sso/login POST ->
  SSO.Domains.lookup(email) ->
    Return integration -> Redirect to /sso/saml/signin/:id
```
