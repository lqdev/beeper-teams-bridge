# Product Requirements Document: mautrix-teams Bridge

## Overview

The mautrix-teams bridge is a Matrix-Microsoft Teams puppeting bridge that enables seamless bidirectional communication between Matrix and Microsoft Teams. This bridge will allow Matrix users to interact with Microsoft Teams chats, channels, and teams through their Matrix client.

## Goals

### Primary Goals
1. Enable Matrix users to send and receive messages from Microsoft Teams
2. Support both 1-on-1 chats and team channels
3. Provide reliable message delivery with proper error handling
4. Maintain message formatting across platforms
5. Support media attachments (images, files, videos)

### Secondary Goals
1. Synchronize presence information between platforms
2. Support message reactions (emoji)
3. Support message editing and deletion
4. Support threading conversations
5. Provide typing indicators and read receipts

## Target Users

- **Primary**: Organizations using Matrix as their primary communication platform but needing to interact with Microsoft Teams users
- **Secondary**: Individual users who participate in both Matrix and Teams communities
- **Tertiary**: Beeper users wanting Teams integration

## Use Cases

### UC1: Login and Authentication
**Actor**: Matrix User  
**Description**: User authenticates their Microsoft Teams account with the bridge  
**Flow**:
1. User sends `login` command to bridge bot
2. Bridge generates OAuth URL and sends to user
3. User authenticates with Microsoft
4. Bridge receives OAuth callback and stores credentials
5. Bridge confirms successful login to user

### UC2: Receive Teams Message in Matrix
**Actor**: Teams User sending a message  
**Description**: A message sent in Teams appears in Matrix  
**Flow**:
1. Teams user sends a message in a chat or channel
2. Bridge receives notification via webhook/polling
3. Bridge creates or identifies the corresponding Matrix room
4. Bridge sends the message to Matrix as the ghost user
5. Matrix user sees the message in their client

### UC3: Send Message from Matrix to Teams
**Actor**: Matrix User  
**Description**: A Matrix user sends a message that appears in Teams  
**Flow**:
1. Matrix user sends a message in a portal room
2. Bridge receives the Matrix event
3. Bridge translates the message format
4. Bridge sends the message to Teams via API
5. Teams users see the message from the Matrix user

### UC4: Media Sharing
**Actor**: Matrix or Teams User  
**Description**: Users share images, files, or other media  
**Flow**:
1. User uploads media in their client
2. Bridge downloads the media from source platform
3. Bridge uploads the media to destination platform
4. Bridge sends message with media reference
5. Recipients can view/download the media

### UC5: Presence Synchronization
**Actor**: Matrix User  
**Description**: User's online/away/offline status syncs between platforms  
**Flow**:
1. User's status changes on either platform
2. Bridge detects the status change
3. Bridge updates status on the other platform
4. Other users see the updated presence

## Technical Requirements

### Functional Requirements

#### FR1: Authentication
- Support OAuth2 authentication with Microsoft Azure AD
- Support multi-tenant and single-tenant configurations
- Securely store and refresh access tokens
- Handle token expiration and re-authentication

#### FR2: Message Handling
- Bidirectional message synchronization
- Support text messages with basic formatting (bold, italic, code)
- Support mentions (@user)
- Support message threading
- Support message editing
- Support message deletion/redaction
- De-duplicate messages to prevent loops

#### FR3: Media Support
- Support image uploads/downloads
- Support file attachments
- Support video files
- Respect file size limits of both platforms
- Provide thumbnails where applicable

#### FR4: Room Management
- Automatically create Matrix rooms for Teams chats
- Support private chats (1-on-1)
- Support group chats
- Support team channels
- Sync room metadata (name, topic, avatar)
- Handle room invitations

#### FR5: User Management
- Create Matrix ghost users for Teams users
- Sync Teams user profiles (name, avatar)
- Handle user presence (online, away, offline)
- Support multiple Matrix users bridging the same Teams account

#### FR6: Real-time Updates
- Support Teams webhooks for real-time message delivery
- Fall back to polling if webhooks unavailable
- Minimize message delivery latency (<5 seconds)

### Non-Functional Requirements

#### NFR1: Performance
- Handle 1000+ concurrent users
- Support 100+ messages per second
- Message delivery latency <5 seconds
- Memory usage <500MB per 1000 users
- Database query time <100ms (p95)

#### NFR2: Reliability
- 99.9% uptime target
- Automatic reconnection on network failure
- Transaction-safe database operations
- Message queue for reliable delivery
- Graceful degradation when Teams API is unavailable

#### NFR3: Security
- Encrypt tokens at rest
- Support end-to-end encryption in Matrix rooms
- No logging of message content
- Secure credential storage
- Regular security audits
- Compliance with data protection regulations

#### NFR4: Scalability
- Horizontal scaling capability
- Database connection pooling
- Efficient API rate limit handling
- Caching for frequently accessed data

