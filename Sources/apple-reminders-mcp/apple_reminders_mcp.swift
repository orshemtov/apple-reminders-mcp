// The Swift Programming Language
// https://docs.swift.org/swift-book

import MCP

@main
struct Main {
    static func main() async throws {
        let server = Server(
            name: "Apple Reminders MCP",
            version: "1.0.0",
            capabilities: .init(
                tools: .init(listChanged: true)
            )
        )

        let transport = StdioTransport()

        try await server.start(transport: transport)
    }
}
