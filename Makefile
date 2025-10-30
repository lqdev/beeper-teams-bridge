# Makefile for beeper-teams-bridge
# Run 'make help' for a list of available commands

.PHONY: help
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Variables
BINARY_NAME=beeper-teams-bridge
VERSION?=$(shell git describe --tags --always --dirty)
COMMIT=$(shell git rev-parse HEAD)
BUILD_TIME=$(shell date -u +%Y-%m-%dT%H:%M:%SZ)
GO_VERSION=$(shell go version | awk '{print $$3}')

LDFLAGS=-ldflags "\
	-X main.Version=$(VERSION) \
	-X main.Commit=$(COMMIT) \
	-X main.BuildTime=$(BUILD_TIME) \
	-X main.GoVersion=$(GO_VERSION) \
	-s -w"

# Build flags
BUILD_FLAGS=-trimpath
TEST_FLAGS=-v -race -coverprofile=coverage.txt -covermode=atomic

# Directories
CMD_DIR=./cmd/beeper-teams-bridge
PKG_DIR=./pkg/...
TEST_DIR=./test/...

# Colors for output
COLOR_RESET=\033[0m
COLOR_BOLD=\033[1m
COLOR_GREEN=\033[32m
COLOR_YELLOW=\033[33m
COLOR_BLUE=\033[34m

#
# Development
#

.PHONY: build
build: ## Build the bridge binary
	@echo "$(COLOR_BLUE)Building $(BINARY_NAME)...$(COLOR_RESET)"
	go build $(BUILD_FLAGS) $(LDFLAGS) -o $(BINARY_NAME) $(CMD_DIR)
	@echo "$(COLOR_GREEN)✓ Build complete: $(BINARY_NAME)$(COLOR_RESET)"

.PHONY: build-all
build-all: ## Build for all platforms
	@echo "$(COLOR_BLUE)Building for all platforms...$(COLOR_RESET)"
	GOOS=linux GOARCH=amd64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(BINARY_NAME)-linux-amd64 $(CMD_DIR)
	GOOS=linux GOARCH=arm64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(BINARY_NAME)-linux-arm64 $(CMD_DIR)
	GOOS=darwin GOARCH=amd64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(BINARY_NAME)-darwin-amd64 $(CMD_DIR)
	GOOS=darwin GOARCH=arm64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(BINARY_NAME)-darwin-arm64 $(CMD_DIR)
	GOOS=windows GOARCH=amd64 go build $(BUILD_FLAGS) $(LDFLAGS) -o $(BINARY_NAME)-windows-amd64.exe $(CMD_DIR)
	@echo "$(COLOR_GREEN)✓ All builds complete$(COLOR_RESET)"

.PHONY: run
run: build ## Build and run the bridge
	@echo "$(COLOR_BLUE)Running $(BINARY_NAME)...$(COLOR_RESET)"
	./$(BINARY_NAME) -c config.yaml

.PHONY: install
install: ## Install the bridge binary
	@echo "$(COLOR_BLUE)Installing $(BINARY_NAME)...$(COLOR_RESET)"
	go install $(BUILD_FLAGS) $(LDFLAGS) $(CMD_DIR)
	@echo "$(COLOR_GREEN)✓ Installed to $(shell go env GOPATH)/bin/$(BINARY_NAME)$(COLOR_RESET)"

.PHONY: clean
clean: ## Remove build artifacts
	@echo "$(COLOR_YELLOW)Cleaning build artifacts...$(COLOR_RESET)"
	rm -f $(BINARY_NAME)
	rm -f $(BINARY_NAME)-*
	rm -f coverage.txt coverage.html
	rm -rf dist/
	@echo "$(COLOR_GREEN)✓ Clean complete$(COLOR_RESET)"

#
# Testing
#

.PHONY: test
test: ## Run all tests
	@echo "$(COLOR_BLUE)Running tests...$(COLOR_RESET)"
	go test $(TEST_FLAGS) ./...
	@echo "$(COLOR_GREEN)✓ Tests passed$(COLOR_RESET)"

.PHONY: test-unit
test-unit: ## Run unit tests only
	@echo "$(COLOR_BLUE)Running unit tests...$(COLOR_RESET)"
	go test -v -short ./...
	@echo "$(COLOR_GREEN)✓ Unit tests passed$(COLOR_RESET)"

.PHONY: test-integration
test-integration: ## Run integration tests
	@echo "$(COLOR_BLUE)Running integration tests...$(COLOR_RESET)"
	go test -v -run Integration ./test/integration/...
	@echo "$(COLOR_GREEN)✓ Integration tests passed$(COLOR_RESET)"

.PHONY: test-e2e
test-e2e: ## Run end-to-end tests
	@echo "$(COLOR_BLUE)Running E2E tests...$(COLOR_RESET)"
	go test -v -run E2E ./test/e2e/...
	@echo "$(COLOR_GREEN)✓ E2E tests passed$(COLOR_RESET)"

.PHONY: test-coverage
test-coverage: ## Run tests with coverage report
	@echo "$(COLOR_BLUE)Running tests with coverage...$(COLOR_RESET)"
	go test $(TEST_FLAGS) ./...
	go tool cover -html=coverage.txt -o coverage.html
	@echo "$(COLOR_GREEN)✓ Coverage report generated: coverage.html$(COLOR_RESET)"
	@echo "Total coverage: $$(go tool cover -func=coverage.txt | grep total | awk '{print $$3}')"

.PHONY: test-watch
test-watch: ## Watch for changes and run tests
	@echo "$(COLOR_BLUE)Watching for changes...$(COLOR_RESET)"
	@which reflex > /dev/null || (echo "Install reflex: go install github.com/cespare/reflex@latest" && exit 1)
	reflex -r '\.go$$' -s -- sh -c 'clear && make test-unit'

#
# Code Quality
#

.PHONY: lint
lint: ## Run linter
	@echo "$(COLOR_BLUE)Running linter...$(COLOR_RESET)"
	@which golangci-lint > /dev/null || (echo "Install golangci-lint: https://golangci-lint.run/usage/install/" && exit 1)
	golangci-lint run --timeout=5m
	@echo "$(COLOR_GREEN)✓ Linting passed$(COLOR_RESET)"

.PHONY: lint-fix
lint-fix: ## Run linter with auto-fix
	@echo "$(COLOR_BLUE)Running linter with auto-fix...$(COLOR_RESET)"
	golangci-lint run --fix --timeout=5m
	@echo "$(COLOR_GREEN)✓ Linting complete$(COLOR_RESET)"

.PHONY: fmt
fmt: ## Format code
	@echo "$(COLOR_BLUE)Formatting code...$(COLOR_RESET)"
	go fmt ./...
	@which goimports > /dev/null && goimports -w . || echo "Tip: install goimports for better formatting"
	@echo "$(COLOR_GREEN)✓ Formatting complete$(COLOR_RESET)"

.PHONY: vet
vet: ## Run go vet
	@echo "$(COLOR_BLUE)Running go vet...$(COLOR_RESET)"
	go vet ./...
	@echo "$(COLOR_GREEN)✓ Vet passed$(COLOR_RESET)"

.PHONY: security
security: ## Run security scanner
	@echo "$(COLOR_BLUE)Running security scan...$(COLOR_RESET)"
	@which gosec > /dev/null || (echo "Install gosec: go install github.com/securego/gosec/v2/cmd/gosec@latest" && exit 1)
	gosec -quiet ./...
	@echo "$(COLOR_GREEN)✓ Security scan complete$(COLOR_RESET)"

.PHONY: check
check: fmt vet lint test ## Run all checks (fmt, vet, lint, test)
	@echo "$(COLOR_GREEN)✓ All checks passed$(COLOR_RESET)"

#
# Dependencies
#

.PHONY: deps
deps: ## Download dependencies
	@echo "$(COLOR_BLUE)Downloading dependencies...$(COLOR_RESET)"
	go mod download
	@echo "$(COLOR_GREEN)✓ Dependencies downloaded$(COLOR_RESET)"

.PHONY: deps-update
deps-update: ## Update dependencies
	@echo "$(COLOR_BLUE)Updating dependencies...$(COLOR_RESET)"
	go get -u ./...
	go mod tidy
	@echo "$(COLOR_GREEN)✓ Dependencies updated$(COLOR_RESET)"

.PHONY: deps-tidy
deps-tidy: ## Tidy dependencies
	@echo "$(COLOR_BLUE)Tidying dependencies...$(COLOR_RESET)"
	go mod tidy
	@echo "$(COLOR_GREEN)✓ Dependencies tidied$(COLOR_RESET)"

.PHONY: deps-verify
deps-verify: ## Verify dependencies
	@echo "$(COLOR_BLUE)Verifying dependencies...$(COLOR_RESET)"
	go mod verify
	@echo "$(COLOR_GREEN)✓ Dependencies verified$(COLOR_RESET)"

#
# Bridge Specific
#

.PHONY: config
config: build ## Generate example config
	@echo "$(COLOR_BLUE)Generating example config...$(COLOR_RESET)"
	./$(BINARY_NAME) -e
	@echo "$(COLOR_GREEN)✓ Config generated: config.yaml$(COLOR_RESET)"

.PHONY: registration
registration: build ## Generate appservice registration
	@echo "$(COLOR_BLUE)Generating registration...$(COLOR_RESET)"
	./$(BINARY_NAME) -g
	@echo "$(COLOR_GREEN)✓ Registration generated: registration.yaml$(COLOR_RESET)"

#
# Docker
#

.PHONY: docker-build
docker-build: ## Build Docker image
	@echo "$(COLOR_BLUE)Building Docker image...$(COLOR_RESET)"
	docker build -t $(BINARY_NAME):latest .
	docker build -t $(BINARY_NAME):$(VERSION) .
	@echo "$(COLOR_GREEN)✓ Docker images built$(COLOR_RESET)"

.PHONY: docker-run
docker-run: ## Run Docker container
	@echo "$(COLOR_BLUE)Running Docker container...$(COLOR_RESET)"
	docker run -d \
		--name $(BINARY_NAME) \
		-v $$(pwd):/data \
		-p 29319:29319 \
		$(BINARY_NAME):latest

.PHONY: docker-stop
docker-stop: ## Stop Docker container
	@echo "$(COLOR_YELLOW)Stopping Docker container...$(COLOR_RESET)"
	docker stop $(BINARY_NAME) || true
	docker rm $(BINARY_NAME) || true

.PHONY: docker-logs
docker-logs: ## View Docker logs
	docker logs -f $(BINARY_NAME)

.PHONY: docker-shell
docker-shell: ## Shell into Docker container
	docker exec -it $(BINARY_NAME) sh

#
# Database
#

.PHONY: db-start
db-start: ## Start PostgreSQL in Docker
	@echo "$(COLOR_BLUE)Starting PostgreSQL...$(COLOR_RESET)"
	docker run -d \
		--name mautrix-teams-db \
		-e POSTGRES_PASSWORD=mautrix \
		-e POSTGRES_USER=mautrix \
		-e POSTGRES_DB=mautrix_teams \
		-p 5432:5432 \
		postgres:15

.PHONY: db-stop
db-stop: ## Stop PostgreSQL
	@echo "$(COLOR_YELLOW)Stopping PostgreSQL...$(COLOR_RESET)"
	docker stop mautrix-teams-db || true
	docker rm mautrix-teams-db || true

.PHONY: db-logs
db-logs: ## View PostgreSQL logs
	docker logs -f mautrix-teams-db

.PHONY: db-shell
db-shell: ## Connect to PostgreSQL
	docker exec -it mautrix-teams-db psql -U mautrix -d mautrix_teams

#
# Development Environment
#

.PHONY: dev-setup
dev-setup: ## Set up development environment
	@echo "$(COLOR_BLUE)Setting up development environment...$(COLOR_RESET)"
	@which go > /dev/null || (echo "Go is not installed" && exit 1)
	@which docker > /dev/null || (echo "Docker is not installed" && exit 1)
	@which git > /dev/null || (echo "Git is not installed" && exit 1)
	go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
	go install github.com/securego/gosec/v2/cmd/gosec@latest
	go install golang.org/x/tools/cmd/goimports@latest
	go mod download
	@echo "$(COLOR_GREEN)✓ Development environment ready$(COLOR_RESET)"

.PHONY: dev-start
dev-start: db-start ## Start development environment
	@echo "$(COLOR_GREEN)✓ Development environment started$(COLOR_RESET)"
	@echo "  Database: localhost:5432"
	@echo "  User: mautrix"
	@echo "  Database: mautrix_teams"

.PHONY: dev-stop
dev-stop: db-stop docker-stop ## Stop development environment
	@echo "$(COLOR_GREEN)✓ Development environment stopped$(COLOR_RESET)"

#
# Git Hooks
#

.PHONY: hooks-install
hooks-install: ## Install git hooks
	@echo "$(COLOR_BLUE)Installing git hooks...$(COLOR_RESET)"
	@which pre-commit > /dev/null || (echo "Install pre-commit: pip install pre-commit" && exit 1)
	pre-commit install
	@echo "$(COLOR_GREEN)✓ Git hooks installed$(COLOR_RESET)"

#
# Documentation
#

.PHONY: docs
docs: ## Generate documentation
	@echo "$(COLOR_BLUE)Generating documentation...$(COLOR_RESET)"
	@which godoc > /dev/null || go install golang.org/x/tools/cmd/godoc@latest
	@echo "$(COLOR_GREEN)✓ Documentation generated$(COLOR_RESET)"
	@echo "View at: http://localhost:6060/pkg/github.com/yourorg/mautrix-teams/"
	godoc -http=:6060

.PHONY: docs-serve
docs-serve: ## Serve documentation locally
	@which godoc > /dev/null || go install golang.org/x/tools/cmd/godoc@latest
	@echo "$(COLOR_BLUE)Serving documentation at http://localhost:6060$(COLOR_RESET)"
	godoc -http=:6060

#
# Release
#

.PHONY: release-check
release-check: ## Check if ready for release
	@echo "$(COLOR_BLUE)Checking release readiness...$(COLOR_RESET)"
	@git diff-index --quiet HEAD || (echo "❌ Uncommitted changes" && exit 1)
	@test -z "$$(git status --porcelain)" || (echo "❌ Untracked files" && exit 1)
	@make test > /dev/null || (echo "❌ Tests failing" && exit 1)
	@make lint > /dev/null || (echo "❌ Linting issues" && exit 1)
	@echo "$(COLOR_GREEN)✓ Ready for release$(COLOR_RESET)"

.PHONY: release-tag
release-tag: release-check ## Create release tag
	@read -p "Enter version (e.g., v1.0.0): " version; \
	git tag -a $$version -m "Release $$version"; \
	git push origin $$version; \
	echo "$(COLOR_GREEN)✓ Tag $$version created and pushed$(COLOR_RESET)"

#
# Utilities
#

.PHONY: version
version: ## Show version information
	@echo "Version: $(VERSION)"
	@echo "Commit:  $(COMMIT)"
	@echo "Built:   $(BUILD_TIME)"
	@echo "Go:      $(GO_VERSION)"

.PHONY: info
info: ## Show project information
	@echo "Project: $(BINARY_NAME)"
	@echo "Version: $(VERSION)"
	@echo ""
	@echo "Go version:     $(GO_VERSION)"
	@echo "Go modules:     $$(go list -m all | wc -l) packages"
	@echo "Go files:       $$(find . -name '*.go' -not -path './vendor/*' | wc -l)"
	@echo "Lines of code:  $$(find . -name '*.go' -not -path './vendor/*' | xargs wc -l | tail -n1 | awk '{print $$1}')"
	@echo ""
	@echo "Database:       PostgreSQL 10+"
	@echo "License:        MIT"

.PHONY: todo
todo: ## Show TODO comments in code
	@echo "$(COLOR_YELLOW)TODO items:$(COLOR_RESET)"
	@grep -rn "TODO" --include="*.go" . || echo "No TODOs found!"

.PHONY: fixme
fixme: ## Show FIXME comments in code
	@echo "$(COLOR_YELLOW)FIXME items:$(COLOR_RESET)"
	@grep -rn "FIXME" --include="*.go" . || echo "No FIXMEs found!"

#
# CI/CD
#

.PHONY: ci
ci: deps check test ## Run CI pipeline locally
	@echo "$(COLOR_GREEN)✓ CI checks passed$(COLOR_RESET)"

.PHONY: pre-commit
pre-commit: fmt lint test-unit ## Run pre-commit checks
	@echo "$(COLOR_GREEN)✓ Pre-commit checks passed$(COLOR_RESET)"

.PHONY: pre-push
pre-push: check ## Run pre-push checks
	@echo "$(COLOR_GREEN)✓ Pre-push checks passed$(COLOR_RESET)"

#
# Default
#

.DEFAULT_GOAL := help
