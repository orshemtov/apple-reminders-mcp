import Foundation
import MCP

enum ToolArgumentParser {
    static func requiredString(_ key: String, from args: [String: Value]?) throws -> String {
        guard let value = args?[key]?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty
        else {
            throw ToolError.invalidArguments("Missing required string argument: \(key)")
        }
        return value
    }

    static func optionalString(_ key: String, from args: [String: Value]?) -> String? {
        args?[key]?.stringValue
    }

    static func optionalBool(_ key: String, from args: [String: Value]?) -> Bool? {
        args?[key]?.boolValue
    }

    static func optionalInt(_ key: String, from args: [String: Value]?) -> Int? {
        args?[key]?.intValue
    }

    static func optionalDouble(_ key: String, from args: [String: Value]?) -> Double? {
        args?[key]?.doubleValue
    }

    static func optionalStringArray(_ key: String, from args: [String: Value]?) -> [String]? {
        args?[key]?.arrayValue?.compactMap(\.stringValue)
    }

    static func optionalIntArray(_ key: String, from args: [String: Value]?) -> [Int]? {
        args?[key]?.arrayValue?.compactMap(\.intValue)
    }

    static func optionalDate(_ key: String, from args: [String: Value]?) throws -> Date? {
        guard let value = args?[key]?.stringValue else { return nil }
        guard let date = DateFormatting.parse(value) else {
            throw ToolError.invalidArguments("Invalid ISO-8601 date for \(key)")
        }
        return date
    }

    static func optionalURL(_ key: String, from args: [String: Value]?) throws -> URL? {
        guard let raw = args?[key]?.stringValue else { return nil }
        guard let url = URL(string: raw) else {
            throw ToolError.invalidArguments("Invalid URL for \(key)")
        }
        return url
    }

    static func optionalObject(_ key: String, from args: [String: Value]?) -> [String: Value]? {
        args?[key]?.objectValue
    }

    static func optionalObjectArray(_ key: String, from args: [String: Value]?) -> [[String: Value]]? {
        args?[key]?.arrayValue?.compactMap(\.objectValue)
    }
}
