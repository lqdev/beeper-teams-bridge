# Build stage
FROM golang:1.21-alpine AS builder

# Install build dependencies
RUN apk add --no-cache git ca-certificates build-base

# Set working directory
WORKDIR /build

# Copy go mod files
COPY go.mod go.sum* ./

# Download dependencies
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN go build -o beeper-teams-bridge \
    -ldflags "-X main.Tag=$(git describe --exact-match --tags 2>/dev/null || echo 'unknown') \
              -X main.Commit=$(git rev-parse HEAD) \
              -X 'main.BuildTime=$(date -u +%Y-%m-%d\ %H:%M:%S)'" \
    ./cmd/beeper-teams-bridge

# Runtime stage
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates su-exec

# Create non-root user
RUN adduser -D -u 1000 beeper

# Copy binary from builder
COPY --from=builder /build/beeper-teams-bridge /usr/local/bin/beeper-teams-bridge

# Copy example config
COPY --from=builder /build/pkg/connector/example-config.yaml /opt/beeper-teams-bridge/example-config.yaml

# Create data directory
RUN mkdir -p /data && chown beeper:beeper /data

# Set working directory
WORKDIR /data

# Expose port
EXPOSE 8080

# Switch to non-root user
USER beeper

# Run the bridge
ENTRYPOINT ["/usr/local/bin/beeper-teams-bridge"]
CMD ["-c", "/data/config.yaml"]
