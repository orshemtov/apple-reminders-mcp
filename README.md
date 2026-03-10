# Apple Reminders MCP

<p align="center">
  <img src="docs/logo.png" alt="Apple Reminders MCP logo" width="900">
</p>

[![CI](https://github.com/orshemtov/apple-reminders-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/orshemtov/apple-reminders-mcp/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Format](https://img.shields.io/badge/format-swift--format-informational)](#development)
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
- Swift 6.2+
- A local macOS user account with Reminders available on that machine
- Reminders permission granted to the executable that runs the server

## Prerequisites And Permissions

- This server reads and writes the Reminders database of the Mac where it is running.
- The Reminders app does not need to stay open, but Reminders data must exist on that Mac through a local or synced account.
- On first run, macOS prompts for Reminders access. If the user denies it, tool calls return a clear permission error.
- If access was denied before, re-enable it in `System Settings > Privacy & Security > Reminders` for the host app or terminal that launches the server.

## Install From Source

```bash
git clone https://github.com/orshemtov/apple-reminders-mcp.git
cd apple-reminders-mcp
swift build
```

## Run

```bash
swift run apple-reminders-mcp
```

## Homebrew

Homebrew distribution will be published through the `orshemtov/brew` tap.

```bash
brew install orshemtov/brew/apple-reminders-mcp
```

Until the first tagged release is published, use the source install path above.

## MCP Client Config

Example stdio entry:

```json
{
  "mcpServers": {
    "apple-reminders": {
      "command": "swift",
      "args": ["run", "--package-path", "/absolute/path/to/apple-reminders-mcp", "apple-reminders-mcp"]
    }
  }
}
```

## Notes

- v1 supports the reminder `url` field, plain reminder `location`, location alarms, recurrence, source metadata, and list color updates.
- v1 does not support arbitrary file or image attachments because EventKit does not expose a clear public API for them on reminders.
