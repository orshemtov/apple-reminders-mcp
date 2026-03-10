# Apple Reminders MCP Agents

This repository exposes a local MCP server named `apple_reminders` through `opencode.json`.

## Local validation guidance

- Prefer read operations first.
- If testing write operations, create clearly labeled temporary reminder lists or reminders and clean them up afterward.
- Prefer `complete_reminder` and `uncomplete_reminder` for completion-state checks.
- If macOS Reminders permission is denied, report that explicitly instead of treating it as a generic MCP failure.

## Expected tool scope

The server exposes tools for:

- reminder sources and default list discovery
- reminder list CRUD
- reminder CRUD
- completion and bulk reminder mutations
- filtered reminder queries for all, completed, and upcoming reminders
