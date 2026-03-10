import Foundation
import Logging
import MCP
import Testing

@testable import AppleRemindersMCP

struct ToolDispatcherTests {
    @Test("list_sources returns reminder sources")
    func listSources() async throws {
        let store = MockReminderStore()
        await store.seedSources([ReminderFixtures.source()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(.init(name: ToolName.listSources))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        if case .text(let text) = content {
            #expect(text.contains("Listed 1 reminder sources."))
            #expect(text.contains("- iCloud | id: source-1 | type: caldav | lists: 1"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("get_default_list returns the default list")
    func getDefaultList() async throws {
        let store = MockReminderStore()
        await store.seedLists([ReminderFixtures.list()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(.init(name: ToolName.getDefaultList))

        #expect(result.isError == nil)
    }

    @Test("list_lists returns structured list payload")
    func listLists() async throws {
        let store = MockReminderStore()
        await store.seedLists([ReminderFixtures.list()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(.init(name: ToolName.listLists))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        if case .text(let text) = content {
            #expect(text.contains("Listed 1 reminder lists."))
            #expect(text.contains("- Inbox | id: list-1"))
            #expect(text.contains("color: none"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("update_list clears color when requested")
    func updateListClearsColor() async throws {
        let store = MockReminderStore()
        await store.seedLists([ReminderFixtures.list(colorHex: "#FF0000")])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(
                name: ToolName.updateList,
                arguments: [
                    "list_id": "list-1",
                    "clear_color": true,
                ]))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        if case .text(let text) = content {
            #expect(text.contains("Updated reminder list."))
            #expect(text.contains("color: none"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("create_list forwards color hex")
    func createListForwardsColorHex() async throws {
        let store = MockReminderStore()
        await store.seedLists([ReminderFixtures.list()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(
                name: ToolName.createList,
                arguments: [
                    "title": "Errands",
                    "color_hex": "#00FF00",
                ]))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        if case .text(let text) = content {
            #expect(text.contains("Created reminder list."))
            #expect(text.contains("color: #00FF00"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("get_list returns error for missing id")
    func getListMissingArgument() async throws {
        let dispatcher = ToolDispatcher(
            toolCatalog: ToolCatalog(), reminderStore: MockReminderStore(), logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(.init(name: ToolName.getList))

        #expect(result.isError == true)
        let content = try #require(result.content.first)
        if case .text(let text) = content {
            #expect(text == "Missing required string argument: list_id")
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("create_reminder parses structured arguments including location")
    func createReminderParsesArguments() async throws {
        let store = MockReminderStore()
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let args: [String: Value] = [
            "title": "Buy milk",
            "location": "Home",
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
            "alarms": [["relative_offset": -3600.0]],
        ]

        let result = try await dispatcher.handleCall(.init(name: ToolName.createReminder, arguments: args))

        #expect(result.isError == nil)
        let requests = await store.capturedCreatedReminders()
        #expect(requests.count == 1)
        #expect(requests[0].location == "Home")
        #expect(requests[0].recurrence?.frequency == .weekly)
        let content = try #require(result.content.first)
        if case .text(let text) = content {
            #expect(text.contains("Created reminder."))
            #expect(text.contains("attachments are not supported in v1"))
        } else {
            Issue.record("Expected text content")
        }
    }

    @Test("update_reminder supports clear flags and location")
    func updateReminderClearFlags() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder(location: "Home")])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(
                name: ToolName.updateReminder,
                arguments: [
                    "reminder_id": "reminder-1",
                    "clear_notes": true,
                    "clear_due_date": true,
                    "clear_location": true,
                    "title": "Updated title",
                ]))

        #expect(result.isError == nil)
        let updates = await store.capturedUpdatedReminders()
        #expect(updates.count == 1)
        #expect(updates[0].1.notes == .clear)
        #expect(updates[0].1.dueDate == .clear)
        #expect(updates[0].1.location == .clear)
    }

    @Test("delete_reminder returns mutation payload")
    func deleteReminder() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(name: ToolName.deleteReminder, arguments: ["reminder_id": "reminder-1"]))

        #expect(result.isError == nil)
    }

    @Test("complete_reminder marks a reminder complete")
    func completeReminder() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(name: ToolName.completeReminder, arguments: ["reminder_id": "reminder-1"]))

        #expect(result.isError == nil)
    }

    @Test("uncomplete_reminder marks a reminder incomplete")
    func uncompleteReminder() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder(isCompleted: true)])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(name: ToolName.uncompleteReminder, arguments: ["reminder_id": "reminder-1"]))

        #expect(result.isError == nil)
    }

    @Test("bulk_move_reminders returns target list id")
    func bulkMoveReminders() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder()])
        let dispatcher = ToolDispatcher(toolCatalog: ToolCatalog(), reminderStore: store, logger: Logger(label: "test"))

        let result = try await dispatcher.handleCall(
            .init(
                name: ToolName.bulkMoveReminders,
                arguments: [
                    "reminder_ids": ["reminder-1"],
                    "target_list_id": "list-2",
                    "dry_run": true,
                ]))

        #expect(result.isError == nil)
        let content = try #require(result.content.first)
        if case .text(let text) = content {
            #expect(text.contains("Previewed bulk move operation."))
            #expect(text.contains("Target list id: list-2"))
        } else {
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
    }

    @Test("list_reminders forwards filters to store")
    func listRemindersQueryForwarding() async throws {
        let store = MockReminderStore()
        await store.seedReminders([ReminderFixtures.reminder(location: "Home")])
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
                    "has_location": true,
                    "priority_min": 1,
                    "limit": 10,
                ]))

        let queries = await store.capturedQueries()
        #expect(queries.count == 1)
        #expect(queries[0].completionState == .incomplete)
        #expect(queries[0].hasLocation == true)
        #expect(queries[0].priorityMin == 1)
    }
}
