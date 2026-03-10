import AppleRemindersMCP
import Foundation
import Logging
import MCP

@main
struct Main {
    static func main() async throws {
        LoggingSupport.bootstrap()
        let logger = LoggingSupport.makeLogger()
        let app = AppleRemindersServer(dependencies: .live(), logger: logger)
        let transport = StdioTransport(logger: logger)

        try await app.start(transport: transport)

        while !Task.isCancelled {
            try await Task.sleep(for: .seconds(3600))
        }
    }
}
