# Azure CLI Setup Guide

This guide explains how to configure Azure AD and Microsoft Graph API permissions for beeper-teams-bridge using the Azure CLI. This is especially useful in automated environments, CI/CD pipelines, and for AI coding agents.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Authentication](#authentication)
4. [Creating Azure AD Application](#creating-azure-ad-application)
5. [Configuring Permissions](#configuring-permissions)
6. [Managing Redirect URIs](#managing-redirect-uris)
7. [Getting Application Details](#getting-application-details)
8. [Troubleshooting](#troubleshooting)
9. [Complete Setup Script](#complete-setup-script)

---

## Prerequisites

- Azure subscription or Microsoft 365 account
- Permissions to create Azure AD applications
- Azure CLI installed (pre-installed in Codespaces)

---

## Installation

### In Codespaces/DevContainer
Azure CLI is pre-installed! Verify with:
```bash
az --version
```

### On Your Local Machine

#### macOS
```bash
brew install azure-cli
```

#### Linux
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### Windows
```powershell
winget install Microsoft.AzureCLI
```

Or download from: https://aka.ms/installazurecliwindows

---

## Authentication

### Interactive Login

The recommended method for initial setup:

```bash
# Login with your Microsoft account
az login

# If you have multiple tenants, specify one
az login --tenant YOUR_TENANT_ID

# For device code flow (useful for SSH/remote sessions)
az login --use-device-code
```

After running `az login`, a browser window will open for authentication. Once authenticated, your credentials are stored locally.

### Service Principal Login

For automation and CI/CD:

```bash
az login --service-principal \
  --username APP_ID \
  --password PASSWORD_OR_CERT \
  --tenant TENANT_ID
```

### Verify Authentication

```bash
# Show current account
az account show

# List all accounts
az account list

# Set default subscription (if you have multiple)
az account set --subscription "SUBSCRIPTION_NAME_OR_ID"
```

---

## Creating Azure AD Application

### Basic Application Creation

```bash
# Create a new Azure AD application
az ad app create \
  --display-name "Beeper Teams Bridge" \
  --sign-in-audience "AzureADandPersonalMicrosoftAccount"
```

This returns JSON with application details. Save the `appId` value.

### With Redirect URI

```bash
# Create application with redirect URI for local development
az ad app create \
  --display-name "Beeper Teams Bridge" \
  --sign-in-audience "AzureADandPersonalMicrosoftAccount" \
  --web-redirect-uris "http://localhost:29319/oauth/callback"

# For production, use your public URL
az ad app create \
  --display-name "Beeper Teams Bridge Production" \
  --sign-in-audience "AzureADandPersonalMicrosoftAccount" \
  --web-redirect-uris "https://your-domain.com/oauth/callback"
```

### Capture Application ID

```bash
# Create and capture the app ID
APP_ID=$(az ad app create \
  --display-name "Beeper Teams Bridge" \
  --sign-in-audience "AzureADandPersonalMicrosoftAccount" \
  --web-redirect-uris "http://localhost:29319/oauth/callback" \
  --query appId -o tsv)

echo "Application ID: $APP_ID"
```

---

## Configuring Permissions

The bridge requires these Microsoft Graph API delegated permissions:

### Required Permissions

- `Chat.ReadWrite` - Read and write user chat messages
- `ChannelMessage.Read.All` - Read all channel messages
- `ChannelMessage.Send` - Send channel messages
- `Team.ReadBasic.All` - Read basic team information
- `User.Read` - Sign in and read user profile

### Adding Permissions via CLI

```bash
# Set your application ID
APP_ID="YOUR_APP_ID_HERE"

# Microsoft Graph API ID
GRAPH_API_ID="00000003-0000-0000-c000-000000000000"

# Add Chat.ReadWrite permission
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions 9ff7295e-131b-4d94-90e1-69fde507ac11=Scope

# Add ChannelMessage.Read.All permission
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions 7b2449af-6ccd-4f4d-9f78-e550c193f0d1=Scope

# Add ChannelMessage.Send permission
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions ebf0f66e-9fb1-49e4-a278-222f76911cf4=Scope

# Add Team.ReadBasic.All permission
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions 2280dda6-0bfd-44ee-a2f4-cb867cfc4c1e=Scope

# Add User.Read permission
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
```

### Grant Admin Consent

If you're an administrator, you can grant consent for all users:

```bash
# Grant admin consent for all permissions
az ad app permission admin-consent --id $APP_ID
```

**Note:** If you're not an admin, you'll need to ask your tenant administrator to run this command or grant consent via the Azure Portal.

### Permission IDs Reference

Here's a table of the permission IDs used above:

| Permission | Type | ID |
|------------|------|-----|
| Chat.ReadWrite | Delegated | 9ff7295e-131b-4d94-90e1-69fde507ac11 |
| ChannelMessage.Read.All | Delegated | 7b2449af-6ccd-4f4d-9f78-e550c193f0d1 |
| ChannelMessage.Send | Delegated | ebf0f66e-9fb1-49e4-a278-222f76911cf4 |
| Team.ReadBasic.All | Delegated | 2280dda6-0bfd-44ee-a2f4-cb867cfc4c1e |
| User.Read | Delegated | e1fe6dd8-ba31-4d61-89e7-88639da4683d |

---

## Managing Redirect URIs

### Add Redirect URI

```bash
# Add a redirect URI to existing app
az ad app update \
  --id $APP_ID \
  --web-redirect-uris \
    "http://localhost:29319/oauth/callback" \
    "https://your-production-domain.com/oauth/callback"
```

### List Current Redirect URIs

```bash
# Show current redirect URIs
az ad app show --id $APP_ID \
  --query "web.redirectUris" -o table
```

### Enable Public Client Flow (for mobile/desktop apps)

```bash
az ad app update \
  --id $APP_ID \
  --enable-public-client true
```

---

## Getting Application Details

### Show Application Information

```bash
# Show full app details
az ad app show --id $APP_ID

# Show just the app ID and display name
az ad app show --id $APP_ID \
  --query "{appId:appId, displayName:displayName}" -o table

# Get tenant ID
az account show --query tenantId -o tsv
```

### Export Configuration for Bridge

```bash
# Get values needed for config.yaml
APP_ID=$(az ad app show --id $APP_ID --query appId -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Add these to your config.yaml:"
echo ""
echo "network:"
echo "  azure_app_id: \"$APP_ID\""
echo "  azure_tenant_id: \"$TENANT_ID\""
echo "  azure_redirect_uri: \"http://localhost:29319/oauth/callback\""
```

---

## Troubleshooting

### Permission Already Exists Error

```bash
# List existing permissions
az ad app permission list --id $APP_ID

# Remove a permission before re-adding
az ad app permission delete \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --permission-id PERMISSION_ID
```

### Finding Permission IDs

```bash
# List all Microsoft Graph permissions
az ad sp show --id $GRAPH_API_ID \
  --query "oauth2PermissionScopes[].{Name:value, ID:id}" -o table

# Search for specific permission
az ad sp show --id $GRAPH_API_ID \
  --query "oauth2PermissionScopes[?value=='Chat.ReadWrite']" -o json
```

### Checking Consent Status

```bash
# Check if admin consent has been granted
az ad app permission list-grants --id $APP_ID
```

### Common Errors

**Error: "Insufficient privileges to complete the operation"**
- Solution: You need Application Administrator or Global Administrator role
- Ask your tenant admin to perform the operation

**Error: "The application already exists"**
- Solution: List existing apps and use the existing one:
  ```bash
  az ad app list --display-name "Beeper Teams Bridge"
  ```

**Error: "Invalid redirect URI"**
- Solution: Ensure URI format is correct (http/https, no trailing slash)
- Must match exactly what's in your config.yaml

---

## Complete Setup Script

Here's a complete script to set up everything:

```bash
#!/bin/bash

# Azure AD Application Setup for Beeper Teams Bridge
# This script creates and configures an Azure AD application

set -e  # Exit on error

echo "🚀 Setting up Azure AD Application for Beeper Teams Bridge"
echo ""

# Check if logged in
if ! az account show &>/dev/null; then
    echo "❌ Not logged into Azure CLI"
    echo "Please run: az login"
    exit 1
fi

# Configuration
APP_NAME="Beeper Teams Bridge"
REDIRECT_URI="http://localhost:29319/oauth/callback"
GRAPH_API_ID="00000003-0000-0000-c000-000000000000"

# Create application
echo "📝 Creating Azure AD application..."
APP_ID=$(az ad app create \
  --display-name "$APP_NAME" \
  --sign-in-audience "AzureADandPersonalMicrosoftAccount" \
  --web-redirect-uris "$REDIRECT_URI" \
  --query appId -o tsv)

echo "✅ Application created: $APP_ID"
echo ""

# Wait a bit for app to be ready
sleep 5

# Add permissions
echo "🔐 Adding Microsoft Graph permissions..."

# Chat.ReadWrite
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions 9ff7295e-131b-4d94-90e1-69fde507ac11=Scope
echo "  ✓ Chat.ReadWrite"

# ChannelMessage.Read.All
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions 7b2449af-6ccd-4f4d-9f78-e550c193f0d1=Scope
echo "  ✓ ChannelMessage.Read.All"

# ChannelMessage.Send
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions ebf0f66e-9fb1-49e4-a278-222f76911cf4=Scope
echo "  ✓ ChannelMessage.Send"

# Team.ReadBasic.All
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions 2280dda6-0bfd-44ee-a2f4-cb867cfc4c1e=Scope
echo "  ✓ Team.ReadBasic.All"

# User.Read
az ad app permission add \
  --id $APP_ID \
  --api $GRAPH_API_ID \
  --api-permissions e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope
echo "  ✓ User.Read"

echo ""
echo "🎉 Setup complete!"
echo ""

# Get tenant ID
TENANT_ID=$(az account show --query tenantId -o tsv)

# Display configuration
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Add these values to your config.yaml:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "network:"
echo "  azure_app_id: \"$APP_ID\""
echo "  azure_tenant_id: \"$TENANT_ID\""
echo "  azure_redirect_uri: \"$REDIRECT_URI\""
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check admin consent
echo "⚠️  IMPORTANT: Admin Consent Required"
echo ""
echo "If you're an administrator, run this command to grant consent:"
echo "  az ad app permission admin-consent --id $APP_ID"
echo ""
echo "If you're not an admin, ask your tenant administrator to:"
echo "1. Run the above command, OR"
echo "2. Visit: https://portal.azure.com/#blade/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/CallAnAPI/appId/$APP_ID"
echo "   and click 'Grant admin consent'"
echo ""

echo "✨ Done! Proceed with bridge configuration."
```

Save this script as `scripts/setup-azure-ad.sh` and run it:

```bash
chmod +x scripts/setup-azure-ad.sh
./scripts/setup-azure-ad.sh
```

---

## Alternative: Using Azure Portal

If you prefer a graphical interface, see [docs/setup.md#azure-ad-setup](setup.md#azure-ad-setup) for portal-based instructions.

---

## Additional Resources

### Microsoft Graph API
- [Microsoft Graph Permissions Reference](https://learn.microsoft.com/en-us/graph/permissions-reference)
- [Microsoft Graph REST API](https://learn.microsoft.com/en-us/graph/api/overview)

### Azure CLI
- [Azure CLI Documentation](https://learn.microsoft.com/en-us/cli/azure/)
- [Azure AD Application Commands](https://learn.microsoft.com/en-us/cli/azure/ad/app)
- [Azure CLI Install Guide](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

### Project Documentation
- [Setup Guide](setup.md)
- [Configuration Reference](configuration.md)
- [Codespaces Guide](codespaces.md)

---

## Next Steps

After creating and configuring your Azure AD application:

1. **Update bridge configuration** with your app ID and tenant ID
2. **Generate example config**: `make config`
3. **Edit config.yaml** with Azure values
4. **Generate registration**: `make registration`
5. **Start the bridge**: `make run`
6. **Login to bridge** and complete OAuth flow

See [docs/setup.md](setup.md) for complete bridge setup instructions.

---

**Need Help?**
- [Matrix Room](https://matrix.to/#/#teams:maunium.net)
- [GitHub Issues](https://github.com/lqdev/beeper-teams-bridge/issues)
