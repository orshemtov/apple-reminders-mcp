import Foundation
import Logging
import MCP

public struct ToolDispatcher: Sendable {
    private let toolCatalog: ToolCatalog
    private let reminderStore: any ReminderStoreProtocol
    private let logger: Logger

    public init(toolCatalog: ToolCatalog, reminderStore: any ReminderStoreProtocol, logger: Logger) {
        self.toolCatalog = toolCatalog
        self.reminderStore = reminderStore
        self.logger = logger
    }

    public func handleCall(_ params: CallTool.Parameters) async throws -> CallTool.Result {
        do {
            logger.info("Tool call", metadata: ["tool": .string(params.name)])
            switch params.name {
            case ToolName.listSources:
                let items = try await reminderStore.sources()
                return try result(message: "Listed \(items.count) reminder sources.", items: items)

            case ToolName.getDefaultList:
                let item = try await reminderStore.defaultList()
                return try result(message: "Fetched default reminder list.", item: item)

            case ToolName.listLists:
                let items = try await reminderStore.lists()
                return try result(message: "Listed \(items.count) reminder lists.", items: items)

            case ToolName.getList:
                let item = try await reminderStore.list(
                    id: try ToolArgumentParser.requiredString("list_id", from: params.arguments))
                return try result(message: "Fetched reminder list.", item: item)

            case ToolName.createList:
                let item = try await reminderStore.createList(
                    .init(
                        title: try ToolArgumentParser.requiredString("title", from: params.arguments),
                        sourceID: ToolArgumentParser.optionalString("source_id", from: params.arguments),
                        colorHex: ToolArgumentParser.optionalString("color_hex", from: params.arguments)
                    )
                )
                return try result(message: "Created reminder list.", item: item)

            case ToolName.updateList:
                let item = try await reminderStore.updateList(
                    id: try ToolArgumentParser.requiredString("list_id", from: params.arguments),
                    patch: .init(
                        title: ToolArgumentParser.optionalString("title", from: params.arguments),
                        colorHex: patchValue(
                            clearFlag: ToolArgumentParser.optionalBool("clear_color", from: params.arguments) ?? false,
                            value: ToolArgumentParser.optionalString("color_hex", from: params.arguments)
                        )
                    )
                )
                return try result(message: "Updated reminder list.", item: item)

            case ToolName.deleteList:
                let id = try ToolArgumentParser.requiredString("list_id", from: params.arguments)
                try await reminderStore.deleteList(id: id)
                let payload = ReminderListMutationResult(
                    success: true, message: "Deleted reminder list.", list: nil, deletedListID: id, warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            case ToolName.listReminders:
                let items = try await remindersWithProgress(
                    params: params, query: try makeReminderQuery(from: params.arguments, defaultCompletionState: .all))
                return try result(message: "Listed \(items.count) reminders.", items: items)

            case ToolName.listCompletedReminders:
                let items = try await remindersWithProgress(
                    params: params,
                    query: try makeReminderQuery(from: params.arguments, defaultCompletionState: .completed))
                return try result(message: "Listed \(items.count) completed reminders.", items: items)

            case ToolName.listUpcomingReminders:
                var query = try makeReminderQuery(from: params.arguments, defaultCompletionState: .incomplete)
                if query.dueStarting == nil {
                    query.dueStarting = Date()
                }
                let items = try await remindersWithProgress(params: params, query: query)
                return try result(message: "Listed \(items.count) upcoming reminders.", items: items)

            case ToolName.getReminder:
                let item = try await reminderStore.reminder(
                    id: try ToolArgumentParser.requiredString("reminder_id", from: params.arguments))
                return try result(message: "Fetched reminder.", item: item)

            case ToolName.createReminder:
                let item = try await reminderStore.createReminder(try makeCreateReminderRequest(from: params.arguments))
                let payload = ReminderMutationResult(
                    success: true, message: "Created reminder.", reminder: item, deletedReminderID: nil,
                    warnings: attachmentWarnings)
                return try mutationResult(message: payload.message, payload: payload, warnings: attachmentWarnings)

            case ToolName.updateReminder:
                let item = try await reminderStore.updateReminder(
                    id: try ToolArgumentParser.requiredString("reminder_id", from: params.arguments),
                    patch: try makeReminderPatch(from: params.arguments)
                )
                let payload = ReminderMutationResult(
                    success: true, message: "Updated reminder.", reminder: item, deletedReminderID: nil, warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            case ToolName.completeReminder:
                let item = try await reminderStore.completeReminder(
                    id: try ToolArgumentParser.requiredString("reminder_id", from: params.arguments))
                let payload = ReminderMutationResult(
                    success: true, message: "Completed reminder.", reminder: item, deletedReminderID: nil, warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            case ToolName.uncompleteReminder:
                let item = try await reminderStore.uncompleteReminder(
                    id: try ToolArgumentParser.requiredString("reminder_id", from: params.arguments))
                let payload = ReminderMutationResult(
                    success: true, message: "Marked reminder as incomplete.", reminder: item, deletedReminderID: nil,
                    warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            case ToolName.bulkCompleteReminders:
                let ids = try requiredStringArray("reminder_ids", from: params.arguments)
                let dryRun = ToolArgumentParser.optionalBool("dry_run", from: params.arguments) ?? false
                let reminders = try await reminderStore.bulkCompleteReminders(ids: ids, dryRun: dryRun)
                let payload = BulkReminderMutationResult(
                    success: true,
                    message: dryRun ? "Previewed bulk complete operation." : "Completed reminders in bulk.",
                    dryRun: dryRun, affectedReminders: reminders, targetListID: nil, warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            case ToolName.bulkDeleteReminders:
                let ids = try requiredStringArray("reminder_ids", from: params.arguments)
                let dryRun = ToolArgumentParser.optionalBool("dry_run", from: params.arguments) ?? false
                let reminders = try await reminderStore.bulkDeleteReminders(ids: ids, dryRun: dryRun)
                let payload = BulkReminderMutationResult(
                    success: true, message: dryRun ? "Previewed bulk delete operation." : "Deleted reminders in bulk.",
                    dryRun: dryRun, affectedReminders: reminders, targetListID: nil, warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            case ToolName.bulkMoveReminders:
                let ids = try requiredStringArray("reminder_ids", from: params.arguments)
                let targetListID = try ToolArgumentParser.requiredString("target_list_id", from: params.arguments)
                let dryRun = ToolArgumentParser.optionalBool("dry_run", from: params.arguments) ?? false
                let reminders = try await reminderStore.bulkMoveReminders(
                    ids: ids, targetListID: targetListID, dryRun: dryRun)
                let payload = BulkReminderMutationResult(
                    success: true, message: dryRun ? "Previewed bulk move operation." : "Moved reminders in bulk.",
                    dryRun: dryRun, affectedReminders: reminders, targetListID: targetListID, warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            case ToolName.deleteReminder:
                let id = try ToolArgumentParser.requiredString("reminder_id", from: params.arguments)
                try await reminderStore.deleteReminder(id: id)
                let payload = ReminderMutationResult(
                    success: true, message: "Deleted reminder.", reminder: nil, deletedReminderID: id, warnings: [])
                return try mutationResult(message: payload.message, payload: payload)

            default:
                let known = toolCatalog.allTools.map(\.name).joined(separator: ", ")
                throw ToolError.invalidArguments("Unknown tool: \(params.name). Available tools: \(known)")
            }
        } catch {
            logger.error(
                "Tool call failed",
                metadata: ["tool": .string(params.name), "error": .string(error.localizedDescription)])
            return errorResult(error)
        }
    }

    private var attachmentWarnings: [String] {
        ["File and image reminder attachments are not supported in v1. Use the reminder URL field instead."]
    }

    private func remindersWithProgress(params: CallTool.Parameters, query: ReminderQuery) async throws -> [Reminder] {
        if params._meta?.progressToken != nil {
            logger.info("Progress requested for reminder query", metadata: ["tool": .string(params.name)])
        }
        return try await reminderStore.reminders(query: query)
    }

    private func result<T: Codable & Sendable>(message: String, item: T) throws -> CallTool.Result {
        let envelope = ToolEnvelope(success: true, message: message, item: item)
        return try CallTool.Result(
            content: [.text(renderContent(message: message, payload: envelope))], structuredContent: envelope)
    }

    private func result<T: Codable & Sendable>(message: String, items: [T], warnings: [String] = []) throws
        -> CallTool.Result
    {
        let envelope = ToolEnvelope(success: true, message: message, item: nil as T?, items: items, warnings: warnings)
        return try CallTool.Result(
            content: [.text(renderContent(message: message, payload: envelope))], structuredContent: envelope)
    }

    private func mutationResult<T: Codable & Sendable>(message: String, payload: T, warnings: [String] = []) throws
        -> CallTool.Result
    {
        try CallTool.Result(
            content: [.text(renderContent(message: message, payload: payload, warnings: warnings))],
            structuredContent: payload)
    }

    private func errorResult(_ error: Error) -> CallTool.Result {
        let message = error.localizedDescription
        return CallTool.Result(
            content: [.text(message)],
            structuredContent: .object([
                "success": .bool(false),
                "message": .string(message),
            ]),
            isError: true
        )
    }

    private func renderContent<T>(message: String, payload: T, warnings: [String] = []) -> String {
        var lines = [message]

        switch payload {
        case let envelope as ToolEnvelope<ReminderSource>:
            if let item = envelope.item { lines.append(render(source: item)) }
            if let items = envelope.items { lines.append(contentsOf: items.map(render(source:))) }

        case let envelope as ToolEnvelope<ReminderList>:
            if let item = envelope.item { lines.append(render(list: item)) }
            if let items = envelope.items { lines.append(contentsOf: items.map(render(list:))) }

        case let envelope as ToolEnvelope<Reminder>:
            if let item = envelope.item { lines.append(render(reminder: item)) }
            if let items = envelope.items { lines.append(contentsOf: items.map(render(reminder:))) }

        case let payload as ReminderMutationResult:
            if let reminder = payload.reminder { lines.append(render(reminder: reminder)) }
            if let deletedReminderID = payload.deletedReminderID {
                lines.append("Deleted reminder id: \(deletedReminderID)")
            }

        case let payload as ReminderListMutationResult:
            if let list = payload.list { lines.append(render(list: list)) }
            if let deletedListID = payload.deletedListID { lines.append("Deleted list id: \(deletedListID)") }

        case let payload as BulkReminderMutationResult:
            lines.append(payload.dryRun ? "Dry run: true" : "Dry run: false")
            if let targetListID = payload.targetListID { lines.append("Target list id: \(targetListID)") }
            lines.append(contentsOf: payload.affectedReminders.map(render(reminder:)))

        default:
            break
        }

        lines.append(contentsOf: warnings)
        return lines.joined(separator: "\n")
    }

    private func render(source: ReminderSource) -> String {
        "- \(source.title) | id: \(source.id) | type: \(source.type) | lists: \(source.listCount)"
    }

    private func render(list: ReminderList) -> String {
        let defaultMarker = list.isDefault ? "default" : "non-default"
        let writable = list.allowsModifications && !list.isImmutable ? "writable" : "read-only"
        return
            "- \(list.title) | id: \(list.id) | source: \(list.sourceTitle) (\(list.sourceType)) | \(defaultMarker) | \(writable) | color: \(list.colorHex ?? "none")"
    }

    private func render(reminder: Reminder) -> String {
        let due = reminder.dueDate?.iso8601 ?? "none"
        let completion = reminder.isCompleted ? "completed" : "incomplete"
        return
            "- \(reminder.title) | id: \(reminder.id) | due: \(due) | list: \(reminder.listTitle) | source: \(reminder.sourceTitle) | \(completion)"
    }

    private func makeReminderQuery(from arguments: [String: Value]?, defaultCompletionState: ReminderCompletionState)
        throws -> ReminderQuery
    {
        let includeCompleted = ToolArgumentParser.optionalBool("include_completed", from: arguments)
        let completionState: ReminderCompletionState
        if let includeCompleted {
            completionState = includeCompleted ? .all : .incomplete
        } else {
            completionState = defaultCompletionState
        }
        return ReminderQuery(
            listIDs: ToolArgumentParser.optionalStringArray("list_ids", from: arguments) ?? [],
            search: ToolArgumentParser.optionalString("search", from: arguments),
            completionState: completionState,
            dueStarting: try ToolArgumentParser.optionalDate("due_starting", from: arguments),
            dueEnding: try ToolArgumentParser.optionalDate("due_ending", from: arguments),
            completedStarting: try ToolArgumentParser.optionalDate("completed_starting", from: arguments),
            completedEnding: try ToolArgumentParser.optionalDate("completed_ending", from: arguments),
            hasDueDate: ToolArgumentParser.optionalBool("has_due_date", from: arguments),
            hasLocation: ToolArgumentParser.optionalBool("has_location", from: arguments),
            hasRecurrence: ToolArgumentParser.optionalBool("has_recurrence", from: arguments),
            priorityMin: ToolArgumentParser.optionalInt("priority_min", from: arguments),
            priorityMax: ToolArgumentParser.optionalInt("priority_max", from: arguments),
            limit: ToolArgumentParser.optionalInt("limit", from: arguments)
        )
    }

    private func makeCreateReminderRequest(from arguments: [String: Value]?) throws -> ReminderCreateRequest {
        ReminderCreateRequest(
            listID: ToolArgumentParser.optionalString("list_id", from: arguments),
            title: try ToolArgumentParser.requiredString("title", from: arguments),
            location: ToolArgumentParser.optionalString("location", from: arguments),
            notes: ToolArgumentParser.optionalString("notes", from: arguments),
            priority: ToolArgumentParser.optionalInt("priority", from: arguments),
            startDate: try parseDatePatch(from: ToolArgumentParser.optionalObject("start_date", from: arguments)),
            dueDate: try parseDatePatch(from: ToolArgumentParser.optionalObject("due_date", from: arguments)),
            url: try ToolArgumentParser.optionalURL("url", from: arguments),
            isCompleted: ToolArgumentParser.optionalBool("is_completed", from: arguments) ?? false,
            completionDate: try ToolArgumentParser.optionalDate("completion_date", from: arguments),
            recurrence: try parseRecurrence(from: ToolArgumentParser.optionalObject("recurrence", from: arguments)),
            alarms: try parseAlarmPatches(from: ToolArgumentParser.optionalObjectArray("alarms", from: arguments) ?? [])
        )
    }

    private func makeReminderPatch(from arguments: [String: Value]?) throws -> ReminderPatch {
        ReminderPatch(
            title: ToolArgumentParser.optionalString("title", from: arguments),
            location: patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_location", from: arguments) ?? false,
                value: ToolArgumentParser.optionalString("location", from: arguments)
            ),
            notes: patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_notes", from: arguments) ?? false,
                value: ToolArgumentParser.optionalString("notes", from: arguments)
            ),
            priority: patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_priority", from: arguments) ?? false,
                value: ToolArgumentParser.optionalInt("priority", from: arguments)
            ),
            startDate: try patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_start_date", from: arguments) ?? false,
                value: parseDatePatch(from: ToolArgumentParser.optionalObject("start_date", from: arguments))
            ),
            dueDate: try patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_due_date", from: arguments) ?? false,
                value: parseDatePatch(from: ToolArgumentParser.optionalObject("due_date", from: arguments))
            ),
            url: try patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_url", from: arguments) ?? false,
                value: ToolArgumentParser.optionalURL("url", from: arguments)
            ),
            isCompleted: ToolArgumentParser.optionalBool("is_completed", from: arguments),
            completionDate: try patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_completion_date", from: arguments) ?? false,
                value: ToolArgumentParser.optionalDate("completion_date", from: arguments)
            ),
            recurrence: try patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_recurrence", from: arguments) ?? false,
                value: parseRecurrence(from: ToolArgumentParser.optionalObject("recurrence", from: arguments))
            ),
            alarms: try patchValue(
                clearFlag: ToolArgumentParser.optionalBool("clear_alarms", from: arguments) ?? false,
                value: parseAlarmPatches(from: ToolArgumentParser.optionalObjectArray("alarms", from: arguments) ?? []),
                valueWasProvided: arguments?["alarms"] != nil
            ),
            listID: ToolArgumentParser.optionalString("list_id", from: arguments)
        )
    }

    private func parseDatePatch(from object: [String: Value]?) throws -> ReminderDatePatch? {
        guard let object else { return nil }
        guard let dateString = object["date"]?.stringValue, let date = DateFormatting.parse(dateString) else {
            throw ToolError.invalidArguments("Invalid reminder date payload.")
        }
        return ReminderDatePatch(
            date: date,
            allDay: object["all_day"]?.boolValue ?? false,
            timeZoneID: object["time_zone"]?.stringValue
        )
    }

    private func parseAlarmPatches(from array: [[String: Value]]) throws -> [ReminderAlarmPatch] {
        try array.map { object in
            ReminderAlarmPatch(
                absoluteDate: try parseOptionalDateValue(object["absolute_date"]),
                relativeOffset: object["relative_offset"]?.doubleValue,
                location: try parseLocationAlarm(from: object["location"]?.objectValue)
            )
        }
    }

    private func parseLocationAlarm(from object: [String: Value]?) throws -> ReminderLocationAlarmPatch? {
        guard let object else { return nil }
        guard let latitude = object["latitude"]?.doubleValue, let longitude = object["longitude"]?.doubleValue else {
            throw ToolError.invalidArguments("Location alarms require latitude and longitude.")
        }
        return ReminderLocationAlarmPatch(
            title: object["title"]?.stringValue,
            radius: object["radius"]?.doubleValue,
            latitude: latitude,
            longitude: longitude,
            proximity: object["proximity"]?.stringValue.flatMap(ReminderProximity.init(rawValue:))
        )
    }

    private func parseRecurrence(from object: [String: Value]?) throws -> ReminderRecurrencePatch? {
        guard let object else { return nil }
        guard let frequencyRaw = object["frequency"]?.stringValue,
            let frequency = ReminderFrequency(rawValue: frequencyRaw)
        else {
            throw ToolError.invalidArguments("recurrence.frequency must be one of daily, weekly, monthly, yearly")
        }
        return ReminderRecurrencePatch(
            frequency: frequency,
            interval: object["interval"]?.intValue ?? 1,
            endDate: try parseOptionalDateValue(object["end_date"]),
            occurrenceCount: object["occurrence_count"]?.intValue,
            daysOfWeek: object["days_of_week"]?.arrayValue?.compactMap { $0.stringValue }.compactMap(
                ReminderWeekday.init(rawValue:)) ?? [],
            daysOfMonth: object["days_of_month"]?.arrayValue?.compactMap(\.intValue) ?? [],
            monthsOfYear: object["months_of_year"]?.arrayValue?.compactMap(\.intValue) ?? [],
            setPositions: object["set_positions"]?.arrayValue?.compactMap(\.intValue) ?? []
        )
    }

    private func parseOptionalDateValue(_ value: Value?) throws -> Date? {
        guard let string = value?.stringValue else { return nil }
        guard let date = DateFormatting.parse(string) else {
            throw ToolError.invalidArguments("Invalid ISO-8601 date value.")
        }
        return date
    }

    private func requiredStringArray(_ key: String, from args: [String: Value]?) throws -> [String] {
        guard let values = ToolArgumentParser.optionalStringArray(key, from: args), !values.isEmpty else {
            throw ToolError.invalidArguments("Missing required string array argument: \(key)")
        }
        return values
    }

    private func patchValue<T>(clearFlag: Bool, value: T?, valueWasProvided: Bool = true) -> OptionalPatch<T>
    where T: Equatable & Sendable {
        if clearFlag {
            return .clear
        }
        if let value {
            return .set(value)
        }
        return valueWasProvided ? .unspecified : .unspecified
    }
}

extension Value {
    fileprivate var objectValue: [String: Value]? {
        if case .object(let object) = self {
            return object
        }
        return nil
    }
}
