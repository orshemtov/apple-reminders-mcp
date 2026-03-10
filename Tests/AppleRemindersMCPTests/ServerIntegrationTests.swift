import Foundation
import Logging
import MCP
import Testing

@testable import AppleRemindersMCP

#if canImport(System)
    import System
#else
    @preconcurrency import SystemPackage
#endif

struct ServerIntegrationTests {
    @Test("server exposes tools over stdio transport", .timeLimit(.minutes(1)))
    func serverRoundtrip() async throws {
        let (clientToServerRead, clientToServerWrite) = try FileDescriptor.pipe()
        let (serverToClientRead, serverToClientWrite) = try FileDescriptor.pipe()

        var logger = Logger(label: "apple-reminders-mcp.test")
        logger.logLevel = .debug

        let serverTransport = StdioTransport(input: clientToServerRead, output: serverToClientWrite, logger: logger)
        let clientTransport = StdioTransport(input: serverToClientRead, output: clientToServerWrite, logger: logger)

        let store = MockReminderStore()
        await store.seedLists([ReminderFixtures.list()])

        let app = AppleRemindersServer(
            dependencies: .init(reminderStore: store),
            logger: logger
        )
        let client = Client(name: "TestClient", version: "1.0.0")

        try await app.start(transport: serverTransport)
        _ = try await client.connect(transport: clientTransport)

        let (tools, _) = try await client.listTools()
        #expect(tools.map(\.name).contains(ToolName.listLists))
        #expect(tools.map(\.name).contains(ToolName.createReminder))
        #expect(tools.map(\.name).contains(ToolName.listSources))
        #expect(tools.map(\.name).contains(ToolName.bulkMoveReminders))

        let toolResult = try await client.callTool(name: ToolName.listLists, arguments: [:])
        #expect(toolResult.isError == nil)
        let content = try #require(toolResult.content.first)
        switch content {
        case .text(let text):
            #expect(text.contains("Listed 1 reminder lists."))
            #expect(text.contains("- Inbox | id: list-1"))
        default:
            Issue.record("Expected text content")
        }

        await app.stop()
    }
}
