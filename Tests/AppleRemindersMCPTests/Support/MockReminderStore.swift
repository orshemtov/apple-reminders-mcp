import Foundation

@testable import AppleRemindersMCP

actor MockReminderStore: ReminderStoreProtocol {
    var listsResult: [ReminderList] = []
    var listByID: [String: ReminderList] = [:]
    var remindersResult: [Reminder] = []
    var reminderByID: [String: Reminder] = [:]
    var createListHandler: ((ReminderListCreateRequest) throws -> ReminderList)?
    var updateListHandler: ((String, ReminderListPatch) throws -> ReminderList)?
    var deleteListHandler: ((String) throws -> Void)?
    var remindersHandler: ((ReminderQuery) throws -> [Reminder])?
    var createReminderHandler: ((ReminderCreateRequest) throws -> Reminder)?
    var updateReminderHandler: ((String, ReminderPatch) throws -> Reminder)?
    var completeReminderHandler: ((String) throws -> Reminder)?
    var uncompleteReminderHandler: ((String) throws -> Reminder)?
    var deleteReminderHandler: ((String) throws -> Void)?

    private(set) var receivedQueries: [ReminderQuery] = []
    private(set) var createdReminders: [ReminderCreateRequest] = []
    private(set) var updatedReminders: [(String, ReminderPatch)] = []

    func seedLists(_ lists: [ReminderList]) {
        self.listsResult = lists
        self.listByID = Dictionary(uniqueKeysWithValues: lists.map { ($0.id, $0) })
    }

    func seedReminders(_ reminders: [Reminder]) {
        self.remindersResult = reminders
        self.reminderByID = Dictionary(uniqueKeysWithValues: reminders.map { ($0.id, $0) })
    }

    func setDeleteReminderHandler(_ handler: @escaping (String) throws -> Void) {
        self.deleteReminderHandler = handler
    }

    func capturedCreatedReminders() -> [ReminderCreateRequest] {
        createdReminders
    }

    func capturedUpdatedReminders() -> [(String, ReminderPatch)] {
        updatedReminders
    }

    func capturedQueries() -> [ReminderQuery] {
        receivedQueries
    }

    func ensureAccess() async throws {}

    func lists() async throws -> [ReminderList] {
        listsResult
    }

    func list(id: String) async throws -> ReminderList {
        if let item = listByID[id] {
            return item
        }
        throw ToolError.listNotFound(id)
    }

    func createList(_ request: ReminderListCreateRequest) async throws -> ReminderList {
        if let createListHandler {
            return try createListHandler(request)
        }
        let item = ReminderList(
            id: UUID().uuidString,
            title: request.title,
            sourceID: request.sourceID ?? "source-1",
            sourceTitle: "iCloud",
            sourceType: "caldav",
            colorHex: nil,
            allowsModifications: true,
            isImmutable: false,
            isDefault: false
        )
        listByID[item.id] = item
        listsResult.append(item)
        return item
    }

    func updateList(id: String, patch: ReminderListPatch) async throws -> ReminderList {
        if let updateListHandler {
            return try updateListHandler(id, patch)
        }
        guard var item = listByID[id] else {
            throw ToolError.listNotFound(id)
        }
        if let title = patch.title {
            item = ReminderList(
                id: item.id,
                title: title,
                sourceID: item.sourceID,
                sourceTitle: item.sourceTitle,
                sourceType: item.sourceType,
                colorHex: item.colorHex,
                allowsModifications: item.allowsModifications,
                isImmutable: item.isImmutable,
                isDefault: item.isDefault
            )
            listByID[id] = item
        }
        return item
    }

    func deleteList(id: String) async throws {
        if let deleteListHandler {
            try deleteListHandler(id)
            return
        }
        if listByID.removeValue(forKey: id) == nil {
            throw ToolError.listNotFound(id)
        }
        listsResult.removeAll(where: { $0.id == id })
    }

    func reminders(query: ReminderQuery) async throws -> [Reminder] {
        receivedQueries.append(query)
        if let remindersHandler {
            return try remindersHandler(query)
        }
        return remindersResult
    }

    func reminder(id: String) async throws -> Reminder {
        if let item = reminderByID[id] {
            return item
        }
        throw ToolError.reminderNotFound(id)
    }

    func createReminder(_ request: ReminderCreateRequest) async throws -> Reminder {
        createdReminders.append(request)
        if let createReminderHandler {
            return try createReminderHandler(request)
        }
        let reminder = ReminderFixtures.reminder(id: UUID().uuidString, title: request.title)
        reminderByID[reminder.id] = reminder
        remindersResult.append(reminder)
        return reminder
    }

    func updateReminder(id: String, patch: ReminderPatch) async throws -> Reminder {
        updatedReminders.append((id, patch))
        if let updateReminderHandler {
            return try updateReminderHandler(id, patch)
        }
        guard var reminder = reminderByID[id] else {
            throw ToolError.reminderNotFound(id)
        }
        let title = patch.title ?? reminder.title
        reminder = ReminderFixtures.reminder(id: reminder.id, title: title)
        reminderByID[id] = reminder
        return reminder
    }

    func completeReminder(id: String) async throws -> Reminder {
        if let completeReminderHandler {
            return try completeReminderHandler(id)
        }
        guard let reminder = reminderByID[id] else {
            throw ToolError.reminderNotFound(id)
        }
        let updated = Reminder(
            id: reminder.id,
            externalID: reminder.externalID,
            listID: reminder.listID,
            listTitle: reminder.listTitle,
            sourceTitle: reminder.sourceTitle,
            title: reminder.title,
            notes: reminder.notes,
            priority: reminder.priority,
            isCompleted: true,
            completionDate: DateFormatting.string(from: Date()),
            startDate: reminder.startDate,
            dueDate: reminder.dueDate,
            url: reminder.url,
            alarms: reminder.alarms,
            recurrence: reminder.recurrence
        )
        reminderByID[id] = updated
        return updated
    }

    func uncompleteReminder(id: String) async throws -> Reminder {
        if let uncompleteReminderHandler {
            return try uncompleteReminderHandler(id)
        }
        guard let reminder = reminderByID[id] else {
            throw ToolError.reminderNotFound(id)
        }
        let updated = Reminder(
            id: reminder.id,
            externalID: reminder.externalID,
            listID: reminder.listID,
            listTitle: reminder.listTitle,
            sourceTitle: reminder.sourceTitle,
            title: reminder.title,
            notes: reminder.notes,
            priority: reminder.priority,
            isCompleted: false,
            completionDate: nil,
            startDate: reminder.startDate,
            dueDate: reminder.dueDate,
            url: reminder.url,
            alarms: reminder.alarms,
            recurrence: reminder.recurrence
        )
        reminderByID[id] = updated
        return updated
    }

    func deleteReminder(id: String) async throws {
        if let deleteReminderHandler {
            try deleteReminderHandler(id)
            return
        }
        if reminderByID.removeValue(forKey: id) == nil {
            throw ToolError.reminderNotFound(id)
        }
        remindersResult.removeAll(where: { $0.id == id })
    }
}

enum ReminderFixtures {
    static func list(id: String = "list-1", title: String = "Inbox") -> ReminderList {
        ReminderList(
            id: id,
            title: title,
            sourceID: "source-1",
            sourceTitle: "iCloud",
            sourceType: "caldav",
            colorHex: nil,
            allowsModifications: true,
            isImmutable: false,
            isDefault: id == "list-1"
        )
    }

    static func reminder(id: String = "reminder-1", title: String = "Buy milk") -> Reminder {
        Reminder(
            id: id,
            externalID: nil,
            listID: "list-1",
            listTitle: "Inbox",
            sourceTitle: "iCloud",
            title: title,
            notes: "2% preferred",
            priority: 5,
            isCompleted: false,
            completionDate: nil,
            startDate: nil,
            dueDate: nil,
            url: nil,
            alarms: [],
            recurrence: nil
        )
    }
}
