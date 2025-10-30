#!/bin/bash
set -e

VERSION=$(git describe --tags --always --dirty)
COMMIT=$(git rev-parse HEAD)
BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
GO_VERSION=$(go version | awk '{print $3}')

LDFLAGS="-X main.Version=$VERSION \
         -X main.Commit=$COMMIT \
         -X main.BuildTime=$BUILD_TIME \
         -X main.GoVersion=$GO_VERSION \
         -s -w"

go build -ldflags "$LDFLAGS" -o beeper-teams-bridge ./cmd/beeper-teams-bridge
