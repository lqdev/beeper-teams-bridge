# Contributing to mautrix-teams

Thank you for your interest in contributing to mautrix-teams! This document provides guidelines and instructions for contributing.

## Code of Conduct

### Our Pledge

We as members, contributors, and leaders pledge to make participation in our community a harassment-free experience for everyone, regardless of age, body size, visible or invisible disability, ethnicity, sex characteristics, gender identity and expression, level of experience, education, socio-economic status, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behavior includes:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community
- Showing empathy towards other community members

**Unacceptable behavior includes:**
- Trolling, insulting/derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission
- Other conduct which could reasonably be considered inappropriate in a professional setting

## Getting Started

### Prerequisites

Before you begin, ensure you have:
- Go 1.24 or higher installed
- PostgreSQL 10+ for local testing
- Git configured with your name and email
- A GitHub account
- (Optional) Docker for containerized testing

### Setting Up Your Development Environment

1. **Fork the repository**
   ```bash
   # Click "Fork" on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/mautrix-teams.git
   cd mautrix-teams
   ```

2. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/mautrix-teams.git
   ```

3. **Install dependencies**
   ```bash
   go mod download
   ```

4. **Set up pre-commit hooks**
   ```bash
   # Install pre-commit (if not already installed)
   pip install pre-commit
   
   # Install the git hooks
   pre-commit install
   ```

5. **Create a development config**
   ```bash
   cp example-config.yaml config.yaml
   # Edit config.yaml with your test credentials
   ```

6. **Set up test database**
   ```bash
   # Using Docker
   docker run -d \
     --name mautrix-teams-test-db \
     -e POSTGRES_PASSWORD=test \
     -e POSTGRES_DB=mautrix_teams_test \
     -p 5432:5432 \
     postgres:15
   ```

## Development Workflow

### Branch Strategy

1. **Create a feature branch**
   ```bash
   git checkout develop
   git pull upstream develop
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code following our [coding standards](#coding-standards)
   - Add tests for new functionality
   - Update documentation as needed

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat(scope): brief description
   
   Longer description of what changed and why.
   
   Closes #123"
   ```

4. **Keep your branch updated**
   ```bash
   git fetch upstream
   git rebase upstream/develop
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create a Pull Request**
   - Go to GitHub and create a PR from your fork to the main repository
   - Fill out the PR template completely
   - Link any related issues

### Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/) for clear and structured commit messages.

**Format:**
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, semicolons, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks
- `ci`: CI/CD changes

**Scopes:**
- `auth`: Authentication/OAuth
- `webhook`: Webhook handling
- `message`: Message bridging
- `portal`: Portal management
- `config`: Configuration
- `db`: Database
- `api`: Graph API integration

**Examples:**
```
feat(auth): add PKCE support to OAuth flow

Implements PKCE (Proof Key for Code Exchange) for enhanced
security in the OAuth authorization flow.

Closes #42

---

fix(webhook): handle missing signature gracefully

Previously the bridge would panic when receiving a webhook
without a signature header. Now it returns 401 Unauthorized.

Fixes #127

---

docs: update setup instructions for Azure AD

Added more detailed steps for configuring the Azure AD
application and granting admin consent.
```

## Coding Standards

### Go Style Guide

We follow the official [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments) and [Effective Go](https://go.dev/doc/effective_go).

**Key points:**

1. **Formatting**
   - Use `gofmt` (or `goimports`) to format all code
   - Use tabs for indentation
   - Keep line length reasonable (~100 characters)

2. **Naming**
   - Use `MixedCaps` or `mixedCaps` (not underscores)
   - Keep names short but descriptive
   - Use single-letter names only for short scopes
   - Prefer `i` for indices, `r` for readers, `w` for writers

3. **Comments**
   - Document all exported functions, types, and constants
   - Use complete sentences
   - Start with the name of the thing being described
   ```go
   // SendMessage sends a text message to the specified Teams chat.
   // It returns the message ID or an error if sending fails.
   func SendMessage(ctx context.Context, chatID, text string) (string, error) {
   ```

4. **Error Handling**
   - Always check errors
   - Wrap errors with context using `fmt.Errorf` with `%w`
   - Use custom error types for domain-specific errors
   ```go
   if err != nil {
       return fmt.Errorf("failed to send message: %w", err)
   }
   ```

5. **Interfaces**
   - Keep interfaces small and focused
   - Define interfaces in the consumer package, not the implementer
   - Use descriptive names ending in "-er" when appropriate

### Testing Standards

**All code must include tests:**

1. **Unit Tests**
   - Test all public functions
   - Use table-driven tests where appropriate
   - Use the `testing` package and `testify/assert`
   - Mock external dependencies
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
       }
       
       for _, tt := range tests {
           t.Run(tt.name, func(t *testing.T) {
               // Test implementation
           })
       }
   }
   ```

2. **Integration Tests**
   - Place in `test/integration/` directory
   - Skip with `testing.Short()` for quick runs
   - Clean up resources in `defer` or `t.Cleanup()`

3. **Coverage**
   - Aim for >80% code coverage
   - Check coverage with `go test -cover`
   - View detailed coverage: `go tool cover -html=coverage.out`

### Code Review Checklist

Before submitting a PR, ensure:

- [ ] Code follows Go style guidelines
- [ ] All tests pass (`make test`)
- [ ] New code has appropriate test coverage
- [ ] Documentation is updated
- [ ] Commit messages follow conventional format
- [ ] No merge conflicts with develop branch
- [ ] PR description is complete
- [ ] Related issues are linked
- [ ] No secrets or credentials in code
- [ ] Linter passes (`make lint`)

## Pull Request Process

### Creating a PR

1. **Fill out the PR template** completely
   - Describe what changed and why
   - List any breaking changes
   - Include screenshots for UI changes

2. **Link related issues**
   - Use "Closes #123" for issues fixed by this PR
   - Use "Relates to #456" for related issues

3. **Request reviews**
   - Tag specific reviewers if needed
   - Be responsive to review comments

### Review Process

**As a reviewer:**
- Review within 24-48 hours
- Be constructive and respectful
- Ask questions to understand decisions
- Approve if changes are acceptable
- Request changes if issues need addressing

**As an author:**
- Respond to all comments
- Make requested changes or explain why not
- Re-request review after making changes
- Keep PR scope focused and manageable

### Merging

- PRs must have at least 1 approval
- All CI checks must pass
- Branch must be up to date with develop
- Squash commits for clean history (if many small commits)
- Merge commits are fine for larger features

## Types of Contributions

### Bug Reports

**Before submitting:**
- Search existing issues to avoid duplicates
- Verify the bug on the latest version
- Collect relevant information (logs, config, versions)

**Use the bug report template and include:**
- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details (OS, Go version, etc.)
- Relevant log excerpts (redact secrets!)

### Feature Requests

**Before submitting:**
- Check if the feature already exists or is planned
- Consider if it fits the project scope

**Use the feature request template and include:**
- Clear description of the desired functionality
- Use cases and examples
- Potential implementation approach
- Willingness to implement it yourself

### Documentation Improvements

Documentation improvements are always welcome!

- Fix typos or unclear wording
- Add examples or clarifications
- Update outdated information
- Translate documentation

### Code Contributions

**Good first contributions:**
- Look for issues labeled `good first issue`
- Fix bugs labeled `easy`
- Improve test coverage
- Add missing documentation

**Larger contributions:**
- Discuss in an issue first
- Break into smaller PRs if possible
- Provide thorough testing
- Update documentation

## Testing

### Running Tests

```bash
# Run all tests
make test

