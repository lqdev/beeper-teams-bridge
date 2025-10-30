# GitHub Codespaces Guide

This guide explains how to use GitHub Codespaces to develop beeper-teams-bridge in a fully configured cloud development environment.

---

## Table of Contents

1. [What is GitHub Codespaces?](#what-is-github-codespaces)
2. [Getting Started](#getting-started)
3. [Development Environment](#development-environment)
4. [Common Tasks](#common-tasks)
5. [Azure Configuration](#azure-configuration)
6. [Troubleshooting](#troubleshooting)

---

## What is GitHub Codespaces?

GitHub Codespaces provides a complete, configurable development environment hosted in the cloud. For beeper-teams-bridge, this means:

- ✅ **Pre-configured Go 1.21+ environment**
- ✅ **PostgreSQL 15 database ready to use**
- ✅ **All development tools pre-installed** (golangci-lint, goimports, etc.)
- ✅ **VS Code with recommended extensions**
- ✅ **Azure CLI and GitHub CLI**
- ✅ **No local setup required**

### Benefits

- Start coding in seconds
- Consistent development environment across team
- Work from any device with a browser
- Automatic environment teardown when not in use
- Free tier available for GitHub users

---

## Getting Started

### 1. Open in Codespaces

Click the button in the README or use one of these methods:

#### From GitHub UI
1. Navigate to the [repository](https://github.com/lqdev/beeper-teams-bridge)
2. Click the green **Code** button
3. Select the **Codespaces** tab
4. Click **Create codespace on main**

#### Using GitHub CLI
```bash
gh codespace create --repo lqdev/beeper-teams-bridge
```

#### From VS Code
1. Install the GitHub Codespaces extension
2. Press `Cmd/Ctrl+Shift+P`
3. Select "Codespaces: Create New Codespace"
4. Choose `lqdev/beeper-teams-bridge`

### 2. Wait for Setup

The first launch takes 2-5 minutes to:
- Build the development container
- Install all dependencies
- Set up PostgreSQL
- Run initial build

You'll see progress in the terminal. Once complete, you're ready to develop!

### 3. Verify Setup

```bash
# Check Go version
go version

# Check tools are installed
golangci-lint version
az --version
gh --version

# Verify build works
make build

# Check database connection
psql -h localhost -U beeper -d beeper-teams-bridge -c "SELECT version();"
# Password: beeper
```

---

## Development Environment

### Included Tools

#### Go Development
- Go 1.21+
- golangci-lint - Code linting
- goimports - Import formatting
- gosec - Security scanning
- godoc - Documentation server
- dlv (Delve) - Go debugger

#### Cloud Tools
- Azure CLI - Manage Azure resources
- GitHub CLI - Interact with GitHub

#### Database
- PostgreSQL 15 client
- Database running on localhost:5432

#### VS Code Extensions
- Go language support with IntelliSense
- GitHub Copilot (if you have access)
- Docker tools
- Database tools (SQLTools)
- Git tools (GitLens)
- YAML and Markdown support

### Environment Variables

Pre-configured environment variables:
```bash
GO111MODULE=on
GOPATH=/go
DATABASE_URL=postgres://beeper:beeper@localhost:5432/beeper-teams-bridge?sslmode=disable
```

### Ports

Automatically forwarded ports:
- **29319** - Bridge appservice (notify on auto-forward)
- **5432** - PostgreSQL (private)

Access forwarded ports via the **Ports** tab in VS Code.

---

## Common Tasks

### Building the Project

```bash
# Build the bridge
make build

# Build for all platforms
make build-all

# Install to $GOPATH/bin
make install
```

### Running Tests

```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run with coverage
make test-coverage
```

### Code Quality

```bash
# Format code
make fmt

# Run linter
make lint

# Fix linting issues automatically
make lint-fix

# Run all checks
make check
```

### Running the Bridge

```bash
# Generate example config
make config

# Edit config.yaml with your settings
code config.yaml

# Generate appservice registration
make registration

# Run the bridge
make run
```

### Database Operations

```bash
# Connect to PostgreSQL
psql -h localhost -U beeper -d beeper-teams-bridge
# Password: beeper

# Or use VS Code SQLTools extension (already configured)
# Press Cmd/Ctrl+Shift+P and search for "SQLTools: Connect"
```

### Using Make Targets

See all available make targets:
```bash
make help
```

Common targets:
- `make build` - Build the bridge
- `make test` - Run tests
- `make lint` - Run linter
- `make run` - Build and run
- `make clean` - Clean build artifacts
- `make dev-setup` - Set up dev environment (already done)

---

## Azure Configuration

### Setting Up Azure AD Application

You'll need to create an Azure AD application for the bridge to work. You can do this via the Azure Portal or Azure CLI.

#### Option 1: Using Azure Portal

See [docs/setup.md#azure-ad-setup](setup.md#azure-ad-setup) for detailed portal instructions.

#### Option 2: Using Azure CLI (Recommended for Codespaces)

See [docs/azure-cli-setup.md](azure-cli-setup.md) for complete Azure CLI setup instructions.

Quick example:
```bash
# Login to Azure
az login

# Create an Azure AD application
az ad app create \
  --display-name "Beeper Teams Bridge Dev" \
  --sign-in-audience AzureADandPersonalMicrosoftAccount \
  --web-redirect-uris "http://localhost:29319/oauth/callback"

# Note the appId from the output
```

### GitHub CLI Authentication

Authenticate with GitHub CLI for easier workflow:
```bash
# Login to GitHub
gh auth login

# Check authentication status
gh auth status
```

---

## Troubleshooting

### Codespace Won't Start

**Problem:** Codespace fails to build or start

**Solutions:**
1. Check the build logs in the terminal
2. Try rebuilding the container:
   - Press `Cmd/Ctrl+Shift+P`
   - Select "Codespaces: Rebuild Container"
3. Create a new codespace if issue persists

### Database Connection Issues

**Problem:** Can't connect to PostgreSQL

**Solutions:**
```bash
# Check if PostgreSQL is running
docker ps | grep postgres

# Check database logs
docker logs beeper-teams-bridge-db

# Restart PostgreSQL
docker restart beeper-teams-bridge-db

# Test connection
psql -h localhost -U beeper -d beeper-teams-bridge -c "SELECT 1;"
```

### Build Failures

**Problem:** `make build` fails

**Solutions:**
```bash
# Clean and rebuild
make clean
make build

# Update dependencies
go mod tidy
go mod download

# Check Go version
go version  # Should be 1.21+
```

### Port Already in Use

**Problem:** Port 29319 or 5432 already in use

**Solutions:**
1. Check what's using the port:
   ```bash
   lsof -i :29319
   lsof -i :5432
   ```
2. Stop conflicting process or change port in config

### Slow Performance

**Problem:** Codespace is slow

**Solutions:**
1. Check machine type (can upgrade via Settings)
2. Stop unnecessary processes
3. Close unused VS Code tabs
4. Consider using a more powerful machine type

### Extensions Not Working

**Problem:** VS Code extensions not loading

**Solutions:**
1. Reload window: `Cmd/Ctrl+Shift+P` → "Developer: Reload Window"
2. Check extension status in Extensions sidebar
3. Rebuild container if needed

### Azure CLI Issues

**Problem:** Azure CLI commands fail

**Solutions:**
```bash
# Check Azure CLI version
az --version

# Login again
az logout
az login

# Clear cache
rm -rf ~/.azure
az login
```

---

## Best Practices

### Resource Management

- **Stop codespace when not in use** to avoid charges
- Codespaces auto-stop after 30 minutes of inactivity (default)
- Delete unused codespaces

### Commits and Push

- Commit and push changes regularly
- Codespaces persist your work, but it's safer to push

### Secrets

- **Never commit secrets** to the repository
- Use environment variables or GitHub Codespaces secrets
- Set secrets via Repository Settings → Codespaces → Secrets

### Performance Tips

- Close unused editor tabs
- Use terminal multiplexer (tmux) for multiple shells
- Stop unused processes

---

## Additional Resources

### Documentation
- [GitHub Codespaces Docs](https://docs.github.com/en/codespaces)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview)
- [DevContainers Specification](https://containers.dev/)

### Project Documentation
- [Setup Guide](setup.md)
- [Configuration Reference](configuration.md)
- [Azure CLI Setup](azure-cli-setup.md)
- [Troubleshooting](troubleshooting.md)

### Support
- [Matrix Room](https://matrix.to/#/#teams:maunium.net)
- [GitHub Issues](https://github.com/lqdev/beeper-teams-bridge/issues)

---

## FAQ

**Q: How much does Codespaces cost?**
A: GitHub provides free tier: 120 core-hours/month and 15GB storage. Check [GitHub pricing](https://github.com/features/codespaces) for details.

**Q: Can I use my local VS Code?**
A: Yes! Install the GitHub Codespaces extension and connect to your codespace from desktop VS Code.

**Q: How do I save my Azure CLI credentials?**
A: The devcontainer mounts `~/.azure` directory, so your credentials persist across sessions.

**Q: Can I customize the devcontainer?**
A: Yes! Edit `.devcontainer/devcontainer.json` and rebuild the container.

**Q: How do I access the database from my local machine?**
A: Use port forwarding. The PostgreSQL port (5432) is automatically forwarded and accessible via the Ports tab.

**Q: What happens to my data when I delete a codespace?**
A: All uncommitted changes and local data are lost. Always commit and push your work!

---

**Happy Coding in the Cloud! ☁️**
