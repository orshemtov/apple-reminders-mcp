import Foundation

@testable import AppleRemindersMCP

actor MockReminderStore: ReminderStoreProtocol {
    var sourcesResult: [ReminderSource] = []
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

    func seedSources(_ sources: [ReminderSource]) {
        self.sourcesResult = sources
    }

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

    func capturedCreatedReminders() -> [ReminderCreateRequest] { createdReminders }
    func capturedUpdatedReminders() -> [(String, ReminderPatch)] { updatedReminders }
    func capturedQueries() -> [ReminderQuery] { receivedQueries }

    func ensureAccess() async throws {}

    func sources() async throws -> [ReminderSource] {
        if sourcesResult.isEmpty {
            return [ReminderFixtures.source()]
        }
        return sourcesResult
    }

    func defaultList() async throws -> ReminderList {
        if let defaultList = listsResult.first(where: { $0.isDefault }) {
            return defaultList
        }
        throw ToolError.noDefaultList
    }

    func lists() async throws -> [ReminderList] { listsResult }

    func list(id: String) async throws -> ReminderList {
        if let item = listByID[id] { return item }
        throw ToolError.listNotFound(id)
    }

    func createList(_ request: ReminderListCreateRequest) async throws -> ReminderList {
        if let createListHandler { return try createListHandler(request) }
        let item = ReminderList(
            id: UUID().uuidString,
            title: request.title,
            sourceID: request.sourceID ?? "source-1",
            sourceTitle: "iCloud",
            sourceType: "caldav",
            colorHex: request.colorHex,
            allowsModifications: true,
            isImmutable: false,
            isDefault: false
        )
        listByID[item.id] = item
        listsResult.append(item)
        return item
    }

    func updateList(id: String, patch: ReminderListPatch) async throws -> ReminderList {
        if let updateListHandler { return try updateListHandler(id, patch) }
        guard let current = listByID[id] else { throw ToolError.listNotFound(id) }
        let item = ReminderList(
            id: current.id,
            title: patch.title ?? current.title,
            sourceID: current.sourceID,
            sourceTitle: current.sourceTitle,
            sourceType: current.sourceType,
            colorHex: {
                switch patch.colorHex {
                case .set(let color): return color
                case .clear: return nil
                case .unspecified: return current.colorHex
                }
            }(),
            allowsModifications: current.allowsModifications,
            isImmutable: current.isImmutable,
            isDefault: current.isDefault
        )
        listByID[id] = item
        listsResult.removeAll(where: { $0.id == id })
        listsResult.append(item)
        return item
    }

    func deleteList(id: String) async throws {
        if let deleteListHandler {
            try deleteListHandler(id)
            return
        }
        guard listByID.removeValue(forKey: id) != nil else { throw ToolError.listNotFound(id) }
        listsResult.removeAll(where: { $0.id == id })
    }

    func reminders(query: ReminderQuery) async throws -> [Reminder] {
        receivedQueries.append(query)
        if let remindersHandler { return try remindersHandler(query) }
        return remindersResult
    }

    func reminder(id: String) async throws -> Reminder {
        if let item = reminderByID[id] { return item }
        throw ToolError.reminderNotFound(id)
    }

    func createReminder(_ request: ReminderCreateRequest) async throws -> Reminder {
        createdReminders.append(request)
        if let createReminderHandler { return try createReminderHandler(request) }
        let reminder = ReminderFixtures.reminder(
            id: UUID().uuidString, title: request.title, location: request.location)
        reminderByID[reminder.id] = reminder
        remindersResult.append(reminder)
        return reminder
    }

    func updateReminder(id: String, patch: ReminderPatch) async throws -> Reminder {
        updatedReminders.append((id, patch))
        if let updateReminderHandler { return try updateReminderHandler(id, patch) }
        guard let current = reminderByID[id] else { throw ToolError.reminderNotFound(id) }
        let reminder = ReminderFixtures.reminder(
            id: current.id,
            title: patch.title ?? current.title,
            location: {
                switch patch.location {
                case .set(let location): return location
                case .clear: return nil
                case .unspecified: return current.location
                }
            }()
        )
        reminderByID[id] = reminder
        return reminder
    }

    func completeReminder(id: String) async throws -> Reminder {
        if let completeReminderHandler { return try completeReminderHandler(id) }
        guard let reminder = reminderByID[id] else { throw ToolError.reminderNotFound(id) }
        let updated = ReminderFixtures.reminder(
            id: reminder.id, title: reminder.title, location: reminder.location, isCompleted: true)
        reminderByID[id] = updated
        return updated
    }

    func uncompleteReminder(id: String) async throws -> Reminder {
        if let uncompleteReminderHandler { return try uncompleteReminderHandler(id) }
        guard let reminder = reminderByID[id] else { throw ToolError.reminderNotFound(id) }
        let updated = ReminderFixtures.reminder(
            id: reminder.id, title: reminder.title, location: reminder.location, isCompleted: false)
        reminderByID[id] = updated
        return updated
    }

    func deleteReminder(id: String) async throws {
        if let deleteReminderHandler {
            try deleteReminderHandler(id)
            return
        }
        guard reminderByID.removeValue(forKey: id) != nil else { throw ToolError.reminderNotFound(id) }
        remindersResult.removeAll(where: { $0.id == id })
    }

    func bulkCompleteReminders(ids: [String], dryRun: Bool) async throws -> [Reminder] {
        let reminders = try ids.map { id in
            guard let reminder = reminderByID[id] else { throw ToolError.reminderNotFound(id) }
            return reminder
        }
        return reminders.map { reminder in
            ReminderFixtures.reminder(
                id: reminder.id, title: reminder.title, location: reminder.location, isCompleted: true)
        }
    }

    func bulkDeleteReminders(ids: [String], dryRun: Bool) async throws -> [Reminder] {
        try ids.map { id in
            guard let reminder = reminderByID[id] else { throw ToolError.reminderNotFound(id) }
            return reminder
        }
    }

    func bulkMoveReminders(ids: [String], targetListID: String, dryRun: Bool) async throws -> [Reminder] {
        let reminders = try ids.map { id in
            guard let reminder = reminderByID[id] else { throw ToolError.reminderNotFound(id) }
            return reminder
        }
        return reminders.map { reminder in
            Reminder(
                id: reminder.id,
                externalID: reminder.externalID,
                listID: targetListID,
                listTitle: "Moved",
                sourceID: reminder.sourceID,
                sourceTitle: reminder.sourceTitle,
                title: reminder.title,
                location: reminder.location,
                notes: reminder.notes,
                priority: reminder.priority,
                isCompleted: reminder.isCompleted,
                completionDate: reminder.completionDate,
                startDate: reminder.startDate,
                dueDate: reminder.dueDate,
                url: reminder.url,
                alarms: reminder.alarms,
                recurrence: reminder.recurrence,
                hasAlarms: reminder.hasAlarms,
                hasRecurrence: reminder.hasRecurrence,
                isAllDay: reminder.isAllDay,
                creationDate: reminder.creationDate,
                lastModifiedDate: reminder.lastModifiedDate
            )
        }
    }
}