# Run only unit tests
make test-unit

# Run with coverage
make test-coverage

# Run specific test
go test -v -run TestSendMessage ./pkg/connector/

# Run with race detector
go test -race ./...
```

### Writing Tests

**Unit test example:**
```go
func TestTeamsClient_SendMessage(t *testing.T) {
    // Setup
    mockAPI := new(MockGraphAPI)
    mockAPI.On("SendMessage", mock.Anything, "chat123", "Hello").
        Return("msg456", nil)
    
    client := &TeamsClient{
        graphAPI: mockAPI,
    }
    
    // Execute
    msgID, err := client.SendMessage(context.Background(), "chat123", "Hello")
    
    // Assert
    assert.NoError(t, err)
    assert.Equal(t, "msg456", msgID)
    mockAPI.AssertExpectations(t)
}
```

**Integration test example:**
```go
func TestGraphAPI_Integration(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    
    // Setup real API client
    client := setupRealClient(t)
    defer client.Cleanup()
    
    // Test actual API call
    msgID, err := client.SendMessage(context.Background(), testChatID, "Test")
    assert.NoError(t, err)
    assert.NotEmpty(t, msgID)
    
    // Cleanup
    client.DeleteMessage(context.Background(), testChatID, msgID)
}
```

## Documentation

### Code Documentation

- Document all exported functions, types, and constants
- Use godoc format
- Include examples for complex functions

```go
// SendMessage sends a text message to a Teams chat or channel.
//
// The function automatically handles:
//   - Markdown to HTML conversion
//   - Rate limiting
//   - Automatic retry on transient failures
//
// Example:
//
//	msgID, err := client.SendMessage(ctx, "chat:abc123", "Hello, world!")
//	if err != nil {
//	    log.Fatal(err)
//	}
//	fmt.Printf("Message sent with ID: %s\n", msgID)
func SendMessage(ctx context.Context, portalID, text string) (string, error) {
    // Implementation
}
```

### User Documentation

Update documentation in the `docs/` directory:
- `docs/setup.md` - Setup and installation
- `docs/configuration.md` - Configuration reference
- `docs/troubleshooting.md` - Common issues and solutions
- `docs/api.md` - API documentation

### README Updates

Keep the README up to date with:
- Feature list
- Installation instructions
- Quick start guide
- Links to detailed documentation

## Release Process

### Version Numbering

We use [Semantic Versioning](https://semver.org/):
- MAJOR: Breaking changes
- MINOR: New features (backwards compatible)
- PATCH: Bug fixes

### Creating a Release

1. **Update CHANGELOG.md**
   ```markdown
   ## [1.2.0] - 2025-10-30
   
   ### Added
   - New OAuth PKCE support
   
   ### Fixed
   - Webhook signature validation
   
   ### Changed
   - Improved error messages
   ```

2. **Tag the release**
   ```bash
   git tag -a v1.2.0 -m "Release v1.2.0"
   git push origin v1.2.0
   ```

3. **GitHub Actions will automatically:**
   - Run all tests
   - Build binaries
   - Create GitHub release
   - Build and push Docker image

## Getting Help

### Communication Channels

- **Matrix Room:** [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net)
- **GitHub Issues:** For bugs and feature requests
- **GitHub Discussions:** For questions and general discussion

### Asking Questions

**Good questions include:**
- What you're trying to accomplish
- What you've already tried
- Relevant code snippets (without secrets!)
- Error messages (full text, not screenshots)
- Version information

## Recognition

Contributors are recognized in:
- CHANGELOG.md (for each release)
- GitHub contributors page
- Special mention for significant contributions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

## Quick Reference

### Common Commands

```bash
# Development
make build          # Build the bridge
make run            # Run the bridge
make test           # Run all tests
make lint           # Run linter
make fmt            # Format code

# Git
git checkout develop
git pull upstream develop
git checkout -b feature/my-feature
git commit -m "feat(scope): description"
git push origin feature/my-feature

# Testing
go test ./...                    # All tests
go test -short ./...             # Skip integration
go test -cover ./...             # With coverage
go test -v -run TestName ./...   # Specific test
```

### Useful Links

- [Go Documentation](https://go.dev/doc/)
- [Effective Go](https://go.dev/doc/effective_go)
- [Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [mautrix-go Documentation](https://pkg.go.dev/maunium.net/go/mautrix)

---

Thank you for contributing to mautrix-teams! 🎉