#### NFR5: Maintainability
- Comprehensive logging
- Metrics and monitoring endpoints
- Clear error messages
- Extensive documentation
- Automated testing (80%+ coverage)
- CI/CD pipeline

## Technical Architecture

### Components

1. **Bridge Core**
   - Matrix event handler
   - Teams event processor
   - Message router
   - Format converter

2. **Teams Client**
   - Microsoft Graph API integration
   - OAuth2 authentication
   - Webhook management
   - Message polling (fallback)

3. **Database**
   - User account storage
   - Portal (room) tracking
   - Puppet (ghost user) records
   - Message deduplication

4. **Configuration**
   - YAML configuration file
   - Environment variables
   - Runtime validation

### Technology Stack

- **Language**: Go 1.21+
- **Framework**: mautrix-go
- **Database**: PostgreSQL (primary), SQLite (development)
- **APIs**: 
  - Matrix Client-Server API
  - Microsoft Graph API
  - Microsoft Teams API
- **Authentication**: OAuth2 / MSAL
- **Deployment**: Docker, Kubernetes

## API Dependencies

### Matrix APIs
- Client-Server API for sending/receiving events
- Application Service API for appservice registration

### Microsoft APIs
- Microsoft Graph API for Teams data
- Teams Activity Feed API for notifications
- Azure AD API for authentication

## Database Schema

### Tables

1. **users**
   - mxid (primary key)
   - teams_id
   - access_token (encrypted)
   - refresh_token (encrypted)
   - token_expiry

2. **portals**
   - portal_key (composite: chat_id + receiver)
   - mxid
   - name
   - topic
   - avatar_url
   - encrypted (boolean)

3. **puppets**
   - teams_id (primary key)
   - mxid
   - displayname
   - avatar_url
   - last_sync

4. **messages**
   - mxid (composite: room_id + event_id)
   - teams_id
   - timestamp

## Configuration

### Required Settings
- Homeserver URL and domain
- Appservice registration details
- Database connection
- Microsoft Azure AD application credentials

### Optional Settings
- Sync intervals
- Presence sync enable/disable
- Message backfill settings
- Media proxy configuration
- Logging levels

## Development Phases

### Phase 1: Foundation (Weeks 1-2) ✓
- Project structure
- Documentation
- Build system
- CI/CD pipeline

### Phase 2: Core Infrastructure (Weeks 3-4)
- Configuration system
- Database schema and migrations
- Basic appservice registration
- Logging and monitoring

### Phase 3: Microsoft Teams Integration (Weeks 5-7)
- Teams API client
- OAuth2 authentication
- Basic message retrieval
- User profile sync

### Phase 4: Bridge Core (Weeks 8-10)
- Portal management
- Puppet handling
- Message format conversion
- Bidirectional messaging

### Phase 5: Advanced Features (Weeks 11-12)
- Media support
- Message editing/deletion
- Reactions
- Typing indicators

### Phase 6: Testing & Polish (Weeks 13-14)
- Integration testing
- Performance optimization
- Documentation completion
- Bug fixes

### Phase 7: Release (Week 15)
- Beta release
- User feedback
- Final fixes
- Stable release

## Success Metrics

1. **Adoption**: 100+ active users within 3 months
2. **Reliability**: 99.9% uptime
3. **Performance**: Message latency <5 seconds (p95)
4. **User Satisfaction**: 4+ star rating
5. **Bug Rate**: <5 critical bugs per month after stable release

## Risks and Mitigations

### Risk 1: Microsoft API Changes
**Impact**: High  
**Probability**: Medium  
**Mitigation**: Use stable API versions, monitor Microsoft announcements, version API calls

### Risk 2: Rate Limiting
**Impact**: Medium  
**Probability**: High  
**Mitigation**: Implement request queuing, respect rate limits, use webhooks when possible

### Risk 3: Authentication Complexity
**Impact**: High  
**Probability**: Medium  
**Mitigation**: Use established OAuth libraries (MSAL), comprehensive error handling

### Risk 4: Message Format Incompatibilities
**Impact**: Medium  
**Probability**: High  
**Mitigation**: Extensive format testing, graceful degradation, clear documentation of limitations

## Out of Scope

- Microsoft Teams meeting integration (future enhancement)
- Teams phone/calling features
- SharePoint integration
- Microsoft 365 app integration beyond Teams
- Historical message migration (backfill may be added later)

## References

- [Matrix Specification](https://spec.matrix.org/)
- [Microsoft Graph API Documentation](https://docs.microsoft.com/en-us/graph/)
- [mautrix-go Framework](https://github.com/mautrix/go)
- [Microsoft Teams API](https://docs.microsoft.com/en-us/graph/api/resources/teams-api-overview)

---

**Document Version**: 1.0  
**Last Updated**: 2025-10-30  
**Owner**: Luis Quintanilla (@lqdev)
