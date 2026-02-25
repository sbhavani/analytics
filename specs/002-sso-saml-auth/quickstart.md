# Quickstart: SSO/SAML Authentication

**Feature**: SSO/SAML Authentication
**Date**: 2026-02-25

## Overview

This guide helps IT administrators configure SAML SSO for Plausible Analytics.

## Prerequisites

- Plausible Analytics instance deployed
- Admin access to Plausible
- SAML 2.0 Identity Provider (IdP) with:
  - Entity ID
  - SSO URL
  - X.509 certificate

## Step 1: Access SSO Settings

1. Log in as team owner
2. Navigate to **Settings** > **SSO**
3. Click **Configure SAML**

## Step 2: Configure IdP

Enter your IdP details:

| Field | Description | Example |
|-------|-------------|---------|
| IdP Entity ID | Your IdP's unique identifier | `https://idp.example.com` |
| IdP SSO URL | URL for SSO requests | `https://idp.example.com/sso` |
| IdP Certificate | X.509 certificate (PEM format) | Paste PEM content |

## Step 3: Configure Attribute Mapping

Map SAML attributes to Plausible fields:

| SAML Attribute | Plausible Field | Required |
|----------------|-----------------|----------|
| email | Email | Yes |
| firstName | First Name | No |
| lastName | Last Name | No |

## Step 4: Add Domain

1. Enter your email domain (e.g., `example.com`)
2. Copy the verification code
3. Add TXT record to your DNS
4. Click **Verify Domain**

## Step 5: Test Connection

1. Click **Test SSO**
2. You'll be redirected to your IdP
3. Authenticate with your corporate credentials
4. Return to Plausible

## Step 6: Enable SSO

Once testing is successful:
1. Toggle **Enable SSO** to ON
2. Users with your domain can now use SSO

## Troubleshooting

### "Invalid Certificate"
- Ensure certificate is in PEM format
- Check certificate hasn't expired

### "Authentication Failed"
- Verify IdP entity ID matches exactly
- Check SAML response signing is enabled

### "Domain Not Verified"
- Wait up to 24 hours for DNS propagation
- Verify TXT record is correct

## Security Considerations

- Certificate expiry: Set calendar reminder 30 days before expiry
- Session timeout: Configure per your organization's policy
- Audit logs: Review login events regularly
