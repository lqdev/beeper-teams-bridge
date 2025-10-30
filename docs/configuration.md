# Configuration Reference

Complete configuration options for beeper-teams-bridge.

---

## Table of Contents

1. [Overview](#overview)
2. [Homeserver Configuration](#homeserver-configuration)
3. [Appservice Configuration](#appservice-configuration)
4. [Bridge Configuration](#bridge-configuration)
5. [Network Configuration](#network-configuration)
6. [Database Configuration](#database-configuration)
7. [Logging Configuration](#logging-configuration)
8. [Metrics Configuration](#metrics-configuration)
9. [Encryption Configuration](#encryption-configuration)
10. [Environment Variables](#environment-variables)

---

## Overview

The bridge configuration is stored in `config.yaml`. Generate an example config with:

```bash
./beeper-teams-bridge -e
```

All configuration changes require a bridge restart to take effect.

---

## Homeserver Configuration

Configure connection to your Matrix homeserver.

```yaml
homeserver:
  # Homeserver client-server API URL
  address: http://localhost:8008
  
  # Homeserver domain name
  domain: matrix.example.com
  
  # Homeserver software (optional, for specific workarounds)
  software: synapse  # synapse, dendrite, conduit
  
  # Status endpoint for server health checks (optional)
  status_endpoint: null
  
  # Checkpoint endpoint for message send confirmations (optional)
  message_send_checkpoint_endpoint: null
  
  # Use async media upload API (MSC2246, Synapse 1.95+)
  async_media: false
```

### Options

- **address**: Full URL to homeserver client-server API
  - Must be reachable from bridge
  - Usually `http://localhost:8008` for local Synapse
  - Use full domain for remote homeservers

- **domain**: Your homeserver's domain name
  - Used in Matrix IDs (`@user:domain`)
  - Must match homeserver's `server_name`

- **software**: Homeserver implementation
  - Enables specific workarounds if needed
  - Values: `synapse`, `dendrite`, `conduit`
  - Optional, auto-detected if not specified

---

## Appservice Configuration

Configure the application service registration.

```yaml
appservice:
  # Address where bridge listens for homeserver requests
  address: http://localhost:29319
  
  # Hostname to bind to (0.0.0.0 for all interfaces)
  hostname: 0.0.0.0
  
  # Port to listen on
  port: 29319
  
  # Appservice ID (must match registration.yaml)
  id: teams
  
  # Bot configuration
  bot:
    username: teamsbot
    displayname: Microsoft Teams Bridge
    avatar: mxc://maunium.net/teams-logo
  
  # Enable ephemeral events (typing, read receipts)
  ephemeral_events: true
  
  # Application service token (generate random 64+ character string)
  as_token: "generate-a-random-string"
  
  # Homeserver token (generate different random 64+ character string)
  hs_token: "generate-another-random-string"
```

### Generate Secure Tokens

```bash
# Linux/macOS
openssl rand -hex 32

# Or
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1
```

### Options

- **address**: URL homeserver uses to reach bridge
  - Change if bridge is on different host
  - Must match address in registration.yaml

- **hostname**: Network interface to bind to
  - `0.0.0.0`: All interfaces
  - `127.0.0.1`: Localhost only (secure if homeserver is local)

- **port**: TCP port for appservice API
  - Default: 29319
  - Must not conflict with other services
  - Must be reachable by homeserver

- **bot.username**: Bridge bot's username
  - Used for commands and notifications
  - Will be `@{username}:{homeserver.domain}`

- **ephemeral_events**: Enable typing indicators and read receipts
  - Set to `false` to reduce traffic

---

## Bridge Configuration

Configure bridge behavior and permissions.

```yaml
bridge:
  # Template for ghost user usernames
  username_template: "teams_{userid}"
  
  # Template for ghost user display names
  displayname_template: "{displayname}"
  
  # Command prefix for bot commands
  command_prefix: "!teams"
  
  # User permissions
  permissions:
    # Default permission for all users
    "*": relay
    
    # Permission for users on specific domain
    "example.com": user
    
    # Admin permission for specific user
    "@admin:example.com": admin
  
  # Relay mode configuration (for non-logged-in users)
  relay:
    enabled: false
  
  # Double puppeting configuration
  double_puppet_server_map: {}
  
  # Shared secret for double puppeting
  login_shared_secret_map: {}
```

### Permission Levels

- **relay**: Can use relayed messages (bridge bot sends messages)
- **user**: Can log in and use bridge
- **admin**: Can use admin commands and manage bridge

### Username Template Variables

- `{userid}`: Teams user ID
- `{username}`: Teams username/email

### Display Name Template Variables

- `{displayname}`: Teams display name
- `{username}`: Teams username/email

---

## Network Configuration

Configure Teams-specific settings.

```yaml
network:
  # Azure AD Application Credentials
  azure_app_id: "your-app-id-from-azure"
  azure_tenant_id: "common"  # or your specific tenant ID
  azure_redirect_uri: "http://localhost:29319/oauth/callback"
  
  # Microsoft Graph API
  graph_api_base: "https://graph.microsoft.com/v1.0"
  
  # Webhook Configuration
  webhook_public_url: "https://your-domain.com"
  webhook_secret: "generate-random-secret-for-webhooks"
  
  # Rate Limiting
  max_requests_per_second: 4
  burst_allowance: 10
  
  # Feature Flags
  enable_reactions: true
  enable_edits: true
  enable_deletes: true
  enable_typing: true
  enable_presence: false
  
  # Message Settings
  max_message_length: 28000
  media_upload_timeout: 300
  
  # Sync Settings
  sync_on_startup: true
  sync_interval: 3600  # seconds
```

### Azure AD Settings

- **azure_app_id**: Application (client) ID from Azure portal
- **azure_tenant_id**: 
  - Use `"common"` for multi-tenant (personal + work accounts)
  - Use specific tenant ID for single organization
- **azure_redirect_uri**: Must match exactly in Azure AD app configuration
  - Include protocol (http/https) and port
  - For production, use HTTPS

### Webhook Settings

- **webhook_public_url**: Publicly accessible HTTPS URL
  - Must be reachable from Microsoft's servers
  - For development, use ngrok: `https://abc123.ngrok.io`
  - For production, use your domain: `https://teams-bridge.example.com`

- **webhook_secret**: Random string for webhook validation
  - Generate like tokens (32+ characters)

### Rate Limiting

Microsoft Graph API limits:
- Default: 4 requests/second per user
- Burst: Allow temporary spikes (10 requests)

Adjust if you experience throttling (429 errors).

### Feature Flags

Enable/disable specific features:
- **enable_reactions**: Like/emoji reactions
- **enable_edits**: Message editing
- **enable_deletes**: Message deletion
- **enable_typing**: Typing indicators
- **enable_presence**: Online/offline status (coming soon)

---

## Database Configuration

Configure PostgreSQL database connection.

```yaml
database:
  # Database type (only postgres supported)
  type: postgres
  
  # Connection URI
  uri: postgres://user:password@localhost/mautrix_teams?sslmode=disable
  
  # Connection pool settings
  max_open_conns: 5
  max_idle_conns: 1
  conn_max_lifetime: 0    # seconds, 0 = unlimited
  conn_max_idle_time: 0   # seconds, 0 = unlimited
```

### URI Format

```
postgres://username:password@host:port/database?parameters
```

**Examples:**
```yaml
# Local database
uri: postgres://mautrix:password@localhost/mautrix_teams?sslmode=disable

# Remote database with SSL
uri: postgres://user:pass@db.example.com:5432/mautrix_teams?sslmode=require

# Unix socket
uri: postgres://mautrix@/mautrix_teams?host=/var/run/postgresql

# Connection pooling via PgBouncer
uri: postgres://mautrix:pass@localhost:6432/mautrix_teams?pool_mode=transaction
```

### Connection Pool

- **max_open_conns**: Maximum open connections
  - Default: 5
  - Increase for high load

- **max_idle_conns**: Maximum idle connections in pool
  - Default: 1
  - Keep lower than max_open_conns

---

## Logging Configuration

Configure logging output and verbosity.

```yaml
logging:
  # Minimum log level
  min_level: info  # debug, info, warn, error
  
  # Log writers
  writers:
    # Console output
    - type: stdout
      format: pretty-colored  # pretty-colored, json
      
    # File output
    - type: file
      format: json
      filename: ./bridge.log
      max_size: 100        # megabytes
      max_backups: 10      # number of old log files to keep
      max_age: 30          # days
      compress: true       # compress old logs
```

### Log Levels

- **debug**: Verbose logging (includes API requests/responses)
- **info**: Normal operation logs (default)
- **warn**: Warnings and non-critical errors
- **error**: Critical errors only

### Log Formats

- **pretty-colored**: Human-readable with colors (for terminal)
- **json**: Structured JSON (for log aggregation tools)

---

## Metrics Configuration

Configure Prometheus metrics export.

```yaml
metrics:
  # Enable metrics endpoint
  enabled: true
  
  # Listen address for metrics
  listen: 127.0.0.1:8001
```

### Available Metrics

```
# Messages
mautrix_teams_messages_received_total
mautrix_teams_messages_sent_total
mautrix_teams_message_latency_seconds

# Users
mautrix_teams_active_users
mautrix_teams_logged_in_users
mautrix_teams_webhook_subscriptions

# Portals
mautrix_teams_portals_total
mautrix_teams_portals_by_type

# Errors
mautrix_teams_graph_api_errors_total
mautrix_teams_webhook_errors_total
```

### Scrape Configuration

Add to Prometheus config:
```yaml
scrape_configs:
  - job_name: 'beeper-teams-bridge'
    static_configs:
      - targets: ['localhost:8001']
```

---

## Encryption Configuration

Configure end-to-bridge encryption (optional).

```yaml
encryption:
  # Allow encrypted rooms
  allow: true
  
  # Enable encryption by default for new portals
  default: false
  
  # Require encryption (reject unencrypted rooms)
  require: false
  
  # Enable appservice-side encryption
  appservice: false
  
  # Enable MSC4190 encrypted backups
  msc4190: false
  
  # Verification levels
  verification_levels:
    # Receive messages from...
    receive: unverified      # verified, unverified, cross-signed-untrusted, cross-signed-tofu
    
    # Send messages to...
    send: unverified         # verified, unverified, cross-signed-untrusted, cross-signed-tofu
    
    # Share keys with...
    share: cross-signed-tofu # verified, cross-signed-untrusted, cross-signed-tofu
```

### Encryption Options

- **allow**: Whether encrypted rooms are supported
- **default**: Auto-enable encryption for new portals
- **require**: Reject unencrypted rooms
- **appservice**: Use appservice encryption (experimental)

---

## Environment Variables

Override config values with environment variables.

### Syntax

```bash
# Format: CONFIG_KEY__NESTED__VALUE
export HOMESERVER__ADDRESS=http://localhost:8008
export DATABASE__URI=postgres://user:pass@localhost/db
export NETWORK__AZURE_APP_ID=your-app-id
```

### Common Variables

```bash
# Homeserver
export HOMESERVER__ADDRESS=http://localhost:8008
export HOMESERVER__DOMAIN=matrix.example.com

# Tokens (recommended for secrets)
export APPSERVICE__AS_TOKEN=your-as-token
export APPSERVICE__HS_TOKEN=your-hs-token

# Azure credentials
export NETWORK__AZURE_APP_ID=your-app-id
export NETWORK__AZURE_TENANT_ID=common
export NETWORK__WEBHOOK_PUBLIC_URL=https://your-domain.com

# Database
export DATABASE__URI=postgres://user:pass@host/db

# Logging
export LOGGING__MIN_LEVEL=debug
```

### Docker Environment Variables

```bash
docker run -d \
  -e HOMESERVER__ADDRESS=http://homeserver:8008 \
  -e APPSERVICE__AS_TOKEN=$AS_TOKEN \
  -e APPSERVICE__HS_TOKEN=$HS_TOKEN \
  -e DATABASE__URI=$DATABASE_URL \
  -v $(pwd)/config.yaml:/data/config.yaml \
  ghcr.io/yourorg/beeper-teams-bridge:latest
```

---

## Complete Example

```yaml
# Homeserver configuration
homeserver:
  address: http://localhost:8008
  domain: matrix.example.com
  software: synapse

# Application service configuration
appservice:
  address: http://localhost:29319
  hostname: 0.0.0.0
  port: 29319
  id: teams
  bot:
    username: teamsbot
    displayname: Microsoft Teams Bridge
    avatar: mxc://maunium.net/teams-logo
  ephemeral_events: true
  as_token: "generate-a-random-string"
  hs_token: "generate-another-random-string"

# Bridge configuration
bridge:
  username_template: "teams_{userid}"
  displayname_template: "{displayname}"
  command_prefix: "!teams"
  permissions:
    "*": relay
    "example.com": user
    "@admin:example.com": admin
  relay:
    enabled: false
  double_puppet_server_map: {}
  login_shared_secret_map: {}

# Network-specific configuration
network:
  azure_app_id: "your-app-id"
  azure_tenant_id: "common"
  azure_redirect_uri: "http://localhost:29319/oauth/callback"
  graph_api_base: "https://graph.microsoft.com/v1.0"
  webhook_public_url: "https://teams-bridge.example.com"
  webhook_secret: "generate-random-secret"
  max_requests_per_second: 4
  burst_allowance: 10
  enable_reactions: true
  enable_edits: true
  enable_deletes: true
  enable_typing: true
  max_message_length: 28000
  media_upload_timeout: 300

# Database configuration
database:
  type: postgres
  uri: postgres://mautrix:password@localhost/mautrix_teams?sslmode=disable
  max_open_conns: 5
  max_idle_conns: 1

# Logging configuration
logging:
  min_level: info
  writers:
    - type: stdout
      format: pretty-colored
    - type: file
      filename: ./bridge.log
      max_size: 100
      max_backups: 10
      max_age: 30
      compress: true

# Metrics configuration  
metrics:
  enabled: true
  listen: 127.0.0.1:8001

# Encryption configuration
encryption:
  allow: true
  default: false
  require: false
```

---

## Validation

Validate your configuration:

```bash
# Test config syntax
./beeper-teams-bridge -c config.yaml -t

# Dry run (validate without starting)
./beeper-teams-bridge -c config.yaml --dry-run
```

---

## Need Help?

- Review [setup.md](setup.md) for initial configuration
- See [troubleshooting.md](troubleshooting.md) for common issues
- Join [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net) for support
