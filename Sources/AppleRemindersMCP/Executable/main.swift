import AppleRemindersMCP
import Foundation
import Logging
import MCP

@main
struct Main {
    static func main() async throws {
        if let mode = StartupMode(arguments: CommandLine.arguments) {
            print(mode.output)
            return
        }

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

private enum StartupMode {
    case help
    case version

    init?(arguments: [String]) {
        let flags = Set(arguments.dropFirst())

        if flags.contains("--help") || flags.contains("-h") {
            self = .help
            return
        }

        if flags.contains("--version") {
            self = .version
            return
        }

        return nil
    }

    var output: String {
        switch self {
        case .help:
            return """
                Apple Reminders MCP

                A local MCP server for Apple Reminders on macOS.

                Usage:
                  apple-reminders-mcp
                  apple-reminders-mcp --help
                  apple-reminders-mcp --version

                Notes:
                  - The server communicates over stdio.
                  - It runs against the local macOS user's Reminders data.
                  - macOS will prompt for Reminders access on first use.
                """
        case .version:
            return BuildInfo.version
        }
    }
}
