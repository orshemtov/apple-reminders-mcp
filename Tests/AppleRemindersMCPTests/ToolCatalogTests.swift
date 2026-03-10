import MCP
import Testing

@testable import AppleRemindersMCP

struct ToolCatalogTests {
    @Test("tool catalog exposes all expected tools")
    func toolCatalogContainsExpectedNames() {
        let catalog = ToolCatalog()
        #expect(
            catalog.allTools.map(\.name) == [
                ToolName.listSources,
                ToolName.getDefaultList,
                ToolName.listLists,
                ToolName.getList,
                ToolName.createList,
                ToolName.updateList,
                ToolName.deleteList,
                ToolName.listReminders,
                ToolName.listCompletedReminders,
                ToolName.listUpcomingReminders,
                ToolName.getReminder,
                ToolName.createReminder,
                ToolName.updateReminder,
                ToolName.completeReminder,
                ToolName.uncompleteReminder,
                ToolName.bulkCompleteReminders,
                ToolName.bulkDeleteReminders,
                ToolName.bulkMoveReminders,
                ToolName.deleteReminder,
            ])
    }

    @Test("read tools are annotated as read-only")
    func readToolsAnnotatedReadOnly() {
        let readOnlyNames = [
            ToolName.listSources,
            ToolName.getDefaultList,
            ToolName.listLists,
            ToolName.getList,
            ToolName.listReminders,
            ToolName.listCompletedReminders,
            ToolName.listUpcomingReminders,
            ToolName.getReminder,
        ]
        let catalog = ToolCatalog()
        for tool in catalog.allTools where readOnlyNames.contains(tool.name) {
            #expect(tool.annotations.readOnlyHint == true)
            #expect(tool.annotations.idempotentHint == true)
        }
    }

    @Test("delete tools are destructive")
    func deleteToolsAnnotatedDestructive() {
        let catalog = ToolCatalog()
        let destructive = catalog.allTools.filter {
            [ToolName.deleteList, ToolName.deleteReminder, ToolName.bulkDeleteReminders].contains($0.name)
        }
        #expect(destructive.count == 3)
        for tool in destructive {
            #expect(tool.annotations.destructiveHint == true)
        }
    }

    @Test("completion tools are idempotent writes")
    func completionToolsAreIdempotentWrites() {
        let catalog = ToolCatalog()
        let tools = catalog.allTools.filter {
            [ToolName.completeReminder, ToolName.uncompleteReminder, ToolName.bulkCompleteReminders].contains($0.name)
        }
        #expect(tools.count == 3)
        for tool in tools {
            #expect(tool.annotations.readOnlyHint == false)
            #expect(tool.annotations.idempotentHint == true)
            #expect(tool.annotations.destructiveHint == false)
        }
    }

    @Test("create reminder schema documents attachment limitation")
    func createReminderDescriptionMentionsAttachments() {
        #expect(ToolCatalog.createReminder.description?.contains("attachments") == true)
    }
}
