# Apple Reminders MCP

<p align="center">
  <img src="docs/logo.png" alt="Apple Reminders MCP logo" width="900">
</p>

[![CI](https://github.com/orshemtov/apple-reminders-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/orshemtov/apple-reminders-mcp/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Swift](https://img.shields.io/badge/swift-6.2-orange)](https://swift.org)

An MCP server for Apple Reminders on macOS, built with Swift, the official MCP Swift SDK, and EventKit.

## Features

| Area | Tools |
| --- | --- |
| Sources | `list_sources`, `get_default_list` |
| Lists | `list_lists`, `get_list`, `create_list`, `update_list`, `delete_list` |
| Reminders | `list_reminders`, `list_completed_reminders`, `list_upcoming_reminders`, `get_reminder`, `create_reminder`, `update_reminder`, `complete_reminder`, `uncomplete_reminder`, `bulk_complete_reminders`, `bulk_delete_reminders`, `bulk_move_reminders`, `delete_reminder` |

- Structured MCP responses for agent-friendly automation
- macOS-native reminders access through EventKit

## Requirements

- macOS 13+
- A local macOS user account with Reminders available on that machine
- Reminders permission granted to the executable that runs the server

## Homebrew

Install:

```bash
brew install orshemtov/brew/apple-reminders-mcp
```

Run:

```bash
apple-reminders-mcp --help
```

Upgrade after new releases:

```bash
brew update
brew upgrade apple-reminders-mcp
```

Homebrew does not update the binary on your machine automatically in the background. New versions become available after the tap formula is updated for a release, and users then upgrade with `brew upgrade`.

Maintainers can find the release and tap automation notes in `docs/homebrew.md`.

## MCP Client Setup

### Claude Code

Add the server with Claude Code's native MCP command:

```bash
claude mcp add --transport stdio apple-reminders -- apple-reminders-mcp
```

Check that it is available:

```bash
claude mcp list
```

### OpenCode

Add this to your `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "mcp": {
    "apple-reminders": {
      "type": "local",
      "command": ["apple-reminders-mcp"],
      "enabled": true
    }
  }
}
```

### Codex

Add the server with Codex's native MCP command:

```bash
codex mcp add apple-reminders -- apple-reminders-mcp
```

You can also configure it manually in `~/.codex/config.toml`:

```toml
[mcp_servers.apple-reminders]
command = "apple-reminders-mcp"
```

### GitHub Copilot CLI

Use Copilot CLI's built-in MCP flow:

```text
/mcp add
```

Then enter:

- Server Name: `apple-reminders`
- Server Type: `STDIO`
- Command: `apple-reminders-mcp`
- Tools: `*`

If you prefer editing the config directly, add this to `~/.copilot/mcp-config.json`:

```json
{
  "mcpServers": {
    "apple-reminders": {
      "type": "local",
      "command": "apple-reminders-mcp",
      "args": [],
      "env": {},
      "tools": ["*"]
    }
  }
}
```

## Permissions

- This server reads and writes the Reminders database of the Mac where it is running.
- The Reminders app does not need to stay open, but Reminders data must exist on that Mac through a local or synced account.
- On first run, macOS prompts for Reminders access.
- If access was denied before, re-enable it in `System Settings > Privacy & Security > Reminders` for the terminal or app that launches the server.

## Example Prompts

- "Show my upcoming reminders for this week"
- "Create a reminder tomorrow at 9am to call Mom"
- "Move all grocery reminders to my Shopping list"
- "List completed reminders from today"

## Notes

- v1 supports the reminder `url` field, plain reminder `location`, location alarms, recurrence, source metadata, and list color updates.
- v1 does not support arbitrary file or image attachments because EventKit does not expose a clear public API for them on reminders.
