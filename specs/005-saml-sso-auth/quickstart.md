# Quickstart: SAML 2.0 SSO Configuration

This guide helps team administrators set up SAML 2.0 SSO for their organization.

## Prerequisites

- Team owner or admin access
- An identity provider (IdP) that supports SAML 2.0
- Ability to configure DNS records for your email domain
- Optional: 2FA enabled on owner accounts (required for Force SSO)

## Setup Steps

### Step 1: Access SSO Settings

1. Log in as a team owner
2. Navigate to **Team Settings** > **Single Sign-On**
3. Click **Start Configuring SSO**

### Step 2: Configure Identity Provider

Your IdP will need the following Service Provider (SP) metadata:

| Parameter | Value |
|-----------|-------|
| **ACS URL** | `https://your-instance.com/sso/consume/:integration-id` |
| **Entity ID** | `https://your-instance.com/sso/:integration-id` |

**Attribute Mappings** required at your IdP:
- `email` - User's email address
- `first_name` - User's first name
- `last_name` - User's last name

### Step 3: Enter IdP Configuration

In the SSO settings page, enter:

- **SSO URL / Sign-on URL / Login URL**: Your IdP's login endpoint
- **Entity ID / Issuer / Identifier**: Your IdP's entity identifier
- **Signing Certificate**: Your IdP's X.509 certificate in PEM format

Click **Save** to store the configuration.

### Step 4: Add Email Domain

1. In the SSO settings, click **Add Domain**
2. Enter your email domain (e.g., `company.com`)
3. Click **Add Domain**

### Step 5: Verify Domain Ownership

Choose one verification method:

**Option A: DNS TXT Record**
```
Add a TXT record to your domain:
Name: @ or plausible-sso-verification
Value: plausible-sso-verification=<identifier>
```

**Option B: HTTP URL**
```
Publish a file at:
https://<your-domain>/plausible-sso-verification
Content: <identifier>
```

**Option C: Meta Tag**
```
Add to your domain's homepage:
<meta name="plausible-sso-verification" content="<identifier>">
```

Once verification succeeds, you'll receive an email confirmation.

### Step 6: Configure SSO Policy (Optional)

In the SSO Policy section:

- **Default role**: Choose the role for new SSO users (Viewer, Member, or Admin)
- **Session timeout**: Set how long SSO sessions remain active (default: 8 hours)
- **Force SSO**: Enable to require all non-owners to use SSO authentication

### Step 7: Test SSO

1. Open an incognito browser window
2. Go to the login page
3. Enter an email from your verified domain
4. You should be redirected to your IdP
5. After authentication, you should be logged in

## Managing SSO

### Viewing SSO Sessions

1. Go to **Team Settings** > **SSO Sessions**
2. View all active SSO sessions with user info and login times

### Revoking a Session

1. In the sessions list, click **Revoke** next to the session
2. Confirm the action
3. The user will be logged out and must re-authenticate

### Removing a Domain

1. Go to **Team Settings** > **Single Sign-On**
2. Find the domain in the list
3. Click **Remove**
4. Confirm the action (users from this domain will no longer be able to use SSO)

## Troubleshooting

### Verification Not Working

- Check that DNS changes have propagated (may take up to 48 hours)
- Verify the TXT record matches exactly
- Use the "Run Verification Now" button to retry

### Login Failures

- Ensure your IdP certificate is valid and not expired
- Check that attribute mappings are correct
- Verify the email domain is verified

### Force SSO Won't Enable

- Ensure you have a verified domain
- Ensure all team owners have 2FA enabled
- At least one SSO user must have logged in successfully

## Security Considerations

- Keep your IdP certificate up to date
- Enable Force SSO for enterprise security compliance
- Regularly review active SSO sessions
- Use 2FA on all owner accounts
