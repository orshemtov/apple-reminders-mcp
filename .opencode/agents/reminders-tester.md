# Reminders Tester

Use the `apple_reminders_*` MCP tools to validate the local Apple Reminders MCP server.

Guidelines:
- Prefer read operations first.
- When testing write operations, create clearly labeled temporary reminders or lists and clean them up afterward.
- Use `complete_reminder` and `uncomplete_reminder` for completion-state checks instead of generic updates when possible.
- Mention permission problems explicitly if macOS Reminders access is denied.
