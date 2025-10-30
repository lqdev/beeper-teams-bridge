# Copilot Setup Steps

This file contains commands that GitHub Copilot will run to set up the development environment before working on this repository.

## Install Go Tools

```bash
# Install golangci-lint for linting
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Install gosec for security scanning
go install github.com/securego/gosec/v2/cmd/gosec@latest

# Install goimports for import formatting
go install golang.org/x/tools/cmd/goimports@latest
```

## Download Dependencies

```bash
# Download Go module dependencies
go mod download
```

## Verify Installation

```bash
# Verify Go version (requires 1.21+)
go version

# Verify tools are installed
which golangci-lint
which gosec
which goimports
```
