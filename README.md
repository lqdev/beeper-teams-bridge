# beeper-teams-bridge

A Matrix bridge for Microsoft Teams, built with [mautrix-go](https://github.com/mautrix/go).

[![CI Status](https://img.shields.io/github/actions/workflow/status/lqdev/beeper-teams-bridge/ci.yml?branch=main)](https://github.com/lqdev/beeper-teams-bridge/actions)
[![Go Report Card](https://goreportcard.com/badge/github.com/lqdev/beeper-teams-bridge)](https://goreportcard.com/report/github.com/lqdev/beeper-teams-bridge)
[![License](https://img.shields.io/github/license/lqdev/beeper-teams-bridge)](LICENSE)
[![Matrix Room](https://img.shields.io/matrix/teams:maunium.net?label=%23teams:maunium.net&logo=matrix&server_fqdn=maunium.net)](https://matrix.to/#/#teams:maunium.net)
[![GitHub release](https://img.shields.io/github/v/release/lqdev/beeper-teams-bridge)](https://github.com/lqdev/beeper-teams-bridge/releases)

Bridge Microsoft Teams channels and chats to Matrix, allowing you to send and receive messages from Teams within your Matrix client (like Beeper).

---

## ✨ Features

### Core Functionality
- ✅ **Two-way message bridging** - Send and receive messages between Teams and Matrix
- ✅ **OAuth 2.0 authentication** - Secure login with Microsoft account
- ✅ **Real-time sync** - Instant message delivery via webhooks
- ✅ **Media support** - Images, files, and other attachments
- ✅ **Reactions** - React to messages on both platforms
- ✅ **Message edits** - Edit messages after sending
- ✅ **Message deletions** - Delete messages on both sides
- ✅ **Reply threading** - Maintain conversation context
- ✅ **@mentions** - Mention users across platforms

### Conversation Types
- ✅ **Team channels** - Bridge public and private channels
- ✅ **1:1 chats** - Direct messages with other Teams users
- ✅ **Group chats** - Multi-user conversations

### Advanced Features
- ✅ **Double puppeting** - Messages from your real Matrix account
- ✅ **Ghost users** - Automatic Matrix users for Teams contacts
- ✅ **Portal rooms** - Automatic Matrix room creation
- ✅ **End-to-bridge encryption** - Optional E2BE support
- ✅ **Presence sync** - See when people are online (coming soon)
- ✅ **Typing indicators** - See when someone is typing (coming soon)

### Coming Soon
- 🚧 **Voice/video calls** - Bridge Teams calls to Matrix
- 🚧 **Meeting integration** - Join Teams meetings from Matrix
- 🚧 **Message history** - Backfill old messages
- 🚧 **Rich cards** - Full Adaptive Card support

---

## 📋 Requirements

### Prerequisites
- **Matrix homeserver** with appservice support (e.g., Synapse, Conduit)
  - Minimum Synapse version: 1.92.0
  - Admin access to register appservices
- **PostgreSQL** 10 or higher
- **Go** 1.24+ (if building from source)
- **Microsoft 365 account** with Teams access
- **Azure AD application** with appropriate permissions

### Azure AD Configuration
You'll need to create an Azure AD application with these Microsoft Graph API permissions:
- `Chat.ReadWrite` (Delegated)
- `ChannelMessage.Read.All` (Delegated)
- `ChannelMessage.Send` (Delegated)
- `Team.ReadBasic.All` (Delegated)
- `User.Read` (Delegated)

See [docs/setup.md](docs/setup.md#azure-ad-setup) for detailed instructions.

---

## 🚀 Quick Start

### 1. Installation

#### Using Docker (Recommended)
```bash
# Create directory for the bridge
mkdir beeper-teams-bridge && cd beeper-teams-bridge

# Pull the latest image
docker pull ghcr.io/lqdev/beeper-teams-bridge:latest

# Generate config
docker run --rm -v $(pwd):/data ghcr.io/lqdev/beeper-teams-bridge:latest -e

# Edit config.yaml with your settings
nano config.yaml

# Generate registration file
docker run --rm -v $(pwd):/data ghcr.io/lqdev/beeper-teams-bridge:latest -g
```

#### Using Pre-built Binary
```bash
# Download latest release
wget https://github.com/lqdev/beeper-teams-bridge/releases/latest/download/beeper-teams-bridge-linux-amd64
chmod +x beeper-teams-bridge-linux-amd64
mv beeper-teams-bridge-linux-amd64 beeper-teams-bridge

# Generate config
./beeper-teams-bridge -e

# Edit config
nano config.yaml

# Generate registration
./beeper-teams-bridge -g
```

#### Building from Source
```bash
# Clone the repository
git clone https://github.com/lqdev/beeper-teams-bridge.git
cd beeper-teams-bridge

# Install dependencies
go mod download

# Build
./scripts/build.sh

# Generate config
./beeper-teams-bridge -e
```

### 2. Configuration

Edit `config.yaml` with your settings:

```yaml
homeserver:
  address: http://localhost:8008  # Your homeserver address
  domain: matrix.example.com      # Your homeserver domain

appservice:
  address: http://localhost:29319
  port: 29319
  
  # Generate random tokens
  as_token: "your-random-as-token"
  hs_token: "your-random-hs-token"

network:
  # Your Azure AD application credentials
  azure_app_id: "your-app-id"
  azure_tenant_id: "common"
  azure_redirect_uri: "http://localhost:29319/oauth/callback"
  
  # Your public webhook URL (use ngrok for testing)
  webhook_public_url: "https://your-domain.com"

database:
  type: postgres
  uri: postgres://user:password@localhost/mautrix_teams?sslmode=disable
```

See [docs/configuration.md](docs/configuration.md) for all options.

### 3. Register with Homeserver

#### Synapse
Add to your Synapse `homeserver.yaml`:
```yaml
app_service_config_files:
  - /path/to/beeper-teams-bridge/registration.yaml
```

Restart Synapse:
```bash
systemctl restart matrix-synapse
```

#### Other Homeservers
See [docs/setup.md#registering-appservice](docs/setup.md#registering-appservice) for Dendrite, Conduit, etc.

### 4. Start the Bridge

#### Docker
```bash
docker run -d \
  --name beeper-teams-bridge \
  --restart unless-stopped \
  -v $(pwd):/data \
  -p 29319:29319 \
  ghcr.io/lqdev/beeper-teams-bridge:latest
```

#### Systemd
```bash
sudo systemctl start beeper-teams-bridge
sudo systemctl enable beeper-teams-bridge
```

#### Manual
```bash
./beeper-teams-bridge
```

### 5. Login

1. **Start a chat** with the bridge bot (`@teamsbot:matrix.example.com`)
2. **Send** `login`
3. **Follow the OAuth link** to authorize with Microsoft
4. **Complete authentication** in your browser
5. **Done!** Your Teams chats will start syncing

---

## 📖 Documentation

### User Guides
- **[Setup Guide](docs/setup.md)** - Detailed installation instructions
- **[Configuration Reference](docs/configuration.md)** - All config options explained
- **[User Guide](docs/usage.md)** - How to use the bridge
- **[Troubleshooting](docs/troubleshooting.md)** - Common issues and solutions

### Developer Documentation
- **[Architecture Overview](docs/architecture.md)** - Technical design
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute
- **[API Documentation](docs/api.md)** - Internal API reference
- **[Product Requirements](docs/beeper-teams-bridge-prd.md)** - Complete PRD and spec

---

## 🎮 Usage

### Bot Commands

Start a chat with `@teamsbot:matrix.example.com` (or your configured bot username).

#### Authentication
```
login          - Start OAuth login flow
logout         - Disconnect from Teams
```

#### Chat Management
```
sync           - Force sync of rooms and messages
list-teams     - Show all Teams you're in
list-chats     - Show recent chats
```

#### Utilities
```
ping           - Check bridge connectivity
help           - Show command help
version        - Show bridge version
```

#### Admin Commands
```
reload-config  - Reload configuration (admin only)
stats          - Show bridge statistics (admin only)
```

### Starting Conversations

**From Matrix:**
1. Use `list-teams` to see available channels
2. Click on a channel to open a portal
3. Send messages as normal

**From Teams:**
- Incoming messages automatically create Matrix rooms
- You'll be invited to the room automatically

---

## 🏗️ Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│                 │         │                  │         │                 │
│  Matrix Client  │◄───────►│  Matrix Bridge   │◄───────►│ Microsoft Teams │
│    (Beeper)     │         │  (beeper-teams-bridge) │         │   (Graph API)   │
│                 │         │                  │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
                                    │
                                    │
                                    ▼
                            ┌──────────────┐
                            │              │
                            │  PostgreSQL  │
                            │   Database   │
                            │              │
                            └──────────────┘
```

The bridge uses webhooks for real-time message delivery from Teams, and the Microsoft Graph API for sending messages to Teams.

See [docs/architecture.md](docs/architecture.md) for detailed technical information.

---

## 🔧 Development

### Setting Up Development Environment

```bash
# Clone the repository
git clone https://github.com/lqdev/beeper-teams-bridge.git
cd beeper-teams-bridge

# Install dependencies
go mod download

# Set up pre-commit hooks
pre-commit install

# Run tests
make test

# Build
make build

# Run locally
./beeper-teams-bridge
```

### Project Structure
```
beeper-teams-bridge/
├── cmd/beeper-teams-bridge/    # Main application entry point
├── pkg/connector/        # Bridge connector implementation
├── internal/             # Internal utilities
├── docs/                 # Documentation
├── test/                 # Integration and E2E tests
└── scripts/              # Build and deployment scripts
```

### Running Tests

```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run with coverage
make test-coverage

# Run linter
make lint
```

### Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development workflow
- Coding standards
- Commit message format
- Pull request process

---

## 🐛 Troubleshooting

### Common Issues

**Bridge won't start**
```bash
# Check logs
docker logs beeper-teams-bridge
# or
journalctl -u beeper-teams-bridge -f
```

**Login fails**
- Verify Azure AD app configuration
- Check redirect URI matches exactly
- Ensure all permissions are granted and admin-consented

**Messages not bridging**
- Check webhook subscriptions are active
- Verify public webhook URL is accessible
- Review bridge logs for errors

**High latency**
- Check database performance
- Verify network connectivity to Graph API
- Monitor rate limiting status

See [docs/troubleshooting.md](docs/troubleshooting.md) for more solutions.

---

## 📊 Monitoring

### Prometheus Metrics

The bridge exposes metrics at `http://localhost:8001/metrics` (configurable):

```
# Messages
mautrix_teams_messages_received_total
mautrix_teams_messages_sent_total
mautrix_teams_message_latency_seconds

# Users
mautrix_teams_active_users
mautrix_teams_webhook_subscriptions

# Errors
mautrix_teams_graph_api_errors_total
```

### Health Check

```bash
curl http://localhost:29319/health
```

---

## 🛡️ Security

### Reporting Security Issues

**DO NOT** create public GitHub issues for security vulnerabilities.

Instead, please email security@yourdomain.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

We'll respond within 48 hours.

### Security Features

- ✅ OAuth 2.0 with PKCE
- ✅ Token encryption at rest
- ✅ Webhook signature validation
- ✅ HTTPS enforcement
- ✅ End-to-bridge encryption support
- ✅ No plaintext credential storage

---

## 📜 License

Licensed under the [MIT License](LICENSE).

```
MIT License

Copyright (c) 2025 [Your Name/Organization]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🙏 Acknowledgments

- Built with [mautrix-go](https://github.com/mautrix/go) by [Tulir Asokan](https://github.com/tulir)
- Inspired by other [mautrix bridges](https://github.com/mautrix)
- Thanks to the [Beeper](https://beeper.com) team for support
- Microsoft Graph API for Teams integration

---

## 💬 Support

### Get Help
- **Matrix Room:** [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net)
- **GitHub Issues:** [Report bugs or request features](https://github.com/lqdev/beeper-teams-bridge/issues)
- **Documentation:** [Read the docs](docs/)

### Community
- [Matrix Community](https://matrix.to/#/#mautrix:maunium.net)
- [Beeper Self-Hosting](https://matrix.to/#/#self-hosting:beeper.com)

---

## 🗺️ Roadmap

### v1.0 (Current)
- [x] Basic message bridging
- [x] OAuth authentication
- [x] Webhook infrastructure
- [x] Media support
- [x] Reactions, edits, deletes
- [ ] Beta testing
- [ ] Production release

### v1.1 (Planned)
- [ ] Presence sync
- [ ] Typing indicators
- [ ] Read receipts
- [ ] Message history backfill

### v2.0 (Future)
- [ ] Voice/video call bridging
- [ ] Meeting integration
- [ ] Full Adaptive Card rendering
- [ ] Teams apps integration

See [GitHub Milestones](https://github.com/lqdev/beeper-teams-bridge/milestones) for detailed progress.

---

## 📈 Project Status

**Current Status:** 🟡 In Active Development

- Core functionality: ✅ Complete
- Testing: 🟡 In Progress
- Documentation: 🟡 In Progress
- Beta Release: ⏳ Coming Soon

---

## ⭐ Star History

[![Star History Chart](https://api.star-history.com/svg?repos=lqdev/beeper-teams-bridge&type=Date)](https://star-history.com/#lqdev/beeper-teams-bridge&Date)

If you find this project useful, please consider giving it a star! ⭐

---

**Made with ❤️ for the Matrix community**