enum ReminderFixtures {
    static func source(id: String = "source-1", title: String = "iCloud") -> ReminderSource {
        ReminderSource(id: id, title: title, type: "caldav", listCount: 1)
    }

    static func list(id: String = "list-1", title: String = "Inbox", colorHex: String? = nil) -> ReminderList {
        ReminderList(
            id: id,
            title: title,
            sourceID: "source-1",
            sourceTitle: "iCloud",
            sourceType: "caldav",
            colorHex: colorHex,
            allowsModifications: true,
            isImmutable: false,
            isDefault: id == "list-1"
        )
    }

    static func reminder(
        id: String = "reminder-1",
        title: String = "Buy milk",
        location: String? = nil,
        isCompleted: Bool = false
    ) -> Reminder {
        Reminder(
            id: id,
            externalID: nil,
            listID: "list-1",
            listTitle: "Inbox",
            sourceID: "source-1",
            sourceTitle: "iCloud",
            title: title,
            location: location,
            notes: "2% preferred",
            priority: 5,
            isCompleted: isCompleted,
            completionDate: isCompleted ? DateFormatting.string(from: Date()) : nil,
            startDate: nil,
            dueDate: nil,
            url: nil,
            alarms: [],
            recurrence: nil,
            hasAlarms: false,
            hasRecurrence: false,
            isAllDay: false,
            creationDate: DateFormatting.string(from: Date(timeIntervalSince1970: 0)),
            lastModifiedDate: DateFormatting.string(from: Date(timeIntervalSince1970: 0))
        )
    }
}
