# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial project setup
- Core bridge architecture
- OAuth 2.0 authentication flow
- Webhook infrastructure for receiving Teams messages
- Message bridging (Teams ↔ Matrix)
- Support for text messages
- Support for media attachments
- Reaction support
- Message edit and delete support
- Portal room management
- Ghost user creation
- Configuration system
- Database schema
- Logging framework

### Changed
- Nothing yet

### Deprecated
- Nothing yet

### Removed
- Nothing yet

### Fixed
- Nothing yet

### Security
- Implemented token encryption at rest
- Added webhook signature validation
- HTTPS enforcement for webhook endpoints

---

## [0.1.0] - 2025-XX-XX (Initial Alpha Release)

### Added
- Basic message bridging functionality
- OAuth login flow
- Webhook event processing
- PostgreSQL database support
- Docker deployment support
- Systemd service configuration
- CI/CD pipeline
- Unit test framework
- Integration test framework
- Basic documentation

---

## Release Template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```

---

[Unreleased]: https://github.com/yourorg/beeper-teams-bridge/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/yourorg/beeper-teams-bridge/releases/tag/v0.1.0
