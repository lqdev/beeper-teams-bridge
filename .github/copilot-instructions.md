# Copilot Instructions for beeper-teams-bridge

This document provides context and guidance for GitHub Copilot when working on the beeper-teams-bridge project.

## Project Overview

beeper-teams-bridge is a Matrix bridge for Microsoft Teams, built with [mautrix-go](https://github.com/mautrix/go). It enables bidirectional message bridging between Matrix and Microsoft Teams, allowing users to send and receive messages, files, reactions, and more across both platforms.

### Key Features
- Two-way message bridging between Matrix and Teams
- OAuth 2.0 authentication with Microsoft
- Real-time message sync via webhooks
- Support for media, reactions, edits, and deletions
- Team channels, 1:1 chats, and group chats
- Double puppeting and ghost users

## Technology Stack

- **Language**: Go 1.21+
- **Framework**: mautrix-go bridge framework
- **Database**: PostgreSQL 10+
- **External APIs**: Microsoft Graph API
- **Protocols**: Matrix Application Service API
- **Container**: Docker

## Project Structure

```
beeper-teams-bridge/
├── cmd/beeper-teams-bridge/    # Main application entry point
│   ├── main.go                 # Application entry point and CLI
│   └── main_test.go            # Basic tests for main package
├── pkg/                        # Core packages
│   └── connector/              # Bridge connector implementation
│       ├── config.go           # Configuration structures
│       └── database.go         # Database interactions
├── docs/                       # Documentation
│   ├── setup.md                # Setup instructions
│   ├── configuration.md        # Configuration reference
│   ├── architecture.md         # Technical architecture
│   └── troubleshooting.md      # Troubleshooting guide
├── scripts/                    # Build and utility scripts
├── Makefile                    # Build automation
├── Dockerfile                  # Container image definition
└── docker-compose.yaml         # Development environment
```

## Build, Test, and Development Commands

### Building
```bash
make build              # Build the bridge binary
make build-all          # Build for all platforms
make install            # Install to $GOPATH/bin
```

### Testing
```bash
make test               # Run all tests with coverage
make test-unit          # Run unit tests only
make test-integration   # Run integration tests
make test-coverage      # Generate coverage report
```

### Code Quality
```bash
make lint               # Run golangci-lint
make lint-fix           # Run linter with auto-fix
make fmt                # Format code with gofmt
make vet                # Run go vet
make check              # Run all checks (fmt, vet, lint, test)
```

### Development
```bash
make dev-setup          # Set up development environment
make dev-start          # Start dev environment (database)
make run                # Build and run the bridge
```

### Other Useful Commands
```bash
make clean              # Remove build artifacts
make deps               # Download dependencies
make deps-tidy          # Tidy go.mod and go.sum
make config             # Generate example config
make registration       # Generate appservice registration
```

## Coding Standards

### Go Style
- Follow [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- Use `gofmt` for formatting (tabs, not spaces)
- Use `goimports` for import organization
- Keep lines around 100 characters
- Use descriptive variable names (avoid single letters except in short scopes)

### Naming Conventions
- Use `MixedCaps` or `mixedCaps` (not snake_case or kebab-case)
- Exported functions/types start with uppercase
- Unexported functions/types start with lowercase
- Package names should be short, lowercase, single-word if possible

### Error Handling
- Always check and handle errors
- Wrap errors with context using `fmt.Errorf` with `%w` verb
- Use custom error types for domain-specific errors
- Don't panic except in truly exceptional cases

Example:
```go
if err != nil {
    return fmt.Errorf("failed to send message to chat %s: %w", chatID, err)
}
```

### Comments and Documentation
- Document all exported functions, types, constants, and packages
- Use complete sentences starting with the name being documented
- Include examples for complex functionality
- Keep comments up to date with code changes

Example:
```go
// SendMessage sends a text message to the specified Teams chat or channel.
// It returns the message ID on success or an error if the operation fails.
//
// The message text supports Markdown formatting which is automatically
// converted to HTML for Teams compatibility.
func SendMessage(ctx context.Context, chatID, text string) (string, error) {
    // Implementation
}
```

### Testing
- Write tests for all new functionality
- Use table-driven tests for multiple test cases
- Mock external dependencies (API calls, database)
- Use `testify/assert` for assertions
- Aim for >80% code coverage
- Integration tests should skip with `testing.Short()`

Example:
```go
func TestSendMessage(t *testing.T) {
    tests := []struct {
        name    string
        chatID  string
        text    string
        wantErr bool
    }{
        {"valid message", "chat123", "Hello", false},
        {"empty chat ID", "", "Hello", true},
        {"empty text", "chat123", "", true},
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Test implementation
        })
    }
}
```

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`

**Scopes**: `auth`, `webhook`, `message`, `portal`, `config`, `db`, `api`

**Examples**:
```
feat(auth): add PKCE support to OAuth flow
fix(webhook): handle missing signature gracefully
docs: update setup instructions for Azure AD
```

## Common Patterns

### Context Usage
Always pass `context.Context` as the first parameter for functions that:
- Make network calls
- Access databases
- May be long-running
- Should be cancellable

```go
func FetchMessages(ctx context.Context, chatID string, limit int) ([]*Message, error) {
    // Implementation
}
```

### Configuration
Configuration is loaded from YAML files and follows this pattern:
```go
type Config struct {
    Homeserver HomeserverConfig `yaml:"homeserver"`
    AppService AppServiceConfig `yaml:"appservice"`
    Network    NetworkConfig    `yaml:"network"`
    Database   DatabaseConfig   `yaml:"database"`
}
```

### Logging
Use structured logging with appropriate log levels:
```go
log.Info().Str("chatID", chatID).Msg("Sending message")
log.Error().Err(err).Str("chatID", chatID).Msg("Failed to send message")
log.Debug().Interface("message", msg).Msg("Received message")
```

### Database Interactions
- Use prepared statements or query builders
- Always use transactions for multiple related operations
- Handle connection errors gracefully
- Use context for query cancellation

## Microsoft Graph API Integration

### Authentication
- Uses OAuth 2.0 with delegated permissions
- Token refresh handled automatically
- Tokens stored encrypted in database

### API Calls
- Always include proper error handling
- Respect rate limits (implement backoff/retry)
- Use appropriate Graph API versions
- Include telemetry headers

### Webhooks
- Validate webhook signatures
- Handle subscription renewals
- Process notifications asynchronously
- Implement idempotency for webhook events

## Matrix Integration

### Appservice Protocol
- Bridge runs as Matrix appservice
- Registers with homeserver via registration.yaml
- Receives events via appservice transaction API
- Manages virtual users (ghosts)

### Portal Management
- Each Teams chat/channel maps to a Matrix room
- Portals created on-demand
- Room metadata synced from Teams
- Message history backfill support (planned)

## Dependencies

Key dependencies:
- `maunium.net/go/mautrix` - Matrix bridge framework
- `github.com/lib/pq` - PostgreSQL driver
- Standard library for HTTP, JSON, crypto

## Security Considerations

- Never commit secrets or credentials
- Use environment variables or secure config for sensitive data
- Validate all webhook signatures
- Encrypt tokens at rest
- Sanitize user input before sending to APIs
- Follow OAuth 2.0 best practices (PKCE)

## Common Tasks

### Adding a New Bot Command
1. Define command in command handler
2. Add help text for the command
3. Implement command logic in handler function
4. Add tests for the command
5. Update user documentation

### Adding a New Message Type
1. Define the message structure
2. Implement conversion from Matrix format
3. Implement conversion to Teams format
4. Handle in the message bridge
5. Add tests for conversion logic

### Adding a New Configuration Option
1. Add field to appropriate config struct
2. Update example config generation
3. Validate the config value
4. Document in `docs/configuration.md`
5. Update config tests

## Troubleshooting Common Issues

### Build Failures
- Ensure Go 1.21+ is installed
- Run `go mod download` to fetch dependencies
- Check for syntax errors with `go vet`

### Test Failures
- Check if PostgreSQL is running for integration tests
- Verify test data is properly mocked
- Run with `-v` flag for verbose output

### Linter Errors
- Run `make lint-fix` for auto-fixable issues
- Check `.golangci.yml` for enabled linters
- Follow Go style guidelines

## Documentation

- User-facing docs in `docs/` directory
- Code documentation via godoc comments
- README.md for quick start and overview
- CONTRIBUTING.md for development guidelines

## Useful Resources

- [mautrix-go documentation](https://pkg.go.dev/maunium.net/go/mautrix)
- [Microsoft Graph API reference](https://docs.microsoft.com/en-us/graph/api/overview)
- [Matrix Spec](https://spec.matrix.org/)
- [Go by Example](https://gobyexample.com/)
- [Effective Go](https://go.dev/doc/effective_go)

## Notes for AI Assistance

- This is a Matrix bridge project following mautrix conventions
- The bridge acts as middleware between Matrix and Teams
- Most message handling involves format conversion between platforms
- Configuration follows YAML format common in mautrix bridges
- The project uses standard Go tooling and conventions
- Tests should mock external API calls to avoid real API dependencies
- Always maintain backward compatibility unless explicitly breaking changes
