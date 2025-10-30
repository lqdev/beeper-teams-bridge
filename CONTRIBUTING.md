# Contributing to mautrix-teams

Thank you for your interest in contributing to mautrix-teams! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

Be respectful and considerate of others. We want to maintain a welcoming and inclusive environment for all contributors.

## Getting Started

### Prerequisites

* Go 1.21 or higher
* Git
* A Matrix homeserver for testing (you can use a local synapse instance)
* A Microsoft Teams account for testing

### Setting Up Your Development Environment

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/beeper-teams-bridge.git
   cd beeper-teams-bridge
   ```

3. **Add the upstream repository**:
   ```bash
   git remote add upstream https://github.com/lqdev/beeper-teams-bridge.git
   ```

4. **Install dependencies**:
   ```bash
   go mod download
   ```

5. **Build the project**:
   ```bash
   go build -o mautrix-teams
   ```

6. **Run tests**:
   ```bash
   go test ./...
   ```

## Development Workflow

### Creating a Branch

Create a new branch for your feature or bug fix:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

Use descriptive branch names:
* `feature/` for new features
* `fix/` for bug fixes
* `docs/` for documentation changes
* `refactor/` for code refactoring

### Making Changes

1. **Write clean, readable code** that follows Go conventions
2. **Add tests** for new functionality
3. **Update documentation** as needed
4. **Keep commits atomic** - each commit should represent a single logical change
5. **Write clear commit messages** following this format:
   ```
   Short (50 chars or less) summary

   More detailed explanatory text, if necessary. Wrap it to about 72
   characters. The blank line separating the summary from the body is
   critical.

   - Bullet points are okay
   - Use present tense ("Add feature" not "Added feature")
   - Reference issues and pull requests liberally
   ```

### Code Style

* Follow the [Go Code Review Comments](https://github.com/golang/go/wiki/CodeReviewComments)
* Use `gofmt` to format your code
* Use `golangci-lint` for linting:
  ```bash
  golangci-lint run
  ```
* Keep functions small and focused
* Add comments for exported functions and types
* Use meaningful variable and function names

### Testing

* Write unit tests for new functionality
* Ensure all tests pass before submitting a PR:
  ```bash
  go test ./...
  ```
* Add integration tests for complex features
* Aim for good test coverage of critical paths

### Running the Bridge Locally

1. Copy the example configuration:
   ```bash
   cp example-config.yaml config.yaml
   ```

2. Edit `config.yaml` with your test homeserver settings

3. Generate registration:
   ```bash
   ./mautrix-teams -g
   ```

4. Run the bridge:
   ```bash
   ./mautrix-teams
   ```

## Submitting a Pull Request

1. **Update your branch** with the latest changes from upstream:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run tests** and ensure they pass:
   ```bash
   go test ./...
   ```

3. **Run linters**:
   ```bash
   golangci-lint run
   ```

4. **Push your branch** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Open a Pull Request** on GitHub with:
   * A clear title describing the change
   * A detailed description of what the PR does
   * Reference to any related issues
   * Screenshots if applicable (for UI changes)

### Pull Request Guidelines

* **Keep PRs focused** - one feature or fix per PR
* **Provide context** - explain why the change is needed
* **Be responsive** - address review comments promptly
* **Update documentation** - if your change affects user-facing behavior
* **Add changelog entries** - for notable changes

## Reporting Bugs

When reporting bugs, please include:

* **Description** of the issue
* **Steps to reproduce** the problem
* **Expected behavior** vs actual behavior
* **Environment details** (OS, Go version, bridge version)
* **Relevant logs** (with sensitive information removed)
* **Configuration** (sanitized, without tokens or passwords)

## Requesting Features

When requesting features:

* **Check existing issues** first to avoid duplicates
* **Describe the use case** - why is this feature needed?
* **Provide examples** of how it would work
* **Consider implementation** - suggest how it could be built

## Project Structure

```
beeper-teams-bridge/
├── bridge/          # Core bridge logic
├── config/          # Configuration handling
├── database/        # Database models and migrations
├── teams/           # Microsoft Teams API client
├── portal/          # Portal (room) management
├── puppet/          # Puppet (ghost user) management
├── commands/        # Bridge bot commands
├── main.go          # Entry point
└── example-config.yaml
```

## Resources

* [mautrix-go documentation](https://pkg.go.dev/maunium.net/go/mautrix)
* [Matrix Specification](https://spec.matrix.org/)
* [Microsoft Teams API documentation](https://docs.microsoft.com/en-us/graph/api/resources/teams-api-overview)
* [Go documentation](https://golang.org/doc/)

## Getting Help

* **GitHub Issues** - for bug reports and feature requests
* **Matrix Room** - [#mautrix-teams:maunium.net](https://matrix.to/#/#mautrix-teams:maunium.net) for questions and discussion

## License

By contributing to mautrix-teams, you agree that your contributions will be licensed under the MIT License.

## Recognition

Contributors will be recognized in the project's documentation and changelog. Thank you for helping make mautrix-teams better!
