# mautrix-teams

A Matrix-Microsoft Teams puppeting bridge built on the [mautrix-go](https://github.com/mautrix/go) framework.

## Features

* **Two-way messaging**: Send and receive messages between Matrix and Microsoft Teams
* **Media support**: Share images, files, and other media types
* **Typing indicators**: See when someone is typing
* **Read receipts**: Know when messages have been read
* **Presence syncing**: Share online/away/offline status
* **Reactions**: React to messages with emoji
* **Message edits**: Edit messages after sending
* **Message deletion**: Delete messages (with redactions in Matrix)
* **Thread support**: Participate in threaded conversations
* **Portal management**: Bridge specific Teams chats and channels to Matrix rooms

## Requirements

* Go 1.21 or higher
* A Matrix homeserver that supports application services
* A Microsoft Teams account
* PostgreSQL 12 or higher (SQLite3 also supported for testing)

## Installation

### From Source

```bash
git clone https://github.com/lqdev/beeper-teams-bridge.git
cd beeper-teams-bridge
go build -o mautrix-teams
```

### Using Docker

```bash
docker pull ghcr.io/lqdev/mautrix-teams:latest
```

## Configuration

1. Copy the example configuration file:
   ```bash
   cp example-config.yaml config.yaml
   ```

2. Edit `config.yaml` to match your setup:
   - Configure your homeserver URL and domain
   - Set up the database connection
   - Configure Microsoft Teams authentication settings

3. Generate the appservice registration file:
   ```bash
   ./mautrix-teams -g
   ```

4. Add the generated `registration.yaml` to your homeserver's configuration

5. Start the bridge:
   ```bash
   ./mautrix-teams
   ```

## Usage

1. Start a chat with the bridge bot (e.g., `@teamsbot:yourdomain.com`)
2. Send `login` to begin the authentication process
3. Follow the instructions to link your Microsoft Teams account
4. Your Teams chats and channels will automatically be bridged to Matrix rooms

### Available Commands

* `login` - Link your Microsoft Teams account
* `logout` - Unlink your Microsoft Teams account
* `reconnect` - Reconnect to Microsoft Teams
* `ping` - Check if the bridge is working
* `help` - Display available commands

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines and instructions.

## Support

* **Issues**: Report bugs and request features on [GitHub Issues](https://github.com/lqdev/beeper-teams-bridge/issues)
* **Matrix Room**: Join [#mautrix-teams:maunium.net](https://matrix.to/#/#mautrix-teams:maunium.net)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

* Built with [mautrix-go](https://github.com/mautrix/go) by Tulir Asokan
* Inspired by other mautrix bridges in the ecosystem

## Disclaimer

This bridge is not affiliated with or endorsed by Microsoft Corporation. Microsoft Teams is a trademark of Microsoft Corporation.
