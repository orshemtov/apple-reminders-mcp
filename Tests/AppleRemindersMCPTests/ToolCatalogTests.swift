import MCP
import Testing

@testable import AppleRemindersMCP

struct ToolCatalogTests {
    @Test("tool catalog exposes all expected tools")
    func toolCatalogContainsExpectedNames() {
        let catalog = ToolCatalog()
        #expect(
            catalog.allTools.map(\.name) == [
                ToolName.listLists,
                ToolName.getList,
                ToolName.createList,
                ToolName.updateList,
                ToolName.deleteList,
                ToolName.listReminders,
                ToolName.getReminder,
                ToolName.createReminder,
                ToolName.updateReminder,
                ToolName.completeReminder,
                ToolName.uncompleteReminder,
                ToolName.deleteReminder,
            ])
    }

    @Test("read tools are annotated as read-only")
    func readToolsAnnotatedReadOnly() {
        let readOnlyNames = [ToolName.listLists, ToolName.getList, ToolName.listReminders, ToolName.getReminder]
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
            $0.name == ToolName.deleteList || $0.name == ToolName.deleteReminder
        }
        #expect(destructive.count == 2)
        for tool in destructive {
            #expect(tool.annotations.destructiveHint == true)
        }
    }

    @Test("completion tools are idempotent writes")
    func completionToolsAreIdempotentWrites() {
        let catalog = ToolCatalog()
        let tools = catalog.allTools.filter {
            $0.name == ToolName.completeReminder || $0.name == ToolName.uncompleteReminder
        }
        #expect(tools.count == 2)
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
