import Logging

public enum LoggingSupport {
    public static func bootstrap() {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = .info
            return handler
        }
    }

    public static func makeLogger(label: String = "com.or.apple-reminders-mcp") -> Logger {
        Logger(label: label)
    }
}
