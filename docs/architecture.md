# Architecture Overview

Technical architecture and design of beeper-teams-bridge.

---

## Table of Contents

1. [High-Level Architecture](#high-level-architecture)
2. [Component Breakdown](#component-breakdown)
3. [Data Flow](#data-flow)
4. [Microsoft Graph API Integration](#microsoft-graph-api-integration)
5. [Database Schema](#database-schema)
6. [Webhook System](#webhook-system)
7. [Error Handling](#error-handling)
8. [Performance Considerations](#performance-considerations)

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Layer                               │
├─────────────────┬───────────────────────┬───────────────────────┤
│  Matrix Client  │   Microsoft Teams     │   Bridge Admin        │
│   (Beeper)      │   (Desktop/Mobile)    │   (Monitoring)        │
└────────┬────────┴───────────┬───────────┴──────────┬────────────┘
         │                    │                       │
         │ /_matrix/*         │ Webhooks              │ /metrics
         ▼                    ▼                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Beeper Teams Bridge                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │  Appservice  │  │   Network    │  │   Webhook    │         │
│  │   Handler    │  │  Connector   │  │   Handler    │         │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘         │
│         │                  │                  │                  │
│         └──────────┬───────┴──────────────────┘                 │
│                    │                                             │
│         ┌──────────▼──────────┐                                 │
│         │   Matrix Portal     │                                 │
│         │      Manager        │                                 │
│         └──────────┬──────────┘                                 │
│                    │                                             │
└────────────────────┼─────────────────────────────────────────────┘
                     │
         ┌───────────▼───────────┐
         │    PostgreSQL DB      │
         │  - Users              │
         │  - Portals            │
         │  - Messages           │
         │  - Subscriptions      │
         └───────────────────────┘

         ┌───────────────────────┐
         │  Microsoft Graph API  │
         │  - OAuth 2.0          │
         │  - Chat Messages      │
         │  - Channel Messages   │
         │  - Subscriptions      │
         └───────────────────────┘
```

---

## Component Breakdown

### 1. Network Connector (`pkg/connector/`)

**Purpose:** Core bridge implementation connecting Matrix to Teams.

**Responsibilities:**
- Implement mautrix-go bridgev2 NetworkConnector interface
- Manage user authentication and login state
- Handle message conversion between Matrix and Teams formats
- Coordinate webhook subscriptions
- Implement bridge-specific logic

**Key Files:**
- `connector.go` - Main connector implementation
- `client.go` - Microsoft Graph API client wrapper
- `login.go` - OAuth 2.0 authentication flow
- `webhook.go` - Webhook handler for Teams events
- `converter.go` - Message format conversion
- `subscriptions.go` - Webhook subscription management

### 2. Appservice Handler

**Purpose:** Handle incoming requests from Matrix homeserver.

**Responsibilities:**
- Process Matrix events (messages, reactions, edits, etc.)
- Handle room invitations and membership
- Respond to appservice queries (user/room aliases)
- Forward events to Network Connector

**Provided by:** mautrix-go framework

### 3. Webhook Handler

**Purpose:** Receive real-time notifications from Microsoft Teams.

**Responsibilities:**
- Validate webhook signatures
- Parse Teams notification payloads
- Route events to appropriate portal handlers
- Acknowledge webhook delivery
- Handle subscription validation

**Endpoint:** `POST /webhook`

### 4. Portal Manager

**Purpose:** Manage Matrix rooms that bridge to Teams conversations.

**Responsibilities:**
- Create Matrix rooms for Teams chats/channels
- Sync room metadata (name, avatar, members)
- Handle message bridging in both directions
- Manage ghost users (Matrix users representing Teams users)
- Track portal state and configuration

**Provided by:** mautrix-go framework with custom implementations

### 5. Graph API Client

**Purpose:** Interface with Microsoft Graph API.

**Responsibilities:**
- Send messages to Teams
- Fetch chat/channel information
- Manage webhook subscriptions
- Handle OAuth token refresh
- Implement rate limiting and retries

**Endpoints Used:**
- `/me/chats` - List user chats
- `/teams/{id}/channels` - List team channels
- `/chats/{id}/messages` - Send/receive chat messages
- `/teams/{id}/channels/{id}/messages` - Send/receive channel messages
- `/subscriptions` - Manage webhook subscriptions

---

## Data Flow

### Matrix → Teams (Outgoing Message)

```
┌─────────────┐
│ Matrix User │
│ sends msg   │
└──────┬──────┘
       │
       ▼
┌─────────────────┐
│   Homeserver    │
│  forwards msg   │
└──────┬──────────┘
       │ /_matrix/app/v1/transactions
       ▼
┌─────────────────────────────────────┐
│  Bridge - Appservice Handler        │
│  - Receives Matrix event            │
│  - Identifies portal                │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Bridge - Portal Handler            │
│  - Validates sender                 │
│  - Converts Matrix → Teams format   │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Bridge - Graph API Client          │
│  - Checks rate limits               │
│  - Refreshes token if needed        │
│  - Sends POST request               │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────┐
│ Microsoft Teams │
│ receives msg    │
└─────────────────┘
```

### Teams → Matrix (Incoming Message)

```
┌─────────────┐
│ Teams User  │
│ sends msg   │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│ Microsoft Graph API │
│ generates event     │
└──────┬──────────────┘
       │ Webhook HTTP POST
       ▼
┌─────────────────────────────────────┐
│  Bridge - Webhook Handler           │
│  - Validates signature              │
│  - Parses notification payload      │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Bridge - Fetch Message Details     │
│  - GET /chats/{id}/messages/{id}    │
│  - Retrieves full message content   │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Bridge - Portal Handler            │
│  - Finds or creates portal          │
│  - Converts Teams → Matrix format   │
│  - Creates ghost users if needed    │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Bridge - Send to Matrix            │
│  - POST /_matrix/client/r0/...      │
│  - Creates message event            │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────┐
│ Homeserver  │
│ delivers to │
│ Matrix user │
└─────────────┘
```

---

## Microsoft Graph API Integration

### Authentication Flow

```
1. User sends "login" command to bridge bot

2. Bridge generates OAuth URL with PKCE challenge
   - Redirect URI: https://bridge.example.com/oauth/callback
   - Scopes: Chat.ReadWrite, ChannelMessage.Read.All, etc.
   - Code challenge (PKCE for security)

3. User visits OAuth URL in browser
   - Redirects to login.microsoftonline.com
   - User authenticates with Microsoft
   - User consents to permissions

4. Microsoft redirects back to bridge callback
   - Includes authorization code
   - Bridge exchanges code for tokens

5. Bridge receives tokens
   - Access token (1 hour lifetime)
   - Refresh token (90 days lifetime)
   - Stores encrypted in database

6. Bridge creates webhook subscriptions
   - For each chat/channel
   - Notifies bridge of new messages

7. Login complete
   - User marked as logged in
   - Message sync begins
```

### Token Management

**Access Token:**
- Lifetime: 1 hour
- Used for all Graph API requests
- Automatically refreshed when expired

**Refresh Token:**
- Lifetime: 90 days
- Used to obtain new access tokens
- Rotates on each use (new refresh token issued)
- Securely stored encrypted in database

**Token Refresh Logic:**
```go
if accessToken.ExpiresAt < time.Now().Add(5*time.Minute) {
    // Refresh proactively (5 min before expiry)
    newTokens := RefreshAccessToken(refreshToken)
    UpdateStoredTokens(newTokens)
}
```

### Rate Limiting

Microsoft Graph API limits:
- **Default:** 4 requests/second per user
- **Burst:** Short spikes allowed
- **Response:** HTTP 429 with Retry-After header

**Bridge Implementation:**
```go
type RateLimiter struct {
    tokens      int           // Available tokens
    maxTokens   int           // Burst capacity (10)
    refillRate  time.Duration // Time per token (250ms = 4/sec)
    lastRefill  time.Time
}

func (rl *RateLimiter) Wait() {
    // Token bucket algorithm
    // Refill tokens based on time elapsed
    // Wait if no tokens available
    // Respect 429 Retry-After headers
}
```

---

## Database Schema

### Core Tables

#### users
```sql
CREATE TABLE users (
    mxid TEXT PRIMARY KEY,          -- Matrix user ID
    teams_user_id TEXT,              -- Teams user ID (UPN)
    access_token TEXT,               -- Encrypted access token
    refresh_token TEXT,              -- Encrypted refresh token
    token_expiry TIMESTAMP,          -- Token expiration time
    display_name TEXT,               -- Teams display name
    avatar_url TEXT,                 -- Teams avatar URL
    logged_in BOOLEAN DEFAULT false,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### portals
```sql
CREATE TABLE portals (
    portal_key TEXT PRIMARY KEY,     -- Chat/channel ID
    mxid TEXT,                        -- Matrix room ID
    name TEXT,                        -- Portal name
    avatar_url TEXT,                  -- Portal avatar
    portal_type TEXT,                 -- 'chat', 'channel', 'group'
    encrypted BOOLEAN DEFAULT false,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);
```

#### messages
```sql
CREATE TABLE messages (
    teams_msg_id TEXT,               -- Teams message ID
    teams_chat_id TEXT,              -- Teams chat/channel ID
    mxid TEXT,                       -- Matrix event ID
    sender TEXT,                     -- Sender Matrix user
    timestamp TIMESTAMP,
    PRIMARY KEY (teams_msg_id, teams_chat_id)
);
```

#### subscriptions
```sql
CREATE TABLE subscriptions (
    subscription_id TEXT PRIMARY KEY, -- Microsoft subscription ID
    chat_id TEXT,                     -- Teams chat/channel ID
    user_mxid TEXT,                   -- Owner Matrix user
    expires_at TIMESTAMP,             -- Subscription expiry
    resource TEXT,                    -- Graph API resource path
    created_at TIMESTAMP
);
```

---

## Webhook System

### Subscription Lifecycle

```
1. User logs in
   ↓
2. Bridge lists user's chats/channels
   ↓
3. For each chat/channel:
   ├─ Create webhook subscription
   │  POST /subscriptions
   │  {
   │    "changeType": "created,updated,deleted",
   │    "notificationUrl": "https://bridge/webhook",
   │    "resource": "/chats/{id}/messages",
   │    "expirationDateTime": "2025-11-01T00:00:00Z"
   │  }
   │
   └─ Store subscription ID in database

4. Microsoft validates webhook
   ├─ Sends validation token
   └─ Bridge responds with token

5. Subscription active
   ├─ Lifetime: Up to 1 hour
   └─ Bridge renews before expiry

6. Renewal process (every 30 minutes)
   ├─ PATCH /subscriptions/{id}
   │  { "expirationDateTime": "2025-11-01T01:00:00Z" }
   └─ Update database

7. On logout or error
   └─ DELETE /subscriptions/{id}
```

### Webhook Payload

**Example notification:**
```json
{
  "value": [
    {
      "subscriptionId": "sub_12345",
      "changeType": "created",
      "resource": "chats/19:xxx/messages/1234567890",
      "resourceData": {
        "id": "1234567890",
        "@odata.type": "#microsoft.graph.chatMessage"
      },
      "tenantId": "tenant-id"
    }
  ],
  "validationTokens": ["token-if-validation"]
}
```

**Bridge handling:**
```go
1. Validate signature (HMAC-SHA256 with webhook secret)
2. Check subscriptionId exists in database
3. Extract message ID from resource path
4. Fetch full message: GET /chats/{id}/messages/{msgId}
5. Process message through portal
6. Respond 200 OK immediately
```

---

## Error Handling

### Error Categories

#### 1. Transient Errors (Retry)
- Network timeouts
- HTTP 429 (rate limit)
- HTTP 503 (service unavailable)
- Temporary database connection loss

**Strategy:** Exponential backoff retry
```
Attempt 1: Immediate
Attempt 2: 1 second
Attempt 3: 2 seconds
Attempt 4: 4 seconds
Attempt 5: 8 seconds
Max attempts: 5
```

#### 2. Permanent Errors (Fail)
- HTTP 401 (unauthorized - token invalid)
- HTTP 403 (forbidden - no permission)
- HTTP 404 (not found - resource deleted)
- Invalid message format

**Strategy:** Log error, notify user, don't retry

#### 3. User Errors
- Invalid commands
- Insufficient permissions
- Login failures

**Strategy:** Send friendly error message to user

### Error Response Format

```go
type BridgeError struct {
    Code       string    // "GRAPH_API_ERROR", "DB_ERROR", etc.
    Message    string    // User-friendly message
    Details    string    // Technical details (for logs)
    Retryable  bool      // Can this be retried?
    Timestamp  time.Time
}
```

---

## Performance Considerations

### Caching Strategy

**Cache user tokens:**
- In-memory cache with database backing
- Refresh proactively before expiry
- Reduce database queries

**Cache portal metadata:**
- Room names, avatars
- Update only when changed
- Reduce Graph API calls

**Cache message mappings:**
- Recent 1000 messages per portal
- LRU eviction
- Fast lookup for edits/deletions

### Database Optimization

**Indexes:**
```sql
CREATE INDEX idx_users_teams_id ON users(teams_user_id);
CREATE INDEX idx_portals_mxid ON portals(mxid);
CREATE INDEX idx_messages_teams ON messages(teams_chat_id, teams_msg_id);
CREATE INDEX idx_subscriptions_chat ON subscriptions(chat_id);
CREATE INDEX idx_subscriptions_expires ON subscriptions(expires_at);
```

**Connection Pooling:**
- Max 5 open connections
- Reuse connections
- Prepared statements

### Webhook Processing

**Async processing:**
```go
// Respond to webhook immediately
w.WriteHeader(http.StatusOK)

// Process in background
go func() {
    processWebhookEvent(notification)
}()
```

**Batch message fetching:**
- Fetch multiple messages in single API call
- Reduce API requests

---

## Security Considerations

1. **Token Encryption:** All tokens encrypted at rest
2. **Webhook Validation:** HMAC signature verification
3. **Rate Limiting:** Prevent abuse
4. **Input Validation:** Sanitize all user input
5. **TLS Required:** All external connections use HTTPS
6. **Secrets Management:** Use environment variables for secrets

---

## Monitoring & Observability

### Metrics

Exposed at `http://localhost:8001/metrics`:

```
# Message throughput
mautrix_teams_messages_received_total
mautrix_teams_messages_sent_total

# Latency
mautrix_teams_message_latency_seconds

# Active resources
mautrix_teams_active_users
mautrix_teams_portals_total
mautrix_teams_webhook_subscriptions

# Errors
mautrix_teams_graph_api_errors_total
mautrix_teams_webhook_errors_total
```

### Health Checks

**Endpoint:** `GET /health`

**Checks:**
- Database connectivity
- Graph API reachability
- Token validity
- Webhook subscriptions

**Response:**
```json
{
  "status": "healthy",
  "checks": {
    "database": "ok",
    "graph_api": "ok",
    "subscriptions": "12 active"
  }
}
```

---

## Technology Stack

- **Language:** Go 1.24+
- **Framework:** mautrix-go bridgev2
- **Database:** PostgreSQL 10+
- **APIs:** Microsoft Graph API v1.0
- **Auth:** OAuth 2.0 with PKCE
- **Transport:** HTTP/HTTPS, WebSockets (Matrix)
- **Metrics:** Prometheus
- **Logging:** Structured logging (JSON)

---

**For implementation details, see the [source code](https://github.com/yourorg/beeper-teams-bridge).**
