# Apple Reminders MCP

[![CI](https://github.com/or/apple-reminders-mcp/actions/workflows/ci.yml/badge.svg)](https://github.com/or/apple-reminders-mcp/actions/workflows/ci.yml)
[![Format](https://img.shields.io/badge/format-swift--format-informational)](#development)
[![Swift](https://img.shields.io/badge/swift-6.2-orange)](https://swift.org)

An MCP server for Apple Reminders on macOS, built with Swift, the official MCP Swift SDK, and EventKit.

## Features

- Reminder list tools: `list_lists`, `get_list`, `create_list`, `update_list`, `delete_list`
- Reminder tools: `list_reminders`, `get_reminder`, `create_reminder`, `update_reminder`, `complete_reminder`, `uncomplete_reminder`, `delete_reminder`
- Structured MCP responses for agent-friendly automation
- macOS-native reminders access through EventKit

## Requirements

- macOS 13+
- Swift 6.2+
- Reminders access granted to the executable running the server

## Install

```bash
git clone https://github.com/or/apple-reminders-mcp.git
cd apple-reminders-mcp
swift build
```

## Run

```bash
swift run apple-reminders-mcp
```

On first run, macOS asks for Reminders permission. If access is denied, tool calls return a clear MCP error.

## MCP client config

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

- v1 supports the reminder `url` field.
- v1 does not support arbitrary file or image attachments because EventKit does not expose a clear public API for them on reminders.

## Development

- `just build` - build the package
- `just run` - run the MCP server
- `just test` - run the test suite
- `just format` - format Swift sources in place
- `just lint` - run `swift-format` in lint mode
- `just check` - run lint and tests

## CI

GitHub Actions runs formatting, linting, build, and tests on macOS for pushes and pull requests.
