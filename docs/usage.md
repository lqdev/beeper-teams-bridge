# User Guide

How to use the Microsoft Teams bridge in your Matrix client.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Bot Commands](#bot-commands)
3. [Authentication](#authentication)
4. [Bridging Conversations](#bridging-conversations)
5. [Sending Messages](#sending-messages)
6. [Managing Portals](#managing-portals)
7. [Advanced Features](#advanced-features)
8. [Tips & Best Practices](#tips--best-practices)

---

## Getting Started

### Prerequisites

- Bridge must be installed and running (see [setup.md](setup.md))
- You must have a Matrix account on the homeserver where the bridge is installed
- You need a Microsoft 365 account with Teams access

### Find the Bridge Bot

The bridge bot username is configured in the bridge config (default: `@teamsbot:matrix.example.com`)

**To start using the bridge:**
1. Open your Matrix client (Beeper, Element, etc.)
2. Start a new chat with the bridge bot
3. The bot will introduce itself

---

## Bot Commands

Send these commands in your chat with the bridge bot.

### Authentication

```
login
```
Start the OAuth login flow to connect your Microsoft Teams account.

```
logout
```
Disconnect from Teams and stop syncing messages.

---

### Chat Management

```
sync
```
Force synchronization of Teams chats and channels. Useful after joining new Teams or channels.

```
list-teams
```
Show all Teams you're a member of.

```
list-chats
```
Show your recent 1:1 and group chats.

---

### Utilities

```
ping
```
Check if the bridge is running and responsive.

```
help
```
Display available commands and usage instructions.

```
version
```
Show the bridge version and build information.

```
status
```
Show your login status and connection health.

---

### Admin Commands

(Only available to users with admin permissions)

```
reload-config
```
Reload the bridge configuration without restarting.

```
stats
```
Display bridge statistics (users, portals, messages).

---

## Authentication

### Initial Login

1. **Start login flow:**
   ```
   login
   ```

2. **Click the OAuth link** provided by the bot
   - Opens Microsoft login page in your browser
   - You may be asked to select an account

3. **Sign in** with your Microsoft credentials
   - Use your work/school account for enterprise Teams
   - Or personal Microsoft account

4. **Grant permissions** when prompted
   - The bridge needs to read and send Teams messages
   - Review the permissions and click "Accept"

5. **Return to Matrix**
   - You'll see a success message
   - The bridge will start syncing your chats

**Example:**
```
You: login

Bot: Please visit this URL to log in:
     https://login.microsoftonline.com/common/oauth2/v2.0/authorize?...
     
     This link expires in 10 minutes.

[After clicking and authorizing]

Bot: ✅ Successfully logged in as John Doe (john@company.com)
     Syncing your Teams chats...
     Created 5 portals for your conversations.
```

### Checking Login Status

```
status
```

**Response:**
```
✅ Logged in as John Doe (john@company.com)
📊 Active portals: 12
🔔 Webhook subscriptions: 12 active
⏰ Token expires in 58 days
```

### Logging Out

```
logout
```

This will:
- Disconnect from Teams
- Stop syncing messages
- Keep existing portal rooms (they become inactive)
- Delete webhook subscriptions

You can log in again later to resume bridging.

---

## Bridging Conversations

### Automatic Portal Creation

When you log in, the bridge automatically creates Matrix rooms (portals) for:
- Your recent 1:1 chats
- Group chats you're in
- Team channels you're a member of

Each portal is a Matrix room that bridges to a Teams conversation.

### From Teams to Matrix

**When someone messages you on Teams:**
1. A new portal room is created (if it doesn't exist)
2. You're invited to the room
3. The message appears in the room

**You'll be invited automatically** - just accept the invitation.

### From Matrix to Teams

**To message someone on Teams:**

**Method 1: Use existing portal**
- If you have a portal for that conversation, just use it

**Method 2: Use list commands**
1. Send `list-teams` or `list-chats` to the bridge bot
2. Click on the conversation you want
3. A portal room is created and you're invited

**Method 3: Direct portal creation** (coming soon)
```
create-portal <teams-chat-id>
```

---

## Sending Messages

### Text Messages

Just send messages normally in the portal room. They'll be delivered to Teams.

**Example:**
```
You (in Matrix): Hello from Matrix!
[Message appears in Teams as: "Hello from Matrix!"]
```

### Replies

Use Matrix's reply feature to reply to specific messages.

**How to reply:**
- Most clients: Long-press message → Reply
- Element: Click reply arrow on message
- The reply context is preserved in Teams

### Reactions

React to messages using emoji reactions in Matrix.

**Supported:**
- Standard emoji (👍, ❤️, 😂, etc.)
- Reactions sync both ways (Matrix ↔ Teams)

**Limitations:**
- Teams supports a limited set of reactions
- Custom emoji may not work

### Editing Messages

Edit your messages after sending:

**How to edit:**
- Most clients: Long-press → Edit
- Element: Click "..." → Edit
- Edited messages sync to Teams with "(edited)" marker

**Limitations:**
- Can only edit your own messages
- Teams may show edit history

### Deleting Messages

Delete messages you've sent:

**How to delete:**
- Most clients: Long-press → Delete
- Element: Click "..." → Remove
- Deleted messages are removed from Teams too

**Limitations:**
- Can only delete your own messages
- Deletion may not be instant

### Media & Files

**Images:**
- Send images normally in Matrix
- They're uploaded to Teams automatically
- Thumbnails are generated

**Files:**
- Attach files in Matrix
- Supported: documents, PDFs, videos, etc.
- File size limit: determined by Teams (up to 250 MB)

**Voice Messages:**
- Send voice messages from Matrix
- They appear as audio files in Teams

---

## Managing Portals

### Viewing Your Portals

```
list-teams
```
Shows all Team channels with portal status.

```
list-chats
```
Shows 1:1 and group chats with portal status.

### Portal Room Settings

Each portal room has these properties:

**Room name:** Matches Teams conversation name
- Updates automatically when changed in Teams

**Room avatar:** Shows Teams chat/channel icon
- Updates when changed in Teams

**Room members:** 
- Bridge bot (manages bridging)
- Ghost users (represent Teams users)
- You (logged in user)

### Leaving a Portal

**To stop bridging a specific conversation:**
1. Leave the Matrix room (portal)
2. The portal remains inactive
3. New messages won't create a new portal automatically
4. Re-sync or re-list to recreate if needed

### Ghost Users

**What are ghost users?**
- Matrix users that represent Teams users
- Created automatically by the bridge
- Username format: `@teams_<userid>:matrix.example.com`
- Display name matches Teams display name
- Avatar syncs from Teams profile picture

**Ghost users appear in portal rooms** representing their Teams counterparts.

---

## Advanced Features

### Double Puppeting

**What is it?**
Double puppeting lets the bridge send messages as your real Matrix account instead of a ghost user.

**Benefits:**
- Messages appear from your actual Matrix user
- Works in encrypted rooms
- Better integration with Matrix features

**Setup:**
Requires homeserver configuration. Ask your admin or see bridge configuration documentation.

### End-to-Bridge Encryption

**What is it?**
E2BE encrypts messages between your Matrix client and the bridge.

**Enable:**
1. Verify it's enabled in bridge config
2. Portal rooms will be encrypted
3. Messages are decrypted at the bridge before sending to Teams

**Note:** Teams doesn't support E2EE, so messages are unencrypted on Teams side.

### Presence Sync

**Status:** Coming soon

Will sync online/offline status between Teams and Matrix.

### Typing Indicators

**Status:** Coming soon

Will show when someone is typing in Teams conversations.

---

## Tips & Best Practices

### Performance

- **Sync regularly:** Use `sync` command after joining new Teams/channels
- **Keep portals active:** Don't leave rooms you use frequently
- **Monitor status:** Check `status` occasionally to ensure connection is healthy

### Privacy

- **Be aware:** Messages bridged through this system are visible to bridge administrator
- **E2BE helps:** Use encryption in Matrix for better privacy
- **Teams policies apply:** Your organization's Teams policies still apply to bridged messages

### Troubleshooting

**Messages not appearing?**
1. Check `status` - are you logged in?
2. Try `sync` to refresh
3. Check bridge bot for error messages

**Portal missing?**
1. Use `list-teams` or `list-chats`
2. Click on the conversation to recreate portal

**Bot not responding?**
1. Check bridge is running
2. Try `ping` command
3. Contact bridge administrator

See [troubleshooting.md](troubleshooting.md) for more help.

### Best Practices

1. **Keep OAuth token fresh:** Re-login if you see authentication errors
2. **Don't spam sync:** Only use `sync` when necessary
3. **Report issues:** Use `help` to find support channels
4. **Update regularly:** Keep bridge updated for bug fixes and features

---

## Limitations

### What Works

✅ Text messages (bi-directional)
✅ Images and files
✅ Reactions
✅ Replies
✅ Message edits
✅ Message deletions
✅ @mentions
✅ Channel and chat bridging

### What Doesn't Work (Yet)

❌ Voice/video calls
❌ Meeting scheduling
❌ Teams apps/bots
❌ Complex Adaptive Cards
❌ Message history (only new messages)
❌ Poll voting
❌ Live events

---

## Getting Help

### Support Channels

- **Matrix Room:** [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net)
- **GitHub Issues:** [Report bugs or request features](https://github.com/yourorg/beeper-teams-bridge/issues)
- **Documentation:** Check other docs in `/docs` folder

### Useful Commands for Support

When asking for help, include:

```
version
```
```
status
```

And describe:
- What you tried to do
- What actually happened
- Any error messages from the bridge bot

---

## Examples

### Example: Starting a New Conversation

```
You: list-teams

Bot: 📋 Your Teams:
     1. Engineering Team (5 channels)
     2. Marketing Team (3 channels)
     3. All Company (12 channels)

You: [Click "Engineering Team"]

Bot: 📋 Channels in Engineering Team:
     1. #general (portal exists)
     2. #development (no portal)
     3. #code-review (no portal)

You: [Click "#development"]

Bot: ✅ Created portal for Engineering Team > #development
     Room: #teams_dev_channel:matrix.example.com
     You've been invited!

[Accept invitation and start chatting]
```

### Example: Daily Usage

```
[Morning: New Teams message arrives]
[Matrix: You're invited to new room]
[Accept invitation]

Teams user: Good morning! Did you see the design docs?

You (in Matrix): Yes, I reviewed them yesterday. Looks great!

Teams user: 👍

[Your Matrix client shows thumbs up reaction]

You: [Send image of updated mockup]

Teams user: Perfect! I'll share with the team.
```

---

**Ready to start?** Send `login` to the bridge bot!

Need setup help? See [setup.md](setup.md)
