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
