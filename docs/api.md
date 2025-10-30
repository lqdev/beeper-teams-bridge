# API Documentation

Internal API reference for beeper-teams-bridge developers.

---

## Table of Contents

1. [Network Connector API](#network-connector-api)
2. [Graph API Client](#graph-api-client)
3. [Webhook Endpoints](#webhook-endpoints)
4. [Bot Commands](#bot-commands)
5. [Database Models](#database-models)
6. [Message Conversion](#message-conversion)

---

## Network Connector API

The main connector interface implementation.

### Connector Interface

```go
package connector

type TeamsConnector struct {
    bridge *bridgev2.Bridge
    config *config.Config
    client *GraphAPIClient
}

// Initialize the connector
func NewTeamsConnector(bridge *bridgev2.Bridge) *TeamsConnector

// Start the connector
func (tc *TeamsConnector) Start(ctx context.Context) error

// Stop the connector
func (tc *TeamsConnector) Stop(ctx context.Context) error
```

### Login Management

```go
// Start OAuth login flow
func (tc *TeamsConnector) GetLoginFlows() []bridgev2.LoginFlow

// Handle OAuth callback
func (tc *TeamsConnector) HandleOAuthCallback(
    ctx context.Context,
    code string,
    state string,
) (*LoginResult, error)

// Logout user
func (tc *TeamsConnector) LogoutUser(
    ctx context.Context,
    userID string,
) error

// Refresh access token
func (tc *TeamsConnector) RefreshAccessToken(
    ctx context.Context,
    userID string,
) error
```

### Portal Management

```go
// Create portal for Teams chat/channel
func (tc *TeamsConnector) CreatePortal(
    ctx context.Context,
    key *PortalKey,
) (*Portal, error)

// Get portal by key
func (tc *TeamsConnector) GetPortal(
    key *PortalKey,
) (*Portal, error)

// Load all portals for user
func (tc *TeamsConnector) LoadPortalsForUser(
    ctx context.Context,
    userID string,
) ([]*Portal, error)

// Sync portal metadata (name, avatar, members)
func (tc *TeamsConnector) SyncPortal(
    ctx context.Context,
    portal *Portal,
) error
```

---

## Graph API Client

Interface for Microsoft Graph API operations.

### Client Interface

```go
package connector

type GraphAPIClient struct {
    baseURL     string
    httpClient  *http.Client
    rateLimiter *RateLimiter
}

// Create new Graph API client
func NewGraphAPIClient(config *config.Config) *GraphAPIClient

// Set access token for requests
func (c *GraphAPIClient) SetAccessToken(token string)
```

### Chat Operations

```go
// List user's chats
func (c *GraphAPIClient) ListChats(
    ctx context.Context,
) ([]Chat, error)

// Get specific chat
func (c *GraphAPIClient) GetChat(
    ctx context.Context,
    chatID string,
) (*Chat, error)

// List messages in chat
func (c *GraphAPIClient) ListChatMessages(
    ctx context.Context,
    chatID string,
    limit int,
) ([]Message, error)

// Get specific message
func (c *GraphAPIClient) GetChatMessage(
    ctx context.Context,
    chatID string,
    messageID string,
) (*Message, error)

// Send message to chat
func (c *GraphAPIClient) SendChatMessage(
    ctx context.Context,
    chatID string,
    content *MessageContent,
) (*Message, error)

// Edit message
func (c *GraphAPIClient) UpdateChatMessage(
    ctx context.Context,
    chatID string,
    messageID string,
    content *MessageContent,
) (*Message, error)

// Delete message
func (c *GraphAPIClient) DeleteChatMessage(
    ctx context.Context,
    chatID string,
    messageID string,
) error
```

### Team & Channel Operations

```go
// List user's teams
func (c *GraphAPIClient) ListTeams(
    ctx context.Context,
) ([]Team, error)

// Get team channels
func (c *GraphAPIClient) ListChannels(
    ctx context.Context,
    teamID string,
) ([]Channel, error)

// Send message to channel
func (c *GraphAPIClient) SendChannelMessage(
    ctx context.Context,
    teamID string,
    channelID string,
    content *MessageContent,
) (*Message, error)
```

### Subscription Operations

```go
// Create webhook subscription
func (c *GraphAPIClient) CreateSubscription(
    ctx context.Context,
    req *SubscriptionRequest,
) (*Subscription, error)

// Renew subscription
func (c *GraphAPIClient) RenewSubscription(
    ctx context.Context,
    subscriptionID string,
    newExpiry time.Time,
) (*Subscription, error)

// Delete subscription
func (c *GraphAPIClient) DeleteSubscription(
    ctx context.Context,
    subscriptionID string,
) error

// List subscriptions
func (c *GraphAPIClient) ListSubscriptions(
    ctx context.Context,
) ([]Subscription, error)
```

### User Operations

```go
// Get current user profile
func (c *GraphAPIClient) GetMe(
    ctx context.Context,
) (*User, error)

// Get user by ID
func (c *GraphAPIClient) GetUser(
    ctx context.Context,
    userID string,
) (*User, error)

// Get user's photo
func (c *GraphAPIClient) GetUserPhoto(
    ctx context.Context,
    userID string,
) ([]byte, error)
```

---

## Webhook Endpoints

HTTP endpoints for receiving Teams notifications.

### POST /webhook

Receive webhook notifications from Microsoft Teams.

**Request:**
```http
POST /webhook HTTP/1.1
Content-Type: application/json
X-Teams-Signature: sha256=<hmac-signature>

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
  ]
}
```

**Response:**
```http
HTTP/1.1 200 OK
Content-Type: text/plain

OK
```

**Validation Request (initial setup):**
```http
POST /webhook?validationToken=<token> HTTP/1.1

# Response must echo token:
HTTP/1.1 200 OK
Content-Type: text/plain

<token>
```

**Implementation:**
```go
func (wh *WebhookHandler) HandleWebhook(w http.ResponseWriter, r *http.Request) {
    // 1. Validate signature
    if !wh.validateSignature(r) {
        http.Error(w, "Invalid signature", http.StatusUnauthorized)
        return
    }
    
    // 2. Handle validation
    if validationToken := r.URL.Query().Get("validationToken"); validationToken != "" {
        w.Write([]byte(validationToken))
        return
    }
    
    // 3. Parse notification
    var notification WebhookNotification
    json.NewDecoder(r.Body).Decode(&notification)
    
    // 4. Respond immediately
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
    
    // 5. Process asynchronously
    go wh.processNotification(notification)
}
```

### GET /health

Health check endpoint.

**Request:**
```http
GET /health HTTP/1.1
```

**Response (healthy):**
```http
HTTP/1.1 200 OK
Content-Type: application/json

{
  "status": "healthy",
  "version": "v1.0.0",
  "checks": {
    "database": "ok",
    "graph_api": "ok",
    "subscriptions": "12 active"
  }
}
```

**Response (unhealthy):**
```http
HTTP/1.1 503 Service Unavailable
Content-Type: application/json

{
  "status": "unhealthy",
  "version": "v1.0.0",
  "checks": {
    "database": "failed: connection timeout",
    "graph_api": "ok",
    "subscriptions": "0 active"
  }
}
```

### GET /oauth/callback

OAuth callback endpoint.

**Request:**
```http
GET /oauth/callback?code=<auth-code>&state=<state> HTTP/1.1
```

**Response (success):**
```http
HTTP/1.1 200 OK
Content-Type: text/html

<html>
  <body>
    <h1>Login Successful!</h1>
    <p>You can close this window and return to Matrix.</p>
  </body>
</html>
```

**Response (error):**
```http
HTTP/1.1 400 Bad Request
Content-Type: text/html

<html>
  <body>
    <h1>Login Failed</h1>
    <p>Error: <error-description></p>
  </body>
</html>
```

---

## Bot Commands

Matrix bot command handlers.

### Command Interface

```go
type CommandHandler interface {
    // Command name (e.g., "login", "logout")
    Name() string
    
    // Command help text
    Help() string
    
    // Required permission level
    RequiredPermission() Permission
    
    // Execute command
    Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
}

type Command struct {
    UserID    string   // Matrix user ID
    RoomID    string   // Room where command was sent
    Args      []string // Command arguments
    RawArgs   string   // Original argument string
}

type CommandResult struct {
    Success   bool
    Message   string
    HTML      string // Optional HTML formatted message
}
```

### Available Commands

#### login
```go
// Start OAuth login flow
func (h *LoginHandler) Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
```

**Usage:** `login`

**Response:**
```
Please visit this URL to log in:
https://login.microsoftonline.com/...

This link expires in 10 minutes.
```

#### logout
```go
// Logout from Teams
func (h *LogoutHandler) Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
```

**Usage:** `logout`

**Response:**
```
✅ Successfully logged out.
Your webhook subscriptions have been deleted.
Existing portal rooms will remain but become inactive.
```

#### sync
```go
// Force sync chats and channels
func (h *SyncHandler) Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
```

**Usage:** `sync`

**Response:**
```
🔄 Syncing your Teams conversations...
✅ Created 3 new portals
✅ Updated 5 existing portals
✅ Renewed 8 webhook subscriptions
```

#### list-teams
```go
// List user's teams
func (h *ListTeamsHandler) Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
```

**Usage:** `list-teams`

**Response:**
```
📋 Your Teams:
1. Engineering Team (5 channels)
2. Marketing Team (3 channels)
3. All Company (12 channels)

Click a team to see channels.
```

#### list-chats
```go
// List user's chats
func (h *ListChatsHandler) Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
```

**Usage:** `list-chats`

**Response:**
```
📋 Recent Chats:
1. John Doe (1:1 chat) - portal exists
2. Project Team (group chat) - portal exists
3. Sarah Smith (1:1 chat) - no portal

Click a chat to create/open portal.
```

#### status
```go
// Show login and connection status
func (h *StatusHandler) Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
```

**Usage:** `status`

**Response:**
```
✅ Logged in as John Doe (john@company.com)
📊 Active portals: 12
🔔 Webhook subscriptions: 12 active
⏰ Token expires in 58 days
🌐 Bridge version: v1.0.0
```

#### ping
```go
// Check bridge connectivity
func (h *PingHandler) Execute(ctx context.Context, cmd *Command) (*CommandResult, error)
```

**Usage:** `ping`

**Response:**
```
Pong! Bridge is running.
Version: v1.0.0
Latency: 23ms
```

---

## Database Models

### User Model

```go
type User struct {
    MXID          string    // Matrix user ID (@user:domain)
    TeamsUserID   string    // Teams UPN (user@company.com)
    AccessToken   string    // Encrypted OAuth access token
    RefreshToken  string    // Encrypted OAuth refresh token
    TokenExpiry   time.Time // Access token expiration
    DisplayName   string    // Teams display name
    AvatarURL     string    // Teams avatar MXC URI
    LoggedIn      bool      // Login state
    CreatedAt     time.Time
    UpdatedAt     time.Time
}

// Get user by Matrix ID
func GetUserByMXID(ctx context.Context, mxid string) (*User, error)

// Get user by Teams ID
func GetUserByTeamsID(ctx context.Context, teamsID string) (*User, error)

// Save user
func (u *User) Save(ctx context.Context) error

// Delete user
func (u *User) Delete(ctx context.Context) error
```

### Portal Model

```go
type Portal struct {
    PortalKey     string    // Teams chat/channel ID
    MXID          string    // Matrix room ID (!room:domain)
    Name          string    // Portal name
    AvatarURL     string    // Portal avatar MXC URI
    PortalType    string    // "chat", "channel", "group"
    TeamID        string    // Team ID (for channels)
    Encrypted     bool      // Is room encrypted
    CreatedAt     time.Time
    UpdatedAt     time.Time
}

// Get portal by key
func GetPortalByKey(ctx context.Context, key string) (*Portal, error)

// Get portal by Matrix room ID
func GetPortalByMXID(ctx context.Context, mxid string) (*Portal, error)

// Save portal
func (p *Portal) Save(ctx context.Context) error

// Delete portal
func (p *Portal) Delete(ctx context.Context) error
```

### Message Model

```go
type Message struct {
    TeamsMessageID string    // Teams message ID
    TeamsChatID    string    // Teams chat/channel ID
    MXID           string    // Matrix event ID ($event:domain)
    Sender         string    // Sender Matrix user ID
    Timestamp      time.Time
}

// Get message by Teams ID
func GetMessageByTeamsID(
    ctx context.Context,
    chatID string,
    msgID string,
) (*Message, error)

// Get message by Matrix event ID
func GetMessageByMXID(ctx context.Context, mxid string) (*Message, error)

// Save message
func (m *Message) Save(ctx context.Context) error
```

### Subscription Model

```go
type Subscription struct {
    SubscriptionID string    // Microsoft subscription ID
    ChatID         string    // Teams chat/channel ID
    UserMXID       string    // Owner Matrix user ID
    ExpiresAt      time.Time // Subscription expiry
    Resource       string    // Graph API resource path
    CreatedAt      time.Time
}

// Get subscription by ID
func GetSubscriptionByID(
    ctx context.Context,
    subID string,
) (*Subscription, error)

// Get subscriptions by chat
func GetSubscriptionsByChatID(
    ctx context.Context,
    chatID string,
) ([]Subscription, error)

// Get subscriptions expiring soon
func GetExpiringSoon(
    ctx context.Context,
    before time.Time,
) ([]Subscription, error)

// Save subscription
func (s *Subscription) Save(ctx context.Context) error

// Delete subscription
func (s *Subscription) Delete(ctx context.Context) error
```

---

## Message Conversion

Convert between Matrix and Teams message formats.

### Teams to Matrix

```go
// Convert Teams message to Matrix event
func ConvertTeamsToMatrix(
    msg *TeamsMessage,
) (*MatrixEvent, error) {
    event := &MatrixEvent{
        Type: "m.room.message",
        Content: map[string]interface{}{
            "msgtype": "m.text",
            "body":    msg.Body.Content,
        },
    }
    
    // Handle formatting
    if msg.Body.ContentType == "html" {
        event.Content["format"] = "org.matrix.custom.html"
        event.Content["formatted_body"] = convertTeamsHTML(msg.Body.Content)
    }
    
    // Handle attachments
    for _, attachment := range msg.Attachments {
        // Convert to Matrix media event
    }
    
    // Handle mentions
    event.Content["mentions"] = convertMentions(msg.Mentions)
    
    return event, nil
}
```

### Matrix to Teams

```go
// Convert Matrix event to Teams message
func ConvertMatrixToTeams(
    event *MatrixEvent,
) (*TeamsMessageContent, error) {
    content := &TeamsMessageContent{
        ContentType: "html",
    }
    
    // Extract body
    body, _ := event.Content["body"].(string)
    
    // Check for formatted body
    if htmlBody, ok := event.Content["formatted_body"].(string); ok {
        content.Content = convertMatrixHTML(htmlBody)
    } else {
        content.Content = escapeHTML(body)
    }
    
    // Handle replies
    if relatesTo, ok := event.Content["m.relates_to"].(map[string]interface{}); ok {
        if inReplyTo, ok := relatesTo["m.in_reply_to"].(map[string]interface{}); ok {
            content.ReplyToID = inReplyTo["event_id"].(string)
        }
    }
    
    return content, nil
}
```

### HTML Conversion

```go
// Convert Teams HTML to Matrix HTML
func convertTeamsHTML(html string) string {
    // Teams uses specific tags and attributes
    // Convert to Matrix-compatible HTML
    
    // Teams mentions: <at id="xxx">Name</at>
    // Matrix mentions: <a href="https://matrix.to/#/@user:domain">Name</a>
    
    return matrixHTML
}

// Convert Matrix HTML to Teams HTML
func convertMatrixHTML(html string) string {
    // Matrix uses standard HTML
    // Convert to Teams-compatible HTML
    
    // Preserve formatting: bold, italic, links
    // Convert mentions
    
    return teamsHTML
}
```

---

## Rate Limiting

### Token Bucket Implementation

```go
type RateLimiter struct {
    mu          sync.Mutex
    tokens      float64
    maxTokens   float64
    refillRate  float64    // tokens per second
    lastRefill  time.Time
}

// Create new rate limiter
func NewRateLimiter(rps float64, burst int) *RateLimiter {
    return &RateLimiter{
        tokens:     float64(burst),
        maxTokens:  float64(burst),
        refillRate: rps,
        lastRefill: time.Now(),
    }
}

// Wait for token availability
func (rl *RateLimiter) Wait(ctx context.Context) error {
    rl.mu.Lock()
    defer rl.mu.Unlock()
    
    // Refill tokens based on time elapsed
    now := time.Now()
    elapsed := now.Sub(rl.lastRefill).Seconds()
    rl.tokens = math.Min(
        rl.maxTokens,
        rl.tokens + elapsed*rl.refillRate,
    )
    rl.lastRefill = now
    
    // If no tokens, wait
    if rl.tokens < 1 {
        waitTime := time.Duration((1-rl.tokens)/rl.refillRate) * time.Second
        select {
        case <-time.After(waitTime):
            rl.tokens = 1
        case <-ctx.Done():
            return ctx.Err()
        }
    }
    
    // Consume token
    rl.tokens--
    return nil
}
```

---

## Error Types

```go
// Bridge errors
type BridgeError struct {
    Code      string
    Message   string
    Retryable bool
    Cause     error
}

// Error codes
const (
    ErrCodeGraphAPI        = "GRAPH_API_ERROR"
    ErrCodeRateLimit       = "RATE_LIMIT_ERROR"
    ErrCodeAuth            = "AUTH_ERROR"
    ErrCodeNotFound        = "NOT_FOUND"
    ErrCodeDatabase        = "DATABASE_ERROR"
    ErrCodeNetwork         = "NETWORK_ERROR"
    ErrCodeWebhook         = "WEBHOOK_ERROR"
    ErrCodeInvalidInput    = "INVALID_INPUT"
)

// Create new bridge error
func NewBridgeError(code, message string, retryable bool, cause error) *BridgeError

// Check if error is retryable
func IsRetryable(err error) bool

// Extract rate limit retry-after duration
func GetRetryAfter(err error) time.Duration
```

---

**For usage examples, see the [source code](https://github.com/yourorg/beeper-teams-bridge).**
