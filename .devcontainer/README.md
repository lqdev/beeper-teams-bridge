# DevContainer Configuration

This directory contains the DevContainer configuration for beeper-teams-bridge, enabling development in GitHub Codespaces or VS Code Remote Containers.

## Files

- **`devcontainer.json`** - Main DevContainer configuration
  - Defines the development environment
  - Specifies VS Code extensions and settings
  - Configures port forwarding
  - Sets up features (Azure CLI, GitHub CLI, Docker-in-Docker)

- **`Dockerfile`** - Development container image
  - Based on Microsoft's Go DevContainer image
  - Includes Go 1.21+ and development tools
  - Pre-installs golangci-lint, goimports, gosec, etc.

- **`docker-compose.yml`** - Multi-container setup
  - Development container (Go environment)
  - PostgreSQL 15 database service
  - Networking configuration

- **`postCreate.sh`** - Post-creation setup script
  - Runs after container is created
  - Downloads Go dependencies
  - Builds the project
  - Displays helpful information

## Quick Start

### GitHub Codespaces

1. Click the "Open in GitHub Codespaces" button in the README
2. Wait for the environment to build (2-5 minutes)
3. Start coding!

### VS Code Remote Containers

1. Install the "Remote - Containers" extension in VS Code
2. Open the repository in VS Code
3. Press `Cmd/Ctrl+Shift+P` and select "Remote-Containers: Reopen in Container"
4. Wait for the container to build

## Features

### Pre-installed Tools

- Go 1.21+
- golangci-lint
- goimports
- gosec
- godoc
- Delve (Go debugger)
- Azure CLI
- GitHub CLI
- PostgreSQL client
- Docker-in-Docker

### VS Code Extensions

- Go language support
- GitHub Copilot
- Docker tools
- Database tools (SQLTools)
- Git tools (GitLens)
- YAML and Markdown support

### Environment Configuration

- **Database**: PostgreSQL 15 running on localhost:5432
  - User: `beeper`
  - Password: `beeper`
  - Database: `beeper-teams-bridge`

- **Ports**:
  - 29319 - Bridge appservice
  - 5432 - PostgreSQL

## Customization

### Adding Extensions

Edit `devcontainer.json` and add extension IDs to the `extensions` array:

```json
"extensions": [
  "golang.go",
  "your.extension-id"
]
```

### Changing Settings

Edit `devcontainer.json` to modify VS Code settings:

```json
"settings": {
  "go.formatTool": "goimports",
  "your.setting": "value"
}
```

### Installing Additional Tools

Edit `Dockerfile` to install additional packages:

```dockerfile
RUN apt-get update && apt-get install -y \
    your-package \
    && apt-get clean
```

Or add to `postCreate.sh` for Go tools:

```bash
go install example.com/tool@latest
```

## Troubleshooting

### Container Won't Build

- Check Docker is running
- Try rebuilding: `Cmd/Ctrl+Shift+P` → "Remote-Containers: Rebuild Container"
- Check Docker logs for errors

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker ps | grep postgres

# Test connection
psql -h localhost -U beeper -d beeper-teams-bridge
# Password: beeper
```

### Slow Performance

- Increase allocated resources in Docker Desktop settings
- Close unused VS Code tabs
- Stop unnecessary processes

## Documentation

- [GitHub Codespaces Guide](../docs/codespaces.md)
- [DevContainers Specification](https://containers.dev/)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/containers)

## Support

- [Matrix Room](https://matrix.to/#/#teams:maunium.net)
- [GitHub Issues](https://github.com/lqdev/beeper-teams-bridge/issues)
