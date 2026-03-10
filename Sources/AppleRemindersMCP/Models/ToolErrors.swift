import Foundation

public enum ToolError: LocalizedError, Equatable, Sendable {
    case permissionDenied
    case noDefaultList
    case invalidArguments(String)
    case listNotFound(String)
    case reminderNotFound(String)
    case listNotWritable(String)
    case unsupported(String)
    case eventKit(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Reminders access is not granted. Allow this executable to access Reminders in System Settings."
        case .noDefaultList:
            return "No default reminders list is configured, and no list_id was provided."
        case .invalidArguments(let message):
            return message
        case .listNotFound(let id):
            return "Reminder list not found: \(id)"
        case .reminderNotFound(let id):
            return "Reminder not found: \(id)"
        case .listNotWritable(let id):
            return "Reminder list is read-only or immutable: \(id)"
        case .unsupported(let message):
            return message
        case .eventKit(let message):
            return message
        }
    }
}
