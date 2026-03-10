import Foundation
import Logging
import MCP
import Testing

@testable import AppleRemindersMCP

struct ToolDispatcherTests {
    @Test("list_lists returns structured list payload")
    func listLists() async throws {
        let store = MockReminderStore()
        await store.seedLists([ReminderFixtures.list()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(.init(name: ToolName.listLists))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        switch content {
        case .text(let text):
            #expect(text.contains("Listed 1 reminder lists."))
            #expect(text.contains("- Inbox | id: list-1"))
            #expect(text.contains("source: iCloud"))
        default:
            Issue.record("Expected text content")
        }
        let payload = try #require(result.structuredContent?.objectValue)
        #expect(payload["success"]?.boolValue == true)
    }

    @Test("get_list returns error for missing id")
    func getListMissingArgument() async throws {
        let dispatcher = ToolDispatcher(
            toolCatalog: ToolCatalog(), reminderStore: MockReminderStore(), logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(.init(name: ToolName.getList))

        #expect(result.isError == true)
        let content = try #require(result.content.first)
        switch content {
        case .text(let text):
            #expect(text == "Missing required string argument: list_id")
        default:
            Issue.record("Expected text content")
        }
    }

    @Test("create_reminder parses structured arguments")
    func createReminderParsesArguments() async throws {
        let store = MockReminderStore()
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let args: [String: Value] = [
            "title": "Buy milk",
            "notes": "2% preferred",
            "priority": 5,
            "url": "https://example.com",
            "due_date": [
                "date": "2026-03-10T12:00:00Z",
                "all_day": false,
                "time_zone": "UTC",
            ],
            "recurrence": [
                "frequency": "weekly",
                "interval": 2,
                "days_of_week": ["monday", "wednesday"],
            ],
            "alarms": [
                [
                    "relative_offset": -3600.0
                ]
            ],
        ]

        let result = try await dispatcher.handleCall(.init(name: ToolName.createReminder, arguments: args))

        #expect(result.isError == nil)
        let requests = await store.capturedCreatedReminders()
        #expect(requests.count == 1)
        #expect(requests[0].title == "Buy milk")
        #expect(requests[0].recurrence?.frequency == .weekly)
        #expect(requests[0].alarms.count == 1)
        let content = try #require(result.content.first)
        switch content {
        case .text(let text):
            #expect(text.contains("Created reminder."))
            #expect(text.contains("- Buy milk | id:"))
            #expect(text.contains("list: Inbox | source: iCloud | incomplete"))
            #expect(text.contains("attachments are not supported in v1"))
        default:
            Issue.record("Expected text content")
        }
    }

    @Test("update_reminder supports clear flags")
    func updateReminderClearFlags() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(
                name: ToolName.updateReminder,
                arguments: [
                    "reminder_id": "reminder-1",
                    "clear_notes": true,
                    "clear_due_date": true,
                    "title": "Updated title",
                ]))

        #expect(result.isError == nil)
        let updates = await store.capturedUpdatedReminders()
        #expect(updates.count == 1)
        #expect(updates[0].1.notes == .clear)
        #expect(updates[0].1.dueDate == .clear)
        #expect(updates[0].1.title == "Updated title")
    }

    @Test("delete_reminder returns mutation payload")
    func deleteReminder() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(name: ToolName.deleteReminder, arguments: ["reminder_id": "reminder-1"]))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        switch content {
        case .text(let text):
            #expect(text.contains("Deleted reminder."))
            #expect(text.contains("Deleted reminder id: reminder-1"))
        default:
            Issue.record("Expected text content")
        }
    }

    @Test("complete_reminder marks a reminder complete")
    func completeReminder() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(name: ToolName.completeReminder, arguments: ["reminder_id": "reminder-1"]))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        switch content {
        case .text(let text):
            #expect(text.contains("Completed reminder."))
            #expect(text.contains("| completed"))
        default:
            Issue.record("Expected text content")
        }
    }

    @Test("uncomplete_reminder marks a reminder incomplete")
    func uncompleteReminder() async throws {
        let store = MockReminderStore()
        await store.seedReminders([
            Reminder(
                id: "reminder-1",
                externalID: nil,
                listID: "list-1",
                listTitle: "Inbox",
                sourceTitle: "iCloud",
                title: "Buy milk",
                notes: "2% preferred",
                priority: 5,
                isCompleted: true,
                completionDate: "2026-03-10T12:00:00Z",
                startDate: nil,
                dueDate: nil,
                url: nil,
                alarms: [],
                recurrence: nil
            )
        ])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(name: ToolName.uncompleteReminder, arguments: ["reminder_id": "reminder-1"]))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        switch content {
        case .text(let text):
            #expect(text.contains("Marked reminder as incomplete."))
            #expect(text.contains("| incomplete"))
        default:
            Issue.record("Expected text content")
        }
    }

    @Test("store errors become MCP tool errors")
    func storeErrorBecomesErrorResult() async throws {
        let store = MockReminderStore()
        await store.setDeleteReminderHandler { _ in throw ToolError.reminderNotFound("missing") }
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(name: ToolName.deleteReminder, arguments: ["reminder_id": "missing"]))

        #expect(result.isError == true)
        let content = try #require(result.content.first)
        switch content {
        case .text(let text):
            #expect(text == "Reminder not found: missing")
        default:
            Issue.record("Expected text content")
        }
    }

    @Test("list_reminders forwards filters to store")
    func listRemindersQueryForwarding() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        _ = try await dispatcher.handleCall(
            .init(
                name: ToolName.listReminders,
                arguments: [
                    "list_ids": ["list-1"],
                    "search": "milk",
                    "include_completed": false,
                    "due_starting": "2026-03-10T00:00:00Z",
                    "due_ending": "2026-03-11T00:00:00Z",
                    "limit": 10,
                ]))

        let queries = await store.capturedQueries()
        #expect(queries.count == 1)
        #expect(queries[0].listIDs == ["list-1"])
        #expect(queries[0].search == "milk")
        #expect(queries[0].includeCompleted == false)
        #expect(queries[0].limit == 10)
    }
}
