# Microsoft Teams Matrix Bridge - Product Requirements Document & Technical Specification

**Project Name:** beeper-teams-bridge  
**Version:** 1.0  
**Status:** Planning  
**Author:** Development Team  
**Last Updated:** October 30, 2025

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Project Overview](#project-overview)
3. [Goals & Success Metrics](#goals--success-metrics)
4. [Technical Architecture](#technical-architecture)
5. [Detailed Requirements](#detailed-requirements)
6. [Implementation Roadmap](#implementation-roadmap)
7. [Development Standards & Best Practices](#development-standards--best-practices)
8. [Repository Setup](#repository-setup)
9. [Testing Strategy](#testing-strategy)
10. [Deployment & Operations](#deployment--operations)
11. [Risk Assessment](#risk-assessment)
12. [Appendices](#appendices)

---

## Executive Summary

### Purpose
Build a Matrix bridge for Microsoft Teams that enables Beeper users to send and receive messages from Teams channels and chats within the Beeper application. This bridge will use the mautrix-go bridgev2 framework and Microsoft Graph API.

### Business Value
- Enables Beeper to support Microsoft Teams, a widely-used enterprise communication platform
- Potential bounty payment up to $50,000 from Beeper
- Fills a significant gap in Matrix bridge ecosystem
- Enterprise/business user acquisition opportunity

### Key Deliverables
1. Fully functional Teams bridge supporting channels and DMs
2. OAuth 2.0 authentication flow
3. Real-time message synchronization via webhooks
4. Open-source repository with MIT License
5. Comprehensive documentation

---

## Project Overview

### Background
Microsoft Teams is a major enterprise communication platform with millions of users. Currently, there is no open-source Matrix bridge for Teams. This project will create a production-ready bridge using the mautrix-go bridgev2 framework, following established patterns from existing bridges like mautrix-whatsapp and the official Twilio bridge example.

### Scope

#### In Scope
- **Authentication:** OAuth 2.0 flow with Azure AD
- **Message Types:** Text, images, files, replies, reactions, edits, deletions
- **Conversation Types:** 1:1 chats, group chats, team channels
- **Real-time Sync:** Webhook-based message delivery
- **User Management:** Profile sync, presence indicators
- **Matrix Features:** Ghost users, portal rooms, double puppeting

#### Out of Scope (v1.0)
- Voice/video calls
- Meeting scheduling/management
- Teams apps/bots integration
- Advanced card rendering (basic Adaptive Cards only)
- Message history backfill (can be added in v2.0)
- Teams administrative functions

### Constraints
- Must use mautrix-go bridgev2 framework
- Must work with Microsoft Graph API v1.0
- Requires Azure AD application with appropriate permissions
- Webhook endpoint must be publicly accessible HTTPS
- Some features require Microsoft 365 E5 licensing

---

## Goals & Success Metrics

### Primary Goals
1. **Functionality:** Successfully bridge messages between Teams and Matrix
2. **Reliability:** Handle message delivery with >99% success rate
3. **Performance:** Message latency <2 seconds end-to-end
4. **Code Quality:** Pass all linting, maintain >80% test coverage
5. **Documentation:** Complete setup guide and API documentation

### Success Metrics

| Metric | Target | Measurement Method |
|--------|--------|-------------------|
| Message Delivery Success Rate | >99% | Monitor webhook delivery logs |
| Average Message Latency | <2 seconds | End-to-end timestamp tracking |
| Test Coverage | >80% | Go coverage tools |
| Setup Time | <30 minutes | User feedback |
| Bridge Uptime | >99.5% | Monitoring tools |
| GitHub Stars | 100+ | GitHub analytics |
| Beeper Bounty Acceptance | Yes | Beeper approval |

### User Stories

#### As a Beeper User
- I want to read Teams messages in Beeper so I don't need to switch apps
- I want to send messages to Teams from Beeper
- I want to see who sent messages and when
- I want to receive notifications for new Teams messages
- I want my sent messages to appear under my real account (double puppeting)

#### As a System Administrator
- I want clear setup documentation so I can deploy the bridge
- I want monitoring capabilities to ensure bridge health
- I want secure authentication so company data is protected
- I want to control which users can use the bridge

#### As a Developer
- I want clear code structure so I can contribute
- I want comprehensive tests so I can refactor safely
- I want good documentation so I can understand the codebase

---

## Technical Architecture

### High-Level Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│                 │         │                  │         │                 │
│  Matrix Client  │◄───────►│  Matrix Bridge   │◄───────►│ Microsoft Teams │
│    (Beeper)     │         │  (beeper-teams-bridge) │         │   (Graph API)   │
│                 │         │                  │         │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
                                    │
                                    │
                                    ▼
                            ┌──────────────┐
                            │              │
                            │  PostgreSQL  │
                            │   Database   │
                            │              │
                            └──────────────┘
```

### Component Breakdown

#### 1. Network Connector (`pkg/connector/connector.go`)
**Responsibility:** Bridge-wide configuration and lifecycle management

**Key Methods:**
- `Init()` - Initialize connector with bridge instance
- `Start()` - Set up HTTP routes for webhooks, start background tasks
- `GetName()` - Return bridge identification info
- `GetLoginFlows()` - Define OAuth login flow
- `CreateLogin()` - Instantiate login process
- `LoadUserLogin()` - Restore user session from database
- `GetConfig()` - Provide network-specific config structure
- `GetDBMetaTypes()` - Define database metadata schemas
- `GetCapabilities()` - Declare bridge capabilities

**Configuration Fields:**
```yaml
network:
  # Azure AD Application credentials
  azure_app_id: ""
  azure_tenant_id: "common"  # or specific tenant ID
  azure_redirect_uri: ""
  
  # Graph API settings
  graph_api_base: "https://graph.microsoft.com/v1.0"
  
  # Webhook settings
  webhook_public_url: ""  # Must be HTTPS
  webhook_path: "/webhook/{userLoginID}"
  
  # Rate limiting
  max_requests_per_second: 4
  
  # Feature flags
  enable_reactions: true
  enable_edits: true
  enable_typing_notifications: true
```

#### 2. Network API Client (`pkg/connector/client.go`)
**Responsibility:** Per-user Teams API interaction

**Key Methods:**
- `Connect()` - Establish Graph API connection, create webhook subscriptions
- `Disconnect()` - Clean up subscriptions
- `IsLoggedIn()` - Check token validity
- `LogoutRemote()` - Revoke tokens, disconnect
- `GetCapabilities()` - Return per-portal capabilities
- `HandleMatrixMessage()` - Send messages to Teams
- `HandleMatrixEdit()` - Edit Teams messages
- `HandleMatrixDelete()` - Delete Teams messages
- `HandleMatrixReaction()` - Add/remove reactions
- `GetChatInfo()` - Fetch Teams channel/chat metadata
- `GetUserInfo()` - Fetch Teams user profile
- `IsThisUser()` - Check if UserID matches login

**Internal Methods:**
- `refreshAccessToken()` - Handle OAuth token refresh
- `createWebhookSubscription()` - Subscribe to message notifications
- `renewWebhookSubscription()` - Extend subscription before expiration
- `deleteWebhookSubscription()` - Clean up subscription
- `sendGraphAPIRequest()` - Generic HTTP request handler with retry logic
- `handleRateLimiting()` - Exponential backoff implementation

#### 3. Login Process (`pkg/connector/login.go`)
**Responsibility:** OAuth 2.0 authentication flow

**Key Methods:**
- `Start()` - Return initial OAuth authorization URL
- `SubmitUserInput()` - Handle OAuth callback code
- `Cancel()` - Clean up failed login attempts

**OAuth Flow:**
```
1. User initiates login
2. Bridge generates authorization URL with PKCE
3. User visits URL, consents in browser
4. Teams redirects to callback with code
5. Bridge exchanges code for tokens
6. Bridge stores tokens in UserLogin metadata
7. Bridge creates webhook subscriptions
8. Login complete
```

**Token Storage (Database Metadata):**
```go
type TeamsUserLoginMetadata struct {
    AccessToken      string    `json:"access_token"`
    RefreshToken     string    `json:"refresh_token"`
    TokenExpiry      time.Time `json:"token_expiry"`
    TokenType        string    `json:"token_type"`
    Scope            string    `json:"scope"`
    TenantID         string    `json:"tenant_id"`
    UserPrincipalName string   `json:"user_principal_name"`
}
```

#### 4. Webhook Handler (`pkg/connector/webhook.go`)
**Responsibility:** Receive and process Teams events

**Endpoints:**
- `POST /webhook/{userLoginID}` - Receive message notifications
- `POST /webhook/validation` - Webhook endpoint validation

**Notification Types:**
- Message created
- Message updated (edited)
- Message deleted
- Reaction added/removed
- Typing indicator (optional)

**Webhook Security:**
- Validate Microsoft signature on all requests
- Verify subscription ID matches stored value
- Rate limit per user login
- Timeout after 5 seconds per webhook

#### 5. Message Converter (`pkg/connector/converter.go`)
**Responsibility:** Translate message formats

**Teams → Matrix:**
- Parse HTML content to Matrix markdown
- Convert @mentions to Matrix mentions
- Download and reupload media attachments
- Extract Adaptive Card text content
- Preserve reply threads
- Map reactions to Matrix reactions

**Matrix → Teams:**
- Convert markdown to Teams HTML
- Map Matrix mentions to Teams mentions
- Upload media to OneDrive/SharePoint
- Create message with proper formatting
- Preserve reply context
- Add reactions via Graph API

#### 6. Subscription Manager (`pkg/connector/subscriptions.go`)
**Responsibility:** Manage Graph API webhook subscriptions

**Key Functionality:**
- Create subscriptions on user connect
- Track expiration times (max 1 hour without lifecycle notifications)
- Implement lifecycle notification handler
- Automatic renewal before expiration (5 minutes buffer)
- Clean up on user disconnect
- Handle subscription failures gracefully

**Subscription Configuration:**
```go
type SubscriptionConfig struct {
    Resource            string
    ChangeTypes         []string
    NotificationURL     string
    ExpirationDateTime  time.Time
    ClientState         string
    LifecycleNotificationURL string
    IncludeResourceData bool
    EncryptionCertificate string
    EncryptionCertificateID string
}
```

### Data Models

#### Identifiers

**Design Philosophy:**
- All identifiers must be unique and deterministic
- Support for multiple Teams tenants
- Clear separation between different entity types

**Implementation:**
```go
// UserID: Azure AD User ID (GUID)
// Example: "d1e2f3a4-b5c6-7d8e-9f0a-1b2c3d4e5f6a"
type UserID = networkid.UserID

// UserLoginID: Azure AD User ID (same as UserID for Teams)
type UserLoginID = networkid.UserLoginID

// PortalID: Unique identifier for channels/chats
// Format for channels: "team:{team-id}:channel:{channel-id}"
// Format for chats: "chat:{chat-id}"
// Example: "team:abc123:channel:xyz789"
// Example: "chat:19:abc123@thread.v2"
type PortalID = networkid.PortalID

// MessageID: Teams message ID
// Example: "1234567890123"
type MessageID = networkid.MessageID
```

#### Portal Receiver Strategy
```
Channels: No receiver (shared portal)
  - All users in same team/channel share Matrix room
  - PortalKey{ ID: "team:X:channel:Y", Receiver: "" }

1:1 Chats: User as receiver (separate portals)
  - Each user gets their own Matrix room for DMs
  - PortalKey{ ID: "chat:Z", Receiver: currentUserID }

Group Chats: User as receiver (separate portals)
  - Each user gets their own Matrix room for group chats
  - PortalKey{ ID: "chat:Z", Receiver: currentUserID }
```

### Microsoft Graph API Integration

#### Authentication
- **Flow:** OAuth 2.0 Authorization Code with PKCE
- **Token Storage:** Encrypted in PostgreSQL
- **Refresh:** Automatic before expiration
- **Scopes Required:**
  - `Chat.ReadWrite` - Read and write chats
  - `ChannelMessage.Read.All` - Read channel messages
  - `ChannelMessage.Send` - Send channel messages
  - `Team.ReadBasic.All` - Read basic team info
  - `User.Read` - Read user profile

#### Key API Endpoints

**Sending Messages:**
```
POST /teams/{team-id}/channels/{channel-id}/messages
POST /chats/{chat-id}/messages
```

**Reading Messages:**
```
GET /teams/{team-id}/channels/{channel-id}/messages
GET /chats/{chat-id}/messages
GET /chats/{chat-id}/messages/{message-id}
```

**User/Team Info:**
```
GET /me
GET /users/{user-id}
GET /me/joinedTeams
GET /teams/{team-id}
GET /teams/{team-id}/channels
GET /chats/{chat-id}
GET /chats/{chat-id}/members
```

**Subscriptions (Webhooks):**
```
POST /subscriptions
PATCH /subscriptions/{subscription-id}
DELETE /subscriptions/{subscription-id}
```

#### Rate Limiting
- **Teams Webhooks:** 4 requests/second per webhook
- **Graph API:** Varies by endpoint, typically 10,000 requests/10 minutes
- **Strategy:** Token bucket algorithm with exponential backoff
- **Retry Logic:** 3 attempts with 1s, 2s, 4s delays

### Database Schema

#### Additional Metadata Tables

**user_login Metadata:**
```sql
-- Stored as JSON in metadata column
{
  "access_token": "encrypted_token",
  "refresh_token": "encrypted_token",
  "token_expiry": "2025-10-30T12:00:00Z",
  "token_type": "Bearer",
  "scope": "Chat.ReadWrite...",
  "tenant_id": "abc-123",
  "user_principal_name": "user@company.com"
}
```

**Custom Tables:**
```sql
-- Track webhook subscriptions
CREATE TABLE teams_subscription (
    user_login_id TEXT PRIMARY KEY,
    subscription_id TEXT NOT NULL,
    resource TEXT NOT NULL,
    expiration TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL,
    last_renewed TIMESTAMP,
    FOREIGN KEY (user_login_id) REFERENCES user_login(id) ON DELETE CASCADE
);

-- Cache Teams entity info
CREATE TABLE teams_entity_cache (
    id TEXT PRIMARY KEY,
    entity_type TEXT NOT NULL, -- 'team', 'channel', 'user'
    data JSONB NOT NULL,
    last_updated TIMESTAMP NOT NULL,
    expires_at TIMESTAMP
);
```

### Error Handling Strategy

#### Error Categories

1. **Authentication Errors**
   - Invalid/expired tokens → Trigger re-login
   - Insufficient permissions → Notify user, log details
   - Tenant restrictions → Inform user of limitations

2. **Network Errors**
   - Connection timeout → Retry with backoff
   - DNS resolution → Log and alert
   - SSL/TLS errors → Fail fast, log certificate info

3. **Rate Limiting**
   - HTTP 429 → Parse Retry-After header, queue request
   - Webhook throttling → Buffer events, process in batches
   - Graph API limits → Implement request queuing

4. **Resource Errors**
   - Message not found → Log, skip processing
   - Chat not found → Remove portal mapping
   - User not found → Create ghost with minimal info

5. **Bridge Errors**
   - Database connection lost → Attempt reconnection
   - Matrix homeserver down → Queue events for retry
   - Internal panic → Recover, log stack trace

#### Error Response Format
```go
type BridgeError struct {
    Code    string    `json:"code"`
    Message string    `json:"message"`
    Details string    `json:"details,omitempty"`
    Retry   bool      `json:"retry"`
    Time    time.Time `json:"timestamp"`
}
```

---

## Detailed Requirements

### Functional Requirements

#### FR-1: User Authentication
- **FR-1.1:** Bridge SHALL support OAuth 2.0 authorization code flow
- **FR-1.2:** Bridge SHALL store access and refresh tokens securely
- **FR-1.3:** Bridge SHALL automatically refresh expired tokens
- **FR-1.4:** Bridge SHALL handle multiple tenant authentications
- **FR-1.5:** Bridge SHALL support logout and token revocation
- **FR-1.6:** Bridge SHALL validate token permissions on startup

#### FR-2: Message Bridging (Teams → Matrix)
- **FR-2.1:** Bridge SHALL receive Teams messages via webhooks
- **FR-2.2:** Bridge SHALL convert Teams HTML to Matrix markdown
- **FR-2.3:** Bridge SHALL preserve message sender information
- **FR-2.4:** Bridge SHALL preserve message timestamps
- **FR-2.5:** Bridge SHALL download and reupload media attachments
- **FR-2.6:** Bridge SHALL preserve reply/thread structure
- **FR-2.7:** Bridge SHALL handle message edits
- **FR-2.8:** Bridge SHALL handle message deletions
- **FR-2.9:** Bridge SHALL handle reactions
- **FR-2.10:** Bridge SHALL create Matrix ghost users for Teams users

#### FR-3: Message Bridging (Matrix → Teams)
- **FR-3.1:** Bridge SHALL send Matrix messages to Teams
- **FR-3.2:** Bridge SHALL convert Matrix markdown to Teams HTML
- **FR-3.3:** Bridge SHALL upload media to Teams
- **FR-3.4:** Bridge SHALL preserve reply context
- **FR-3.5:** Bridge SHALL handle message edits
- **FR-3.6:** Bridge SHALL handle message deletions (redactions)
- **FR-3.7:** Bridge SHALL handle reactions
- **FR-3.8:** Bridge SHALL support @mentions

#### FR-4: Portal Management
- **FR-4.1:** Bridge SHALL create Matrix rooms for Teams channels
- **FR-4.2:** Bridge SHALL create Matrix rooms for Teams chats
- **FR-4.3:** Bridge SHALL sync room names from Teams
- **FR-4.4:** Bridge SHALL sync room topics from Teams
- **FR-4.5:** Bridge SHALL sync room membership
- **FR-4.6:** Bridge SHALL update room avatars
- **FR-4.7:** Bridge SHALL support starting new chats from Matrix

#### FR-5: Webhook Management
- **FR-5.1:** Bridge SHALL create webhook subscriptions on user login
- **FR-5.2:** Bridge SHALL validate webhook requests
- **FR-5.3:** Bridge SHALL renew subscriptions before expiration
- **FR-5.4:** Bridge SHALL handle lifecycle notifications
- **FR-5.5:** Bridge SHALL delete subscriptions on user logout
- **FR-5.6:** Bridge SHALL process webhook events within 5 seconds

#### FR-6: User Experience
- **FR-6.1:** Bridge SHALL provide clear login instructions
- **FR-6.2:** Bridge SHALL provide status feedback for operations
- **FR-6.3:** Bridge SHALL support bot commands (login, logout, sync, etc.)
- **FR-6.4:** Bridge SHALL log errors in user-friendly format
- **FR-6.5:** Bridge SHALL support double puppeting

### Non-Functional Requirements

#### NFR-1: Performance
- **NFR-1.1:** Message latency SHALL be <2 seconds end-to-end
- **NFR-1.2:** Bridge SHALL handle 100 concurrent users
- **NFR-1.3:** Bridge SHALL process 1000 messages/minute
- **NFR-1.4:** Database queries SHALL complete in <100ms (p95)
- **NFR-1.5:** Memory usage SHALL stay <512MB under normal load

#### NFR-2: Reliability
- **NFR-2.1:** Bridge uptime SHALL be >99.5%
- **NFR-2.2:** Message delivery success rate SHALL be >99%
- **NFR-2.3:** Bridge SHALL recover from crashes automatically
- **NFR-2.4:** Bridge SHALL persist state in database
- **NFR-2.5:** Bridge SHALL handle network interruptions gracefully

#### NFR-3: Security
- **NFR-3.1:** Tokens SHALL be encrypted at rest
- **NFR-3.2:** Webhook endpoints SHALL validate request signatures
- **NFR-3.3:** HTTPS SHALL be enforced for all webhook endpoints
- **NFR-3.4:** Secrets SHALL NOT be logged
- **NFR-3.5:** Bridge SHALL support end-to-bridge encryption

#### NFR-4: Maintainability
- **NFR-4.1:** Code SHALL follow Go best practices
- **NFR-4.2:** Code coverage SHALL be >80%
- **NFR-4.3:** All public functions SHALL have documentation
- **NFR-4.4:** Breaking changes SHALL be avoided in minor versions
- **NFR-4.5:** Deprecations SHALL have 6-month notice period

#### NFR-5: Scalability
- **NFR-5.1:** Bridge SHALL support horizontal scaling
- **NFR-5.2:** Database connections SHALL be pooled
- **NFR-5.3:** Webhook processing SHALL be parallelizable
- **NFR-5.4:** Rate limiting SHALL be distributed

#### NFR-6: Observability
- **NFR-6.1:** Bridge SHALL expose Prometheus metrics
- **NFR-6.2:** Bridge SHALL log all errors with context
- **NFR-6.3:** Bridge SHALL support structured logging
- **NFR-6.4:** Bridge SHALL expose health check endpoint
- **NFR-6.5:** Bridge SHALL track message delivery metrics

### Bot Commands

#### User Commands
```
login            - Start OAuth login flow
logout           - Disconnect from Teams
sync             - Force sync of rooms and messages
list-teams       - Show all Teams you're in
list-chats       - Show recent chats
set-relay        - Configure relay mode for a room
ping             - Check bridge connectivity
help             - Show command help
version          - Show bridge version
```

#### Admin Commands
```
reload-config    - Reload configuration
list-users       - Show all logged-in users
disconnect-user  - Force disconnect a user
clean-rooms      - Clean up unused portal rooms
stats            - Show bridge statistics
debug-portal     - Show debug info for a portal
```

---

## Implementation Roadmap

### Phase 0: Project Setup (Week 1)
**Goal:** Initialize repository and development environment

**Tasks:**
- Set up GitHub repository with branch protection
- Create directory structure
- Initialize Go module
- Set up CI/CD pipeline
- Create issue templates
- Write CONTRIBUTING.md
- Set up pre-commit hooks

**Deliverables:**
- Repository structure
- CI/CD running basic checks
- Documentation templates

### Phase 1: Core Framework (Week 2)
**Goal:** Implement mautrix-go integration skeleton

**Tasks:**
- Implement NetworkConnector interface
- Create configuration structure
- Set up database schema
- Implement basic logging
- Create build script
- Write registration generation

**Deliverables:**
- Bridge can start up
- Config can be generated
- Registration can be generated
- Basic health check works

### Phase 2: Authentication (Week 3)
**Goal:** OAuth 2.0 login flow

**Tasks:**
- Implement OAuth authorization URL generation
- Create callback handler
- Implement token exchange
- Add token refresh logic
- Create token storage in database
- Add logout functionality

**Deliverables:**
- Users can log in via OAuth
- Tokens are stored and refreshed
- Users can log out

**Testing:**
- Unit tests for token handling
- Integration test with real Azure AD
- Test token expiration/refresh

### Phase 3: Webhook Infrastructure (Week 4)
**Goal:** Receive and validate Teams events

**Tasks:**
- Implement webhook HTTP handlers
- Add signature validation
- Create subscription manager
- Implement lifecycle notifications
- Add subscription renewal logic
- Create webhook event parser

**Deliverables:**
- Webhook endpoint receives notifications
- Subscriptions are created/renewed/deleted
- Events are validated and parsed

**Testing:**
- Unit tests for signature validation
- Integration tests with Graph API
- Test subscription lifecycle

### Phase 4: Message Sending (Matrix → Teams) (Week 5)
**Goal:** Send messages from Matrix to Teams

**Tasks:**
- Implement HandleMatrixMessage
- Add text message support
- Create message converter (markdown → HTML)
- Add media upload support
- Implement @mention mapping
- Add reply support

**Deliverables:**
- Text messages bridge to Teams
- Images/files bridge to Teams
- Mentions work
- Replies preserve context

**Testing:**
- Unit tests for converters
- Integration tests for sending
- Test various message types

### Phase 5: Message Receiving (Teams → Matrix) (Week 6)
**Goal:** Receive messages from Teams to Matrix

**Tasks:**
- Implement webhook message handler
- Create message converter (HTML → markdown)
- Add media download/reupload
- Implement ghost user creation
- Add portal room creation
- Handle message metadata

**Deliverables:**
- Teams messages appear in Matrix
- Media is bridged
- Ghost users are created
- Rooms are created automatically

**Testing:**
- Integration tests for receiving
- Test various Teams message types
- Test portal creation

### Phase 6: Advanced Message Features (Week 7)
**Goal:** Support edits, deletes, reactions

**Tasks:**
- Implement message edit handling (both directions)
- Implement message delete handling (both directions)
- Add reaction support (both directions)
- Handle typing notifications
- Add read receipt sync

**Deliverables:**
- Edits work both directions
- Deletes work both directions
- Reactions work both directions

**Testing:**
- Test edit scenarios
- Test delete scenarios
- Test reaction scenarios

### Phase 7: Portal Management (Week 8)
**Goal:** Comprehensive room/chat management

**Tasks:**
- Implement GetChatInfo for channels
- Implement GetChatInfo for chats
- Add GetUserInfo
- Implement room metadata sync
- Add membership sync
- Create "start chat" functionality

**Deliverables:**
- Room names/topics/avatars sync
- Membership is accurate
- Can start new chats from Matrix

**Testing:**
- Test room metadata updates
- Test membership changes
- Test chat creation

### Phase 8: Error Handling & Resilience (Week 9)
**Goal:** Robust error handling

**Tasks:**
- Add comprehensive error types
- Implement retry logic
- Add rate limit handling
- Create error reporting to users
- Add crash recovery
- Implement backoff strategies

**Deliverables:**
- Graceful error handling
- Rate limits don't break bridge
- Users see helpful error messages

**Testing:**
- Fault injection tests
- Rate limit simulation
- Network failure tests

### Phase 9: Documentation & Polish (Week 10)
**Goal:** Production-ready documentation

**Tasks:**
- Write README with setup instructions
- Create architecture documentation
- Add code documentation (godoc)
- Write troubleshooting guide
- Create example configurations
- Record demo video

**Deliverables:**
- Complete documentation
- Setup guide
- Troubleshooting guide

### Phase 10: Testing & Quality Assurance (Week 11)
**Goal:** Comprehensive testing

**Tasks:**
- Achieve >80% code coverage
- Run integration test suite
- Perform load testing
- Security audit
- User acceptance testing
- Fix all critical bugs

**Deliverables:**
- All tests passing
- Coverage target met
- Security review complete

### Phase 11: Beta Release (Week 12)
**Goal:** Limited release for testing

**Tasks:**
- Create beta release
- Deploy test instance
- Gather user feedback
- Fix reported issues
- Update documentation based on feedback

**Deliverables:**
- Beta release published
- Test users onboarded
- Feedback collected

### Phase 12: Production Release & Beeper Submission (Week 13)
**Goal:** Official v1.0 release

**Tasks:**
- Create v1.0.0 release
- Publish to GitHub
- Submit to Beeper
- Announce release
- Monitor for issues

**Deliverables:**
- v1.0.0 released
- Beeper submission sent
- Community announcement

---

## Development Standards & Best Practices

### Code Style & Guidelines

#### Go Standards
```go
// Follow Effective Go: https://go.dev/doc/effective_go
// Follow Go Code Review Comments: https://github.com/golang/go/wiki/CodeReviewComments

// Package documentation
// Package connector implements the Microsoft Teams network connector for mautrix-go.
package connector

// Struct documentation
// TeamsClient represents a logged-in Microsoft Teams user.
// It implements the bridgev2.NetworkAPI interface.
type TeamsClient struct {
    // UserLogin is the bridge's user login object
    UserLogin *bridgev2.UserLogin
    
    // graphClient is the Microsoft Graph API client
    graphClient *msgraph.GraphServiceClient
}

// Function documentation
// SendMessage sends a text message to the specified Teams chat or channel.
// It returns the message ID from Teams or an error if sending fails.
//
// Parameters:
//   - ctx: Context for cancellation and timeouts
//   - portalID: The Teams channel or chat ID
//   - text: The message text in markdown format
//
// Returns:
//   - messageID: The Teams message ID
//   - error: Any error that occurred during sending
func (tc *TeamsClient) SendMessage(ctx context.Context, portalID string, text string) (messageID string, err error) {
    // Implementation
}
```

#### Naming Conventions
- **Packages:** Short, lowercase, single word (e.g., `connector`, `webhook`)
- **Files:** Lowercase with underscores (e.g., `webhook_handler.go`)
- **Types:** PascalCase (e.g., `TeamsClient`, `MessageConverter`)
- **Functions:** PascalCase for exported, camelCase for private
- **Constants:** PascalCase with type prefix (e.g., `MaxRetryAttempts`)
- **Interfaces:** End with -er when appropriate (e.g., `MessageSender`)

#### Error Handling
```go
// Always check errors
data, err := fetchData()
if err != nil {
    return fmt.Errorf("failed to fetch data: %w", err)
}

// Use custom error types for domain errors
type AuthenticationError struct {
    Reason string
    Err    error
}

func (e *AuthenticationError) Error() string {
    return fmt.Sprintf("authentication failed: %s: %v", e.Reason, e.Err)
}

func (e *AuthenticationError) Unwrap() error {
    return e.Err
}

// Panic only for programmer errors
if config == nil {
    panic("config cannot be nil")
}
```

#### Logging Standards
```go
// Use zerolog for structured logging
import "github.com/rs/zerolog/log"

// Log levels:
// - trace: Very detailed, typically disabled
// - debug: Detailed information for debugging
// - info: General informational messages
// - warn: Warning messages (recoverable issues)
// - error: Error messages (operation failed)
// - fatal: Fatal errors (program exits)

// Add context to logs
log.Info().
    Str("user_id", userID).
    Str("portal_id", portalID).
    Msg("Creating portal room")

// Log errors with stack traces when appropriate
log.Error().
    Err(err).
    Str("operation", "send_message").
    Msg("Failed to send message to Teams")

// Never log sensitive data
// BAD: log.Debug().Str("access_token", token)
// GOOD: log.Debug().Msg("Token refreshed successfully")
```

### Git Workflow

#### Branch Strategy
```
main
├── develop
│   ├── feature/oauth-implementation
│   ├── feature/webhook-handler
│   ├── bugfix/token-refresh-race
│   └── release/v1.0.0
└── hotfix/critical-security-fix
```

**Branch Types:**
- `main` - Production-ready code, always stable
- `develop` - Integration branch for features
- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Emergency production fixes
- `release/*` - Release preparation

#### Branch Protection Rules

**For `main`:**
- Require pull request reviews (minimum 1)
- Require status checks to pass (CI/CD)
- Require branches to be up to date
- Require signed commits
- No direct pushes (except release bot)

**For `develop`:**
- Require pull request reviews (minimum 1)
- Require status checks to pass
- Allow force pushes (for maintainers only)

#### Commit Message Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes
- `ci`: CI/CD changes

**Examples:**
```
feat(auth): implement OAuth 2.0 token refresh

Add automatic token refresh logic that runs 5 minutes before
expiration. Implements retry with exponential backoff on failure.

Closes #42
```

```
fix(webhook): handle missing signature header

Gracefully handle webhooks missing the signature header instead
of panicking. Log a warning and return 401 Unauthorized.

Fixes #127
```

#### Pull Request Template
```markdown
## Description
<!-- Describe your changes in detail -->

## Type of Change
- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Related Issues
<!-- Link to related issues: Closes #123, Fixes #456 -->

## How Has This Been Tested?
<!-- Describe the tests you ran -->
- [ ] Unit tests
- [ ] Integration tests
- [ ] Manual testing

## Checklist
- [ ] My code follows the project's style guidelines
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
- [ ] Any dependent changes have been merged and published

## Screenshots (if applicable)

## Additional Notes
```

### Code Review Guidelines

#### As a Reviewer
1. **Review promptly** - Within 24 hours
2. **Be constructive** - Suggest improvements, don't just criticize
3. **Ask questions** - "Why did you choose this approach?"
4. **Check for:**
   - Correctness
   - Security issues
   - Performance concerns
   - Error handling
   - Test coverage
   - Documentation

#### As an Author
1. **Keep PRs small** - Aim for <400 lines changed
2. **Provide context** - Explain the "why" in the description
3. **Self-review first** - Review your own diff before submitting
4. **Respond to comments** - Address all feedback
5. **Update PR as needed** - Don't leave PRs stale

#### Review Checklist
- [ ] Code solves the stated problem
- [ ] Code is readable and maintainable
- [ ] Error handling is appropriate
- [ ] Tests cover new functionality
- [ ] Documentation is updated
- [ ] No security vulnerabilities introduced
- [ ] Performance is acceptable
- [ ] Breaking changes are documented

---

## Repository Setup

### Directory Structure
```
beeper-teams-bridge/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── release.yml
│   │   └── codeql.yml
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   ├── feature_request.yml
│   │   └── question.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── dependabot.yml
├── cmd/
│   └── beeper-teams-bridge/
│       └── main.go
├── pkg/
│   └── connector/
│       ├── connector.go
│       ├── client.go
│       ├── login.go
│       ├── webhook.go
│       ├── converter.go
│       ├── subscriptions.go
│       ├── identifiers.go
│       └── example-config.yaml
├── internal/
│   └── util/
│       ├── encryption.go
│       └── http.go
├── docs/
│   ├── architecture.md
│   ├── setup.md
│   ├── troubleshooting.md
│   └── api.md
├── scripts/
│   ├── build.sh
│   ├── test.sh
│   └── release.sh
├── .gitignore
├── .golangci.yml
├── go.mod
├── go.sum
├── LICENSE
├── README.md
├── CONTRIBUTING.md
├── CHANGELOG.md
└── example-config.yaml
```

### GitHub Configuration Files

#### `.github/workflows/ci.yml`
```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
          POSTGRES_DB: mautrix_teams_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v5
      with:
        go-version: '1.24'
    
    - name: Cache Go modules
      uses: actions/cache@v4
      with:
        path: ~/go/pkg/mod
        key: ${{ runner.os }}-go-${{ hashFiles('**/go.sum') }}
        restore-keys: |
          ${{ runner.os }}-go-
    
    - name: Download dependencies
      run: go mod download
    
    - name: Run linter
      uses: golangci/golangci-lint-action@v6
      with:
        version: latest
    
    - name: Run tests
      run: go test -v -race -coverprofile=coverage.txt -covermode=atomic ./...
      env:
        DATABASE_URL: postgres://postgres:test@localhost:5432/mautrix_teams_test?sslmode=disable
    
    - name: Upload coverage
      uses: codecov/codecov-action@v4
      with:
        file: ./coverage.txt
        flags: unittests
    
    - name: Build
      run: ./scripts/build.sh

  lint:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Go
      uses: actions/setup-go@v5
      with:
        go-version: '1.24'
    
    - name: golangci-lint
      uses: golangci/golangci-lint-action@v6
      with:
        version: latest
        args: --timeout=5m

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Gosec Security Scanner
      uses: securego/gosec@master
      with:
        args: '-no-fail -fmt sarif -out results.sarif ./...'
    
    - name: Upload SARIF file
      uses: github/codeql-action/upload-sarif@v3
      with:
        sarif_file: results.sarif
```

#### `.github/workflows/release.yml`
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    permissions:
      contents: write
    
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
    
    - name: Set up Go
      uses: actions/setup-go@v5
      with:
        go-version: '1.24'
    
    - name: Run tests
      run: go test -v ./...
    
    - name: Build binaries
      run: |
        ./scripts/build.sh
        
        # Build for multiple platforms
        GOOS=linux GOARCH=amd64 go build -o beeper-teams-bridge-linux-amd64 ./cmd/beeper-teams-bridge
        GOOS=linux GOARCH=arm64 go build -o beeper-teams-bridge-linux-arm64 ./cmd/beeper-teams-bridge
        GOOS=darwin GOARCH=amd64 go build -o beeper-teams-bridge-darwin-amd64 ./cmd/beeper-teams-bridge
        GOOS=darwin GOARCH=arm64 go build -o beeper-teams-bridge-darwin-arm64 ./cmd/beeper-teams-bridge
    
    - name: Create Release
      uses: softprops/action-gh-release@v2
      with:
        files: |
          beeper-teams-bridge-linux-amd64
          beeper-teams-bridge-linux-arm64
          beeper-teams-bridge-darwin-amd64
          beeper-teams-bridge-darwin-arm64
        generate_release_notes: true
        draft: false
        prerelease: false
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: |
          ghcr.io/${{ github.repository }}:latest
          ghcr.io/${{ github.repository }}:${{ github.ref_name }}
```

#### `.github/ISSUE_TEMPLATE/bug_report.yml`
```yaml
name: Bug Report
description: File a bug report
title: "[Bug]: "
labels: ["bug", "triage"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for taking the time to fill out this bug report!
  
  - type: textarea
    id: what-happened
    attributes:
      label: What happened?
      description: A clear and concise description of the bug
      placeholder: Tell us what you see!
    validations:
      required: true
  
  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
      description: What did you expect to happen?
    validations:
      required: true
  
  - type: textarea
    id: reproduce
    attributes:
      label: Steps to Reproduce
      description: Steps to reproduce the behavior
      placeholder: |
        1. Go to '...'
        2. Click on '....'
        3. Scroll down to '....'
        4. See error
    validations:
      required: true
  
  - type: textarea
    id: logs
    attributes:
      label: Relevant log output
      description: Please copy and paste any relevant log output (redact sensitive information)
      render: shell
  
  - type: input
    id: version
    attributes:
      label: Bridge Version
      description: What version of beeper-teams-bridge are you running?
      placeholder: v1.0.0
    validations:
      required: true
  
  - type: dropdown
    id: homeserver
    attributes:
      label: Homeserver
      description: What homeserver are you using?
      options:
        - Synapse
        - Dendrite
        - Conduit
        - Other
    validations:
      required: true
  
  - type: textarea
    id: context
    attributes:
      label: Additional Context
      description: Add any other context about the problem here
```

#### `.github/ISSUE_TEMPLATE/feature_request.yml`
```yaml
name: Feature Request
description: Suggest an idea for this project
title: "[Feature]: "
labels: ["enhancement"]
body:
  - type: markdown
    attributes:
      value: |
        Thanks for suggesting a new feature!
  
  - type: textarea
    id: problem
    attributes:
      label: Is your feature request related to a problem?
      description: A clear and concise description of what the problem is
      placeholder: I'm always frustrated when [...]
  
  - type: textarea
    id: solution
    attributes:
      label: Describe the solution you'd like
      description: A clear and concise description of what you want to happen
    validations:
      required: true
  
  - type: textarea
    id: alternatives
    attributes:
      label: Describe alternatives you've considered
      description: A clear and concise description of any alternative solutions or features you've considered
  
  - type: textarea
    id: context
    attributes:
      label: Additional context
      description: Add any other context or screenshots about the feature request here
```

#### `.golangci.yml`
```yaml
run:
  timeout: 5m
  tests: true

linters:
  enable:
    - errcheck
    - gosimple
    - govet
    - ineffassign
    - staticcheck
    - unused
    - gofmt
    - goimports
    - misspell
    - gocritic
    - gosec
    - revive
    - stylecheck
    - unconvert

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true
  
  govet:
    check-shadowing: true
  
  gofmt:
    simplify: true
  
  misspell:
    locale: US
  
  revive:
    rules:
      - name: exported
        severity: warning
        disabled: false

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - gosec
        - gocritic
```

### Essential Files

#### `README.md` Structure
```markdown
# beeper-teams-bridge

A Matrix bridge for Microsoft Teams, built with mautrix-go.

[![CI Status](link)](link)
[![Go Report Card](link)](link)
[![License](link)](link)
[![Matrix Room](link)](link)

## Features

- ✅ Two-way message bridging
- ✅ Media support (images, files)
- ✅ Reactions
- ✅ Message edits and deletions
- ✅ Channel and DM support
- ✅ Double puppeting
- 🚧 Voice/video calls (planned)

## Installation

### Prerequisites

- Go 1.24+
- PostgreSQL 10+
- Matrix homeserver with appservice support
- Azure AD application with Microsoft Graph API permissions

### Quick Start

[Installation instructions]

## Configuration

[Configuration guide]

## Usage

[Usage guide]

## Development

[Development guide]

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## License

Licensed under the [MIT License](LICENSE). See LICENSE file for details.

## Support

- Matrix room: [#teams:maunium.net](link)
- GitHub issues: [Issues](link)

## Acknowledgments

- Built with [mautrix-go](link)
- Inspired by [mautrix bridges](link)
```

#### `CONTRIBUTING.md`
```markdown
# Contributing to beeper-teams-bridge

Thank you for your interest in contributing!

## Code of Conduct

[Code of conduct]

## Getting Started

1. Fork the repository
2. Clone your fork
3. Create a feature branch
4. Make your changes
5. Run tests
6. Submit a pull request

## Development Setup

[Setup instructions]

## Coding Standards

[Standards reference]

## Commit Guidelines

[Commit message format]

## Pull Request Process

[PR process]

## Testing

[Testing instructions]

## Questions?

[Support channels]
```

---

## Testing Strategy

### Testing Pyramid

```
            /\
           /  \
          / E2E \         10% - End-to-End Tests
         /______\
        /        \
       /Integration\      30% - Integration Tests
      /____________\
     /              \
    /   Unit Tests   \    60% - Unit Tests
   /__________________\
```

### Unit Tests

**Coverage Target:** >80% of code

**Test Structure:**
```go
package connector

import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/mock"
)

// Table-driven tests
func TestTeamsClient_SendMessage(t *testing.T) {
    tests := []struct {
        name        string
        portalID    string
        text        string
        wantErr     bool
        setupMock   func(*mockGraphClient)
    }{
        {
            name:     "successful send to channel",
            portalID: "team:123:channel:456",
            text:     "Hello, world!",
            wantErr:  false,
            setupMock: func(m *mockGraphClient) {
                m.On("SendChannelMessage", mock.Anything, mock.Anything).
                    Return("msg123", nil)
            },
        },
        {
            name:     "handle rate limit",
            portalID: "chat:789",
            text:     "Test message",
            wantErr:  true,
            setupMock: func(m *mockGraphClient) {
                m.On("SendChatMessage", mock.Anything, mock.Anything).
                    Return("", ErrRateLimited)
            },
        },
    }
    
    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // Setup
            mockClient := new(mockGraphClient)
            tt.setupMock(mockClient)
            
            client := &TeamsClient{
                graphClient: mockClient,
            }
            
            // Execute
            msgID, err := client.SendMessage(context.Background(), tt.portalID, tt.text)
            
            // Assert
            if tt.wantErr {
                assert.Error(t, err)
            } else {
                assert.NoError(t, err)
                assert.NotEmpty(t, msgID)
            }
            
            mockClient.AssertExpectations(t)
        })
    }
}

// Test fixtures
func createTestClient(t *testing.T) *TeamsClient {
    // Setup test client
}

func createTestUserLogin(t *testing.T) *bridgev2.UserLogin {
    // Setup test user login
}
```

**What to Test:**
- Message conversion (Teams ↔ Matrix)
- Token refresh logic
- Webhook signature validation
- Error handling
- Rate limiting
- Identifier parsing
- Configuration validation

### Integration Tests

**Test Database Interactions:**
```go
func TestDatabase_StoreAndRetrieveToken(t *testing.T) {
    // Setup test database
    db := setupTestDB(t)
    defer db.Close()
    
    // Create test data
    token := &TeamsUserLoginMetadata{
        AccessToken: "test_token",
        RefreshToken: "refresh_token",
        TokenExpiry: time.Now().Add(1 * time.Hour),
    }
    
    // Store
    err := db.StoreUserLogin("user123", token)
    assert.NoError(t, err)
    
    // Retrieve
    retrieved, err := db.GetUserLogin("user123")
    assert.NoError(t, err)
    assert.Equal(t, token.AccessToken, retrieved.AccessToken)
}
```

**Test Graph API Integration:**
```go
func TestGraphAPI_SendMessage(t *testing.T) {
    if testing.Short() {
        t.Skip("skipping integration test")
    }
    
    // Requires real Azure AD credentials
    client := createRealGraphClient(t)
    
    msgID, err := client.SendMessage(context.Background(), testChannelID, "Integration test message")
    assert.NoError(t, err)
    assert.NotEmpty(t, msgID)
    
    // Clean up
    client.DeleteMessage(context.Background(), testChannelID, msgID)
}
```

**Test Webhook Flow:**
```go
func TestWebhook_EndToEnd(t *testing.T) {
    // Start test server
    bridge := setupTestBridge(t)
    defer bridge.Stop()
    
    // Create subscription
    subID, err := bridge.CreateSubscription(testUserID, testChannelID)
    assert.NoError(t, err)
    
    // Simulate webhook notification
    notification := createTestNotification(testChannelID, "Test message")
    resp := sendWebhook(bridge.WebhookURL(), notification)
    assert.Equal(t, 200, resp.StatusCode)
    
    // Verify message was processed
    assert.Eventually(t, func() bool {
        return bridge.MessageReceived(notification.MessageID)
    }, 5*time.Second, 100*time.Millisecond)
}
```

### End-to-End Tests

**Full Bridge Flow:**
```go
func TestE2E_MessageBridging(t *testing.T) {
    // Setup full environment
    matrix := setupTestMatrixServer(t)
    teams := setupTestTeamsAccount(t)
    bridge := setupBridge(t, matrix, teams)
    
    defer cleanup(matrix, teams, bridge)
    
    // Login user
    loginResult := bridge.LoginUser(teams.UserID, teams.AccessToken)
    assert.True(t, loginResult.Success)
    
    // Create portal
    portal := bridge.CreatePortal(teams.ChannelID)
    matrixRoom := matrix.GetRoom(portal.MXID)
    
    // Test Matrix → Teams
    matrix.SendMessage(matrixRoom, "Hello from Matrix")
    assert.Eventually(t, func() bool {
        return teams.HasMessage("Hello from Matrix")
    }, 10*time.Second, 500*time.Millisecond)
    
    // Test Teams → Matrix
    teams.SendMessage(teams.ChannelID, "Hello from Teams")
    assert.Eventually(t, func() bool {
        return matrix.HasMessage(matrixRoom, "Hello from Teams")
    }, 10*time.Second, 500*time.Millisecond)
}
```

### Test Organization

```
beeper-teams-bridge/
├── pkg/connector/
│   ├── connector_test.go
│   ├── client_test.go
│   ├── login_test.go
│   ├── webhook_test.go
│   └── converter_test.go
├── test/
│   ├── integration/
│   │   ├── database_test.go
│   │   ├── graphapi_test.go
│   │   └── webhook_test.go
│   ├── e2e/
│   │   ├── bridging_test.go
│   │   └── authentication_test.go
│   └── fixtures/
│       ├── teams_messages.json
│       ├── matrix_events.json
│       └── test_config.yaml
└── scripts/
    └── test.sh
```

### Test Commands

```bash
# Run all tests
make test

# Run unit tests only
make test-unit

# Run integration tests
make test-integration

# Run e2e tests
make test-e2e

# Run with coverage
make test-coverage

# Run specific test
go test -v -run TestTeamsClient_SendMessage ./pkg/connector

# Run with race detector
go test -race ./...

# Generate coverage report
go test -coverprofile=coverage.out ./...
go tool cover -html=coverage.out
```

### CI Test Matrix

```yaml
# .github/workflows/ci.yml
strategy:
  matrix:
    go-version: ['1.24', '1.25']
    postgres-version: ['15', '16']
    os: [ubuntu-latest, macos-latest]
```

### Mocking Strategy

**Use Interfaces:**
```go
type GraphAPIClient interface {
    SendMessage(ctx context.Context, chatID, text string) (string, error)
    GetMessage(ctx context.Context, chatID, msgID string) (*Message, error)
    DeleteMessage(ctx context.Context, chatID, msgID string) error
}

// Mock implementation
type MockGraphAPIClient struct {
    mock.Mock
}

func (m *MockGraphAPIClient) SendMessage(ctx context.Context, chatID, text string) (string, error) {
    args := m.Called(ctx, chatID, text)
    return args.String(0), args.Error(1)
}
```

### Test Data Management

**Fixtures:**
```go
// test/fixtures/teams_messages.go
package fixtures

var TeamsTextMessage = `{
    "id": "1234567890123",
    "messageType": "message",
    "createdDateTime": "2025-10-30T12:00:00Z",
    "from": {
        "user": {
            "id": "user123",
            "displayName": "John Doe"
        }
    },
    "body": {
        "contentType": "html",
        "content": "<p>Hello, world!</p>"
    }
}`

var TeamsImageMessage = `{...}`
```

---

## Deployment & Operations

### Deployment Methods

#### 1. Docker Deployment

**Dockerfile:**
```dockerfile
FROM golang:1.24-alpine AS builder

WORKDIR /build
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o beeper-teams-bridge ./cmd/beeper-teams-bridge

FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata

WORKDIR /data
COPY --from=builder /build/beeper-teams-bridge /usr/local/bin/

RUN adduser -D -u 1337 mautrix
USER mautrix

ENTRYPOINT ["/usr/local/bin/beeper-teams-bridge"]
CMD ["-c", "/data/config.yaml"]
```

**docker-compose.yml:**
```yaml
version: '3.8'

services:
  beeper-teams-bridge:
    image: mautrix/teams:latest
    container_name: beeper-teams-bridge
    restart: unless-stopped
    ports:
      - "29319:29319"
    volumes:
      - ./data:/data
    environment:
      - TZ=UTC
    depends_on:
      - postgres
    networks:
      - matrix

  postgres:
    image: postgres:15-alpine
    container_name: beeper-teams-bridge-db
    restart: unless-stopped
    environment:
      POSTGRES_DB: mautrix_teams
      POSTGRES_USER: mautrix
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - matrix

volumes:
  postgres_data:

networks:
  matrix:
    external: true
```

#### 2. Systemd Service

**`/etc/systemd/system/beeper-teams-bridge.service`:**
```ini
[Unit]
Description=beeper-teams-bridge bridge
After=network.target postgresql.service

[Service]
Type=exec
User=beeper-teams-bridge
WorkingDirectory=/opt/beeper-teams-bridge
ExecStart=/opt/beeper-teams-bridge/beeper-teams-bridge -c /opt/beeper-teams-bridge/config.yaml

Restart=on-failure
RestartSec=30s

# Security hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/beeper-teams-bridge
CapabilityBoundingSet=

[Install]
WantedBy=multi-user.target
```

#### 3. Kubernetes Deployment

**deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: beeper-teams-bridge
  namespace: matrix
spec:
  replicas: 1
  selector:
    matchLabels:
      app: beeper-teams-bridge
  template:
    metadata:
      labels:
        app: beeper-teams-bridge
    spec:
      containers:
      - name: beeper-teams-bridge
        image: mautrix/teams:latest
        ports:
        - containerPort: 29319
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: beeper-teams-bridge-secret
              key: database-url
        volumeMounts:
        - name: config
          mountPath: /data/config.yaml
          subPath: config.yaml
          readOnly: true
      volumes:
      - name: config
        configMap:
          name: beeper-teams-bridge-config
```

### Monitoring & Observability

#### Prometheus Metrics

**Exposed Metrics:**
```go
// pkg/connector/metrics.go
var (
    messagesReceived = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "mautrix_teams_messages_received_total",
            Help: "Total number of messages received from Teams",
        },
        []string{"type", "portal"},
    )
    
    messagesSent = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "mautrix_teams_messages_sent_total",
            Help: "Total number of messages sent to Teams",
        },
        []string{"type", "portal"},
    )
    
    messageLatency = promauto.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "mautrix_teams_message_latency_seconds",
            Help:    "Message processing latency",
            Buckets: prometheus.ExponentialBuckets(0.01, 2, 10),
        },
        []string{"direction"},
    )
    
    activeUsers = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "mautrix_teams_active_users",
            Help: "Number of logged-in users",
        },
    )
    
    webhookSubscriptions = promauto.NewGauge(
        prometheus.GaugeOpts{
            Name: "mautrix_teams_webhook_subscriptions",
            Help: "Number of active webhook subscriptions",
        },
    )
    
    graphAPIErrors = promauto.NewCounterVec(
        prometheus.CounterOpts{
            Name: "mautrix_teams_graph_api_errors_total",
            Help: "Total number of Graph API errors",
        },
        []string{"error_type"},
    )
)
```

#### Logging Configuration

```yaml
# config.yaml
logging:
  min_level: info
  
  # File output
  writers:
    - type: file
      filename: /var/log/beeper-teams-bridge/bridge.log
      max_size: 100   # MB
      max_backups: 10
      max_age: 30     # days
      compress: true
  
  # Stdout for Docker
    - type: stdout
      format: json
  
  # Log specific loggers at different levels
  loggers:
    mautrix.crypto: warn
    mautrix.bridge: info
    connector: debug
```

#### Health Checks

```go
// Health check endpoint
func (tc *TeamsConnector) HealthCheck(w http.ResponseWriter, r *http.Request) {
    health := struct {
        Status    string `json:"status"`
        Database  string `json:"database"`
        GraphAPI  string `json:"graph_api"`
        Timestamp string `json:"timestamp"`
    }{
        Status:    "healthy",
        Timestamp: time.Now().Format(time.RFC3339),
    }
    
    // Check database
    if err := tc.Bridge.DB.Ping(); err != nil {
        health.Status = "unhealthy"
        health.Database = "error: " + err.Error()
    } else {
        health.Database = "ok"
    }
    
    // Check Graph API (sample request)
    if _, err := tc.testGraphAPIConnection(); err != nil {
        health.Status = "degraded"
        health.GraphAPI = "error: " + err.Error()
    } else {
        health.GraphAPI = "ok"
    }
    
    statusCode := http.StatusOK
    if health.Status == "unhealthy" {
        statusCode = http.StatusServiceUnavailable
    }
    
    w.WriteHeader(statusCode)
    json.NewEncoder(w).Encode(health)
}
```

### Backup & Recovery

**Database Backup:**
```bash
#!/bin/bash
# scripts/backup.sh

BACKUP_DIR="/var/backups/beeper-teams-bridge"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/mautrix_teams_$DATE.sql.gz"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Dump database
pg_dump -h localhost -U mautrix -d mautrix_teams | gzip > "$BACKUP_FILE"

# Keep only last 30 days
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_FILE"
```

**Restore:**
```bash
#!/bin/bash
# scripts/restore.sh

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: $0 <backup-file>"
    exit 1
fi

# Stop bridge
systemctl stop beeper-teams-bridge

# Restore database
gunzip < "$BACKUP_FILE" | psql -h localhost -U mautrix -d mautrix_teams

# Start bridge
systemctl start beeper-teams-bridge

echo "Restore completed"
```

### Security Considerations

**Secrets Management:**
```yaml
# Use environment variables for secrets
homeserver:
  address: ${HOMESERVER_ADDRESS}
  domain: ${HOMESERVER_DOMAIN}

appservice:
  as_token: ${AS_TOKEN}
  hs_token: ${HS_TOKEN}

network:
  azure_app_id: ${AZURE_APP_ID}
  azure_client_secret: ${AZURE_CLIENT_SECRET}

database:
  uri: ${DATABASE_URL}
```

**TLS Configuration:**
```yaml
# config.yaml
webhook:
  tls:
    enabled: true
    cert_file: /etc/beeper-teams-bridge/tls/cert.pem
    key_file: /etc/beeper-teams-bridge/tls/key.pem
    
  # Or use reverse proxy
  behind_proxy: true
  public_url: https://teams-bridge.example.com
```

---

## Risk Assessment

### Technical Risks

#### 1. Microsoft Graph API Changes
- **Probability:** Medium
- **Impact:** High
- **Mitigation:**
  - Monitor Microsoft Graph API changelog
  - Implement API version pinning
  - Create adapter layer for API interactions
  - Maintain comprehensive integration tests

#### 2. Rate Limiting
- **Probability:** High
- **Impact:** Medium
- **Mitigation:**
  - Implement token bucket algorithm
  - Add request queuing
  - Monitor rate limit headers
  - Implement exponential backoff
  - Document rate limits in README

#### 3. Webhook Reliability
- **Probability:** Medium
- **Impact:** High
- **Mitigation:**
  - Implement subscription renewal
  - Add health monitoring
  - Create fallback polling mechanism
  - Log all webhook failures
  - Alert on repeated failures

#### 4. Token Management
- **Probability:** Low
- **Impact:** High
- **Mitigation:**
  - Encrypt tokens at rest
  - Implement automatic refresh
  - Handle refresh failures gracefully
  - Add token validation on startup
  - Monitor token expiration

#### 5. Database Performance
- **Probability:** Medium
- **Impact:** Medium
- **Mitigation:**
  - Add database indexes
  - Implement connection pooling
  - Use prepared statements
  - Monitor slow queries
  - Regular database maintenance

### Operational Risks

#### 1. Bridge Downtime
- **Probability:** Medium
- **Impact:** High
- **Mitigation:**
  - Implement health checks
  - Auto-restart on failure
  - Queue messages during downtime
  - Document recovery procedures
  - Monitor uptime metrics

#### 2. Data Loss
- **Probability:** Low
- **Impact:** High
- **Mitigation:**
  - Regular database backups
  - Transaction-safe operations
  - Write-ahead logging
  - Test restore procedures
  - Document backup strategy

#### 3. Security Vulnerabilities
- **Probability:** Medium
- **Impact:** High
- **Mitigation:**
  - Regular security audits
  - Dependency scanning
  - Code review process
  - Security disclosure policy
  - Rapid patch deployment

### Business Risks

#### 1. Beeper Rejection
- **Probability:** Low
- **Impact:** High
- **Mitigation:**
  - Follow mautrix-go best practices
  - Maintain code quality
  - Provide comprehensive documentation
  - Engage with Beeper team early
  - Implement all required features

#### 2. Low Adoption
- **Probability:** Medium
- **Impact:** Medium
- **Mitigation:**
  - Create excellent documentation
  - Provide example configurations
  - Active community engagement
  - Quick bug fixes
  - Feature responsiveness

#### 3. Maintenance Burden
- **Probability:** High
- **Impact:** Medium
- **Mitigation:**
  - Write maintainable code
  - Comprehensive test coverage
  - Good documentation
  - Community contribution guidelines
  - Automated testing/releases

---

## Appendices

### Appendix A: Microsoft Graph API Reference

#### Required Permissions

**Delegated Permissions (User Context):**
```
Chat.ReadWrite                 - Read and write user's chats
ChannelMessage.Read.All        - Read all channel messages
ChannelMessage.Send            - Send messages to channels
Team.ReadBasic.All             - Read basic team information
User.Read                      - Sign in and read user profile
```

**Application Permissions (NOT USED):**
```
Note: Application permissions don't work for sending chat messages.
Only delegated permissions with user context are supported.
```

#### API Endpoints Summary

| Operation | Method | Endpoint |
|-----------|--------|----------|
| Send channel message | POST | `/teams/{id}/channels/{id}/messages` |
| Send chat message | POST | `/chats/{id}/messages` |
| Get message | GET | `/chats/{id}/messages/{id}` |
| Edit message | PATCH | `/chats/{id}/messages/{id}` |
| Delete message | DELETE | `/chats/{id}/messages/{id}` |
| List chats | GET | `/me/chats` |
| List teams | GET | `/me/joinedTeams` |
| Get team channels | GET | `/teams/{id}/channels` |
| Create subscription | POST | `/subscriptions` |
| Renew subscription | PATCH | `/subscriptions/{id}` |
| Delete subscription | DELETE | `/subscriptions/{id}` |

### Appendix B: Configuration Reference

**Complete Example Config:**
```yaml
# Homeserver configuration
homeserver:
  address: http://localhost:8008
  domain: matrix.example.com
  software: synapse
  status_endpoint: null
  message_send_checkpoint_endpoint: null
  async_media: false

# Application service configuration
appservice:
  address: http://localhost:29319
  hostname: 0.0.0.0
  port: 29319
  
  id: teams
  bot:
    username: teamsbot
    displayname: Microsoft Teams Bridge
    avatar: mxc://maunium.net/teams-logo
  
  ephemeral_events: true
  as_token: "generate-a-random-string"
  hs_token: "generate-another-random-string"

# Bridge configuration
bridge:
  username_template: "teams_{userid}"
  displayname_template: "{displayname}"
  
  command_prefix: "!teams"
  
  permissions:
    "*": relay
    "example.com": user
    "@admin:example.com": admin
  
  relay:
    enabled: false
    
  double_puppet_server_map: {}
  login_shared_secret_map: {}

# Network-specific configuration
network:
  # Azure AD Application
  azure_app_id: "your-app-id"
  azure_tenant_id: "common"
  azure_redirect_uri: "http://localhost:29319/oauth/callback"
  
  # Graph API
  graph_api_base: "https://graph.microsoft.com/v1.0"
  
  # Webhooks
  webhook_public_url: "https://teams-bridge.example.com"
  webhook_secret: "generate-random-secret"
  
  # Rate limiting
  max_requests_per_second: 4
  burst_allowance: 10
  
  # Features
  enable_reactions: true
  enable_edits: true
  enable_deletes: true
  enable_typing: true
  
  # Message settings
  max_message_length: 28000
  media_upload_timeout: 300

# Database configuration
database:
  type: postgres
  uri: postgres://user:password@localhost/mautrix_teams?sslmode=disable
  max_open_conns: 5
  max_idle_conns: 1
  conn_max_lifetime: 0
  conn_max_idle_time: 0

# Logging configuration
logging:
  min_level: info
  writers:
  - type: stdout
    format: pretty-colored
  - type: file
    filename: ./bridge.log
    max_size: 100
    max_backups: 10
    max_age: 30
    compress: true

# Metrics configuration  
metrics:
  enabled: true
  listen: 127.0.0.1:8001

# Encryption (optional)
encryption:
  allow: true
  default: false
  require: false
  appservice: false
  msc4190: false
  
  verification_levels:
    receive: unverified
    send: unverified
    share: cross-signed-tofu
```

### Appendix C: Glossary

**Terms:**
- **Bridge:** Software that connects two chat networks
- **Portal:** A Matrix room that represents a Teams channel or chat
- **Ghost User:** Matrix user representing a Teams user
- **Puppet:** See Ghost User
- **Double Puppeting:** Using your real Matrix account instead of ghost
- **Appservice:** Matrix's extension mechanism for bridges
- **Homeserver:** Matrix server (e.g., Synapse)
- **MXID:** Matrix User ID (e.g., @user:example.com)

**Acronyms:**
- **API:** Application Programming Interface
- **E2BE:** End-to-Bridge Encryption
- **MXID:** Matrix User ID
- **OAuth:** Open Authorization
- **PKCE:** Proof Key for Code Exchange
- **SSO:** Single Sign-On
- **UPN:** User Principal Name
- **UUID:** Universally Unique Identifier

### Appendix D: Troubleshooting Guide

**Common Issues:**

1. **Bridge won't start**
   - Check config.yaml for errors
   - Verify database connection
   - Check homeserver address
   - Review logs for specific error

2. **Login fails**
   - Verify Azure AD app configuration
   - Check redirect URI matches
   - Ensure correct permissions granted
   - Review OAuth error messages

3. **Messages not bridging**
   - Check webhook subscriptions
   - Verify network connectivity
   - Review rate limiting status
   - Check portal creation

4. **High latency**
   - Check database performance
   - Review network connectivity
   - Monitor Graph API response times
   - Check homeserver load

### Appendix E: Resources

**Documentation:**
- [mautrix-go Documentation](https://docs.mau.fi/bridges/go/)
- [Microsoft Graph API Docs](https://learn.microsoft.com/en-us/graph/api/overview)
- [Matrix Specification](https://spec.matrix.org/)
- [OAuth 2.0 RFC](https://datatracker.ietf.org/doc/html/rfc6749)

**Community:**
- Matrix Room: #teams:maunium.net
- GitHub Issues: github.com/yourorg/beeper-teams-bridge/issues
- Beeper Self-Hosting: #self-hosting:beeper.com

**Tools:**
- [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer)
- [ngrok](https://ngrok.com/) - For webhook development
- [golangci-lint](https://golangci-lint.run/) - Go linter
- [gosec](https://github.com/securego/gosec) - Security scanner

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-30 | Development Team | Initial PRD created |

---

## Approval Signatures

_To be completed before implementation begins_

| Role | Name | Signature | Date |
|------|------|-----------|------|
| Project Lead | | | |
| Technical Lead | | | |
| QA Lead | | | |

---

**END OF DOCUMENT**
