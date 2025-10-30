#!/bin/bash

# Post-creation script for DevContainer
echo "🚀 Setting up beeper-teams-bridge development environment..."

# Download Go dependencies
echo "📦 Downloading Go dependencies..."
go mod download

# Install Go tools if not already installed
echo "🔧 Verifying Go tools installation..."
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest 2>/dev/null || true
go install golang.org/x/tools/cmd/goimports@latest 2>/dev/null || true
go install github.com/securego/gosec/v2/cmd/gosec@latest 2>/dev/null || true

# Run go mod tidy to ensure dependencies are clean
echo "🧹 Tidying Go modules..."
go mod tidy

# Build the project to verify everything works
echo "🏗️  Building project..."
make build

# Display helpful information
echo ""
echo "✅ Development environment ready!"
echo ""
echo "📋 Quick Start Commands:"
echo "  make build          - Build the bridge"
echo "  make test           - Run tests"
echo "  make lint           - Run linter"
echo "  make run            - Build and run the bridge"
echo "  make dev-start      - Start PostgreSQL"
echo ""
echo "🔗 Useful Links:"
echo "  PostgreSQL: localhost:5432 (user: beeper, password: beeper, db: beeper-teams-bridge)"
echo "  Bridge Port: 29319"
echo ""
echo "📖 Documentation:"
echo "  - Setup: docs/setup.md"
echo "  - Configuration: docs/configuration.md"
echo "  - Codespaces Guide: docs/codespaces.md"
echo "  - Azure CLI Setup: docs/azure-cli-setup.md"
echo ""
echo "🎉 Happy coding!"
