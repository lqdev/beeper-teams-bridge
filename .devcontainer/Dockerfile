# Development container for Beeper Teams Bridge
FROM mcr.microsoft.com/devcontainers/go:1-1.21-bookworm

# Install additional system packages
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
    postgresql-client \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    vim \
    nano \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Go tools
RUN go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest \
    && go install golang.org/x/tools/cmd/goimports@latest \
    && go install github.com/securego/gosec/v2/cmd/gosec@latest \
    && go install github.com/cespare/reflex@latest \
    && go install golang.org/x/tools/cmd/godoc@latest \
    && go install github.com/go-delve/delve/cmd/dlv@latest

# Set up Go environment
ENV GO111MODULE=on
ENV GOPATH=/go
ENV PATH=$PATH:/go/bin

# Create workspace directory
RUN mkdir -p /workspace && chown -R vscode:vscode /workspace

# Switch to vscode user
USER vscode

# Set working directory
WORKDIR /workspace
