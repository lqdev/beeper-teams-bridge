.PHONY: all build clean test lint run docker-build docker-up docker-down help

# Binary name
BINARY_NAME=mautrix-teams

# Build variables
BUILD_DIR=build
VERSION?=0.1.0
COMMIT=$(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME=$(shell date -u '+%Y-%m-%d %H:%M:%S')
TAG=$(shell git describe --exact-match --tags 2>/dev/null || echo "dev")

# Go variables
GOBASE=$(shell pwd)
GOBIN=$(GOBASE)/$(BUILD_DIR)
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X 'main.BuildTime=$(BUILD_TIME)' -X main.Tag=$(TAG)"

all: help

## build: Build the binary
build:
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BUILD_DIR)
	@go build $(LDFLAGS) -o $(GOBIN)/$(BINARY_NAME) .
	@echo "Binary built at $(GOBIN)/$(BINARY_NAME)"

## clean: Clean build artifacts
clean:
	@echo "Cleaning..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(BINARY_NAME)
	@go clean
	@echo "Cleaned successfully"

## test: Run tests
test:
	@echo "Running tests..."
	@go test -v ./...

## test-coverage: Run tests with coverage
test-coverage:
	@echo "Running tests with coverage..."
	@go test -v -coverprofile=coverage.out ./...
	@go tool cover -html=coverage.out -o coverage.html
	@echo "Coverage report generated at coverage.html"

## lint: Run linters
lint:
	@echo "Running linters..."
	@which golangci-lint > /dev/null || (echo "golangci-lint not found, installing..." && go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest)
	@golangci-lint run

## format: Format code
format:
	@echo "Formatting code..."
	@go fmt ./...
	@gofmt -s -w .

## run: Build and run the bridge
run: build
	@echo "Running $(BINARY_NAME)..."
	@$(GOBIN)/$(BINARY_NAME)

## deps: Download dependencies
deps:
	@echo "Downloading dependencies..."
	@go mod download
	@go mod tidy

## docker-build: Build Docker image
docker-build:
	@echo "Building Docker image..."
	@docker build -t $(BINARY_NAME):$(VERSION) .

## docker-up: Start services with docker-compose
docker-up:
	@echo "Starting services..."
	@docker-compose up -d

## docker-down: Stop services with docker-compose
docker-down:
	@echo "Stopping services..."
	@docker-compose down

## docker-logs: Show docker-compose logs
docker-logs:
	@docker-compose logs -f

## help: Show this help message
help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' | sed -e 's/^/ /'
