# Quickstart: SSO/SAML Authentication

## Overview

Enterprise SSO/SAML authentication is already implemented in Plausible Analytics. This guide helps enterprise customers set up SAML-based single sign-on.

## Prerequisites

- Plausible Analytics Enterprise subscription
- Admin access to your Plausible team
- Access to your Identity Provider (IdP) admin console
- Valid SSL certificate on your Plausible instance

## Supported Identity Providers

The following IdPs are known to work with Plausible:

- **Okta**
- **Microsoft Azure AD**
- **OneLogin**
- **Google Workspace**
- **Any SAML 2.0 compliant IdP**

## Setup Steps

### 1. Access SSO Settings

1. Log in to Plausible as a team owner or admin
2. Navigate to **Team Settings** → **Single Sign-On**

### 2. Configure Identity Provider

Enter your IdP details:

| Field | Description | Where to Find |
|-------|-------------|---------------|
| IdP Entity ID | Unique identifier for your IdP | IdP admin console |
| IdP SSO URL | URL where users are redirected to log in | IdP admin console |
| IdP Certificate | X.509 certificate for signature verification | IdP admin console (download as PEM) |

**Tip**: Most IdPs provide metadata XML that contains all these values. You can paste the metadata XML instead of entering fields individually.

### 3. Configure Service Provider

Your Plausible instance acts as a Service Provider (SP). Share these details with your IdP admin:

- **SP Entity ID**: `https://your-plausible-domain.com/sso/{integration-id}`
- **SP ACS URL**: `https://your-plausible-domain.com/sso/saml/consume/{integration-id}`

### 4. Configure Attribute Mapping

Map SAML attributes to Plausible user fields:

| SAML Attribute | Plausible Field | Required |
|---------------|-----------------|----------|
| email | Email address | Yes |
| first_name | First name | No |
| last_name | Last name | No |

### 5. Test Configuration

Use the "Test Configuration" button in the settings to verify your setup before enabling SSO.

### 6. Enable SSO

Once testing is successful, enable SSO for your team. You can choose:

- **Optional SSO**: Users can choose to use SSO or regular login
- **Required SSO**: All team members must use SSO

## Domain-Based SSO

You can configure SSO for specific email domains:

1. In SSO settings, go to **Domains**
2. Add your email domain (e.g., `example.com`)
3. Verify domain ownership via DNS TXT record
4. Users with emails ending in `@example.com` will be automatically routed to SSO

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| "Invalid signature" | Ensure IdP certificate is correct and not expired |
| "Session expired" | Check clock sync on both IdP and Plausible servers |
| "User not found" | Verify email attribute mapping in IdP configuration |
| "Certificate expired" | Update IdP certificate in Plausible settings |

### Debug Mode

Enable debug logging in `config/runtime.exs`:

```elixir
config :logger, level: :debug
```

## Security Considerations

1. **Certificate Expiration**: Monitor IdP certificate expiration dates
2. **Session Timeout**: Configure appropriate session length in team policy
3. **Access Audit**: Review SSO login events in audit logs

## Next Steps

- Review [SSO Documentation](https://plausible.io/docs/sso)
- Contact enterprise support for specialized IdP setup help
