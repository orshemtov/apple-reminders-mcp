import Foundation

public protocol ReminderStoreProtocol: Sendable {
    func ensureAccess() async throws
    func lists() async throws -> [ReminderList]
    func list(id: String) async throws -> ReminderList
    func createList(_ request: ReminderListCreateRequest) async throws -> ReminderList
    func updateList(id: String, patch: ReminderListPatch) async throws -> ReminderList
    func deleteList(id: String) async throws

    func reminders(query: ReminderQuery) async throws -> [Reminder]
    func reminder(id: String) async throws -> Reminder
    func createReminder(_ request: ReminderCreateRequest) async throws -> Reminder
    func updateReminder(id: String, patch: ReminderPatch) async throws -> Reminder
    func completeReminder(id: String) async throws -> Reminder
    func uncompleteReminder(id: String) async throws -> Reminder
    func deleteReminder(id: String) async throws
}
