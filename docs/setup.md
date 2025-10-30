# Setup Guide

Complete installation and setup instructions for beeper-teams-bridge.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure AD Setup](#azure-ad-setup)
3. [Installation Methods](#installation-methods)
4. [Configuration](#configuration)
5. [Registering Appservice](#registering-appservice)
6. [First Run](#first-run)
7. [Verification](#verification)

---

## Prerequisites

Before installing the bridge, ensure you have:

### System Requirements
- **Matrix homeserver** with appservice support
  - Synapse 1.92.0 or higher (recommended)
  - Dendrite, Conduit also supported
  - Admin access to register appservices
- **PostgreSQL** 10 or higher
- **Go** 1.24+ (if building from source)
- **Docker** (optional, for container deployment)

### Accounts & Access
- **Microsoft 365 account** with Teams access
- **Azure AD tenant** with permissions to create applications
- **Public HTTPS endpoint** for webhooks (can use ngrok for testing)

### Network Requirements
- Bridge needs to communicate with:
  - Matrix homeserver
  - Microsoft Graph API (https://graph.microsoft.com)
  - PostgreSQL database
- Homeserver needs to reach bridge on configured port (default: 29319)
- Teams needs to reach your public webhook URL

---

## Azure AD Setup

You can configure Azure AD using either the Azure Portal (GUI) or Azure CLI (command line).

**Choose your method:**
- **[Azure Portal](#azure-portal-setup)** - Visual interface (below)
- **[Azure CLI](azure-cli-setup.md)** - Command line (recommended for automation and AI agents)

### Azure Portal Setup

### 1. Create Azure AD Application

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **App registrations**
3. Click **New registration**
4. Configure:
   - **Name:** "Beeper Teams Bridge"
   - **Supported account types:** "Accounts in any organizational directory and personal Microsoft accounts"
   - **Redirect URI:** 
     - Platform: Web
     - URL: `http://localhost:29319/oauth/callback` (or your public URL)

### 2. Configure API Permissions

1. In your app, go to **API permissions**
2. Click **Add a permission** → **Microsoft Graph** → **Delegated permissions**
3. Add these permissions:
   - `Chat.ReadWrite`
   - `ChannelMessage.Read.All`
   - `ChannelMessage.Send`
   - `Team.ReadBasic.All`
   - `User.Read`
4. Click **Grant admin consent** (if you're an admin)
   - If not, ask your tenant admin to consent

### 3. Note Your Credentials

1. Go to **Overview** and copy:
   - **Application (client) ID** - Save as `azure_app_id`
   - **Directory (tenant) ID** - Save as `azure_tenant_id` (or use "common")
2. The redirect URI you configured earlier

**Important Notes:**
- Do NOT create a client secret - the bridge uses delegated permissions with OAuth 2.0 PKCE flow
- Application permissions won't work for chat messages - only delegated permissions are supported
- The redirect URI must match exactly (including http/https and port)

---

## Installation Methods

### Method 1: Docker (Recommended)

**Advantages:** Easy setup, isolated environment, simple updates

```bash
# Create directory for bridge data
mkdir beeper-teams-bridge && cd beeper-teams-bridge

# Pull latest image
docker pull ghcr.io/yourorg/beeper-teams-bridge:latest

# Generate example config
docker run --rm -v $(pwd):/data ghcr.io/yourorg/beeper-teams-bridge:latest -e

# Edit config.yaml with your settings
nano config.yaml

# Generate registration file
docker run --rm -v $(pwd):/data ghcr.io/yourorg/beeper-teams-bridge:latest -g
```

### Method 2: Pre-built Binary

**Advantages:** No Docker required, direct execution

```bash
# Download latest release
wget https://github.com/yourorg/beeper-teams-bridge/releases/latest/download/beeper-teams-bridge-linux-amd64
chmod +x beeper-teams-bridge-linux-amd64
mv beeper-teams-bridge-linux-amd64 /usr/local/bin/beeper-teams-bridge

# Create data directory
mkdir -p /etc/beeper-teams-bridge
cd /etc/beeper-teams-bridge

# Generate config
beeper-teams-bridge -e

# Edit config
nano config.yaml

# Generate registration
beeper-teams-bridge -g
```

### Method 3: Build from Source

**Advantages:** Latest features, customization

```bash
# Clone repository
git clone https://github.com/yourorg/beeper-teams-bridge.git
cd beeper-teams-bridge

# Install dependencies
go mod download

# Build
./scripts/build.sh
# Or: make build

# The binary is at ./beeper-teams-bridge

# Generate config
./beeper-teams-bridge -e

# Edit config
nano config.yaml

# Generate registration
./beeper-teams-bridge -g
```

---

## Configuration

### 1. Generate Configuration File

The `-e` flag creates an example `config.yaml`:

```bash
./beeper-teams-bridge -e
```

### 2. Configure Essential Settings

Edit `config.yaml` and configure:

#### Homeserver Settings
```yaml
homeserver:
  address: http://localhost:8008  # Your homeserver URL
  domain: matrix.example.com      # Your homeserver domain
```

#### Appservice Settings
```yaml
appservice:
  address: http://localhost:29319  # Bridge listen address
  port: 29319                       # Bridge port
  
  # Generate secure random tokens (32+ characters each)
  as_token: "generate-a-random-string-here"
  hs_token: "generate-another-random-string-here"
```

**Generate tokens:**
```bash
# Linux/macOS
openssl rand -hex 32

# Or use any secure random generator
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
```

#### Network Settings
```yaml
network:
  # Your Azure AD application credentials
  azure_app_id: "your-app-id-from-azure"
  azure_tenant_id: "common"  # or your specific tenant ID
  azure_redirect_uri: "http://localhost:29319/oauth/callback"
  
  # Public webhook URL (must be HTTPS in production)
  webhook_public_url: "https://your-domain.com"
```

**For development/testing with ngrok:**
```bash
# Start ngrok
ngrok http 29319

# Use the HTTPS URL in webhook_public_url
webhook_public_url: "https://abc123.ngrok.io"
```

#### Database Settings
```yaml
database:
  type: postgres
  uri: postgres://user:password@localhost/mautrix_teams?sslmode=disable
```

**Setup PostgreSQL:**
```bash
# Create database and user
sudo -u postgres psql << EOF
CREATE USER mautrix WITH PASSWORD 'your-secure-password';
CREATE DATABASE mautrix_teams OWNER mautrix;
\c mautrix_teams
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOF
```

### 3. Generate Registration File

```bash
./beeper-teams-bridge -g
```

This creates `registration.yaml` with appservice configuration for your homeserver.

See [configuration.md](configuration.md) for complete configuration reference.

---

## Registering Appservice

### Synapse

1. **Copy registration file** to your Synapse config directory:
   ```bash
   sudo cp registration.yaml /etc/matrix-synapse/
   ```

2. **Edit Synapse config** (`/etc/matrix-synapse/homeserver.yaml`):
   ```yaml
   app_service_config_files:
     - /etc/matrix-synapse/registration.yaml
   ```

3. **Restart Synapse:**
   ```bash
   sudo systemctl restart matrix-synapse
   ```

4. **Verify** in Synapse logs:
   ```bash
   sudo journalctl -u matrix-synapse -f
   # Look for: "Loaded appservice: teams"
   ```

### Dendrite

1. **Copy registration file** to Dendrite config directory
2. **Edit Dendrite config** (`dendrite.yaml`):
   ```yaml
   app_service_api:
     config_files:
       - /path/to/registration.yaml
   ```
3. **Restart Dendrite:**
   ```bash
   sudo systemctl restart dendrite
   ```

### Conduit

1. **Place registration file** in Conduit appservice directory:
   ```bash
   sudo cp registration.yaml /var/lib/matrix-conduit/appservices/
   ```

2. **Restart Conduit:**
   ```bash
   sudo systemctl restart conduit
   ```

---

## First Run

### Using Docker

```bash
docker run -d \
  --name beeper-teams-bridge \
  --restart unless-stopped \
  -v $(pwd):/data \
  -p 29319:29319 \
  ghcr.io/yourorg/beeper-teams-bridge:latest
```

**View logs:**
```bash
docker logs -f beeper-teams-bridge
```

### Using Systemd

1. **Create systemd service** (`/etc/systemd/system/beeper-teams-bridge.service`):
   ```ini
   [Unit]
   Description=Beeper Teams Bridge
   After=network.target matrix-synapse.service postgresql.service
   
   [Service]
   Type=simple
   User=mautrix
   WorkingDirectory=/etc/beeper-teams-bridge
   ExecStart=/usr/local/bin/beeper-teams-bridge -c /etc/beeper-teams-bridge/config.yaml
   Restart=on-failure
   RestartSec=10
   
   [Install]
   WantedBy=multi-user.target
   ```

2. **Start service:**
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl start beeper-teams-bridge
   sudo systemctl enable beeper-teams-bridge
   ```

3. **View logs:**
   ```bash
   sudo journalctl -u beeper-teams-bridge -f
   ```

### Manual Run

```bash
./beeper-teams-bridge -c config.yaml
```

---

## Verification

### 1. Check Bridge Status

**Health check:**
```bash
curl http://localhost:29319/health
```

Expected response: `{"status":"ok"}`

**Logs should show:**
```
INFO Bridge initialized successfully
INFO Appservice listening on 0.0.0.0:29319
INFO Webhook endpoint available at /webhook
```

### 2. Test Bridge Bot

1. **Start a chat** with the bridge bot:
   - Bot username from config (default: `@teamsbot:matrix.example.com`)
   
2. **Send command:**
   ```
   ping
   ```

3. **Expected response:**
   ```
   Pong! Bridge is running.
   Version: v1.0.0
   ```

### 3. Login to Teams

1. **In bridge bot chat, send:**
   ```
   login
   ```

2. **Click the OAuth link** in the bot's response

3. **Sign in** with your Microsoft account

4. **Authorize** the application

5. **Return to Matrix** - you should see:
   ```
   ✅ Successfully logged in as John Doe (john@example.com)
   ```

6. **Verify sync:**
   ```
   sync
   ```
   
   The bridge will create Matrix rooms for your Teams chats and channels.

---

## Troubleshooting

### Bridge Won't Start

**Check logs:**
```bash
# Docker
docker logs beeper-teams-bridge

# Systemd
sudo journalctl -u beeper-teams-bridge -n 50

# Manual
./beeper-teams-bridge -c config.yaml
```

**Common issues:**
- Database connection failed → Verify PostgreSQL is running and credentials are correct
- Config parse error → Check YAML syntax in config.yaml
- Port already in use → Change port in config or stop conflicting service
- Homeserver unreachable → Verify homeserver address and network connectivity

### Login Fails

**Symptoms:** OAuth error or "Login failed" message

**Fixes:**
1. **Verify Azure AD configuration:**
   - Redirect URI must match exactly (check http vs https, port number)
   - All permissions granted and admin-consented
   - App ID and tenant ID are correct

2. **Check bridge logs** for specific OAuth error

3. **Test OAuth flow manually:**
   - Visit: `http://localhost:29319/oauth/start`
   - Should redirect to Microsoft login

### Messages Not Bridging

**Symptoms:** Messages sent but not appearing on other side

**Fixes:**
1. **Check webhook subscriptions:**
   ```
   # In bridge bot chat
   help
   ```
   Look for webhook status in response

2. **Verify public webhook URL:**
   - Must be accessible from internet
   - Must be HTTPS in production
   - Test: `curl https://your-domain.com/webhook`

3. **Check rate limits:**
   - Review bridge logs for 429 errors
   - Adjust rate limiting in config

See [troubleshooting.md](troubleshooting.md) for more solutions.

---

## Next Steps

- Read [usage.md](usage.md) for how to use the bridge
- Review [configuration.md](configuration.md) for advanced settings
- Join [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net) for support

---

## Security Best Practices

1. **Use HTTPS** for webhook URL in production
2. **Generate strong tokens** (32+ characters, random)
3. **Secure database** with firewall rules and strong password
4. **Keep bridge updated** for security patches
5. **Monitor logs** for suspicious activity
6. **Use environment variables** for secrets instead of plain text in config

---

**Need help?** Join [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net) or open an issue on [GitHub](https://github.com/yourorg/beeper-teams-bridge/issues).
