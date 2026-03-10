import Foundation

public struct ReminderList: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let sourceID: String
    public let sourceTitle: String
    public let sourceType: String
    public let colorHex: String?
    public let allowsModifications: Bool
    public let isImmutable: Bool
    public let isDefault: Bool
}

public struct Reminder: Codable, Equatable, Sendable {
    public let id: String
    public let externalID: String?
    public let listID: String
    public let listTitle: String
    public let sourceTitle: String
    public let title: String
    public let notes: String?
    public let priority: Int?
    public let isCompleted: Bool
    public let completionDate: String?
    public let startDate: ReminderDate?
    public let dueDate: ReminderDate?
    public let url: String?
    public let alarms: [ReminderAlarm]
    public let recurrence: ReminderRecurrence?
}

public struct ReminderDate: Codable, Equatable, Sendable {
    public let iso8601: String
    public let allDay: Bool
    public let timeZone: String?
}

public struct ReminderAlarm: Codable, Equatable, Sendable {
    public let absoluteDate: String?
    public let relativeOffset: Double?
    public let location: ReminderLocationAlarm?
}

public struct ReminderLocationAlarm: Codable, Equatable, Sendable {
    public let title: String?
    public let radius: Double?
    public let latitude: Double
    public let longitude: Double
    public let proximity: String?
}

public struct ReminderRecurrence: Codable, Equatable, Sendable {
    public let frequency: String
    public let interval: Int
    public let endDate: String?
    public let occurrenceCount: Int?
    public let daysOfWeek: [String]?
    public let daysOfMonth: [Int]?
    public let monthsOfYear: [Int]?
    public let setPositions: [Int]?
}

public struct ToolEnvelope<T: Codable & Sendable>: Codable, Sendable {
    public let success: Bool
    public let message: String
    public let item: T?
    public let items: [T]?
    public let warnings: [String]
    public let nextCursor: String?

    public init(
        success: Bool = true,
        message: String,
        item: T? = nil,
        items: [T]? = nil,
        warnings: [String] = [],
        nextCursor: String? = nil
    ) {
        self.success = success
        self.message = message
        self.item = item
        self.items = items
        self.warnings = warnings
        self.nextCursor = nextCursor
    }
}

public struct ReminderMutationResult: Codable, Equatable, Sendable {
    public let success: Bool
    public let message: String
    public let reminder: Reminder?
    public let deletedReminderID: String?
    public let warnings: [String]
}

public struct ReminderListMutationResult: Codable, Equatable, Sendable {
    public let success: Bool
    public let message: String
    public let list: ReminderList?
    public let deletedListID: String?
    public let warnings: [String]
}

public struct ReminderQuery: Equatable, Sendable {
    public var listIDs: [String]
    public var search: String?
    public var includeCompleted: Bool
    public var dueStarting: Date?
    public var dueEnding: Date?
    public var limit: Int?

    public init(
        listIDs: [String] = [],
        search: String? = nil,
        includeCompleted: Bool = true,
        dueStarting: Date? = nil,
        dueEnding: Date? = nil,
        limit: Int? = nil
    ) {
        self.listIDs = listIDs
        self.search = search
        self.includeCompleted = includeCompleted
        self.dueStarting = dueStarting
        self.dueEnding = dueEnding
        self.limit = limit
    }
}

public struct ReminderPatch: Equatable, Sendable {
    public var title: String?
    public var notes: OptionalPatch<String>
    public var priority: OptionalPatch<Int>
    public var startDate: OptionalPatch<ReminderDatePatch>
    public var dueDate: OptionalPatch<ReminderDatePatch>
    public var url: OptionalPatch<URL>
    public var isCompleted: Bool?
    public var completionDate: OptionalPatch<Date>
    public var recurrence: OptionalPatch<ReminderRecurrencePatch>
    public var alarms: OptionalPatch<[ReminderAlarmPatch]>
    public var listID: String?

    public init(
        title: String? = nil,
        notes: OptionalPatch<String> = .unspecified,
        priority: OptionalPatch<Int> = .unspecified,
        startDate: OptionalPatch<ReminderDatePatch> = .unspecified,
        dueDate: OptionalPatch<ReminderDatePatch> = .unspecified,
        url: OptionalPatch<URL> = .unspecified,
        isCompleted: Bool? = nil,
        completionDate: OptionalPatch<Date> = .unspecified,
        recurrence: OptionalPatch<ReminderRecurrencePatch> = .unspecified,
        alarms: OptionalPatch<[ReminderAlarmPatch]> = .unspecified,
        listID: String? = nil
    ) {
        self.title = title
        self.notes = notes
        self.priority = priority
        self.startDate = startDate
        self.dueDate = dueDate
        self.url = url
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.recurrence = recurrence
        self.alarms = alarms
        self.listID = listID
    }
}

public struct ReminderCreateRequest: Equatable, Sendable {
    public let listID: String?
    public let title: String
    public let notes: String?
    public let priority: Int?
    public let startDate: ReminderDatePatch?
    public let dueDate: ReminderDatePatch?
    public let url: URL?
    public let isCompleted: Bool
    public let completionDate: Date?
    public let recurrence: ReminderRecurrencePatch?
    public let alarms: [ReminderAlarmPatch]

    public init(
        listID: String? = nil,
        title: String,
        notes: String? = nil,
        priority: Int? = nil,
        startDate: ReminderDatePatch? = nil,
        dueDate: ReminderDatePatch? = nil,
        url: URL? = nil,
        isCompleted: Bool = false,
        completionDate: Date? = nil,
        recurrence: ReminderRecurrencePatch? = nil,
        alarms: [ReminderAlarmPatch] = []
    ) {
        self.listID = listID
        self.title = title
        self.notes = notes
        self.priority = priority
        self.startDate = startDate
        self.dueDate = dueDate
        self.url = url
        self.isCompleted = isCompleted
        self.completionDate = completionDate
        self.recurrence = recurrence
        self.alarms = alarms
    }
}

public struct ReminderListCreateRequest: Equatable, Sendable {
    public let title: String
    public let sourceID: String?

    public init(title: String, sourceID: String? = nil) {
        self.title = title
        self.sourceID = sourceID
    }
}

public struct ReminderListPatch: Equatable, Sendable {
    public let title: String?

    public init(title: String? = nil) {
        self.title = title
    }
}

public struct ReminderDatePatch: Equatable, Sendable {
    public let date: Date
    public let allDay: Bool
    public let timeZoneID: String?

    public init(date: Date, allDay: Bool, timeZoneID: String? = nil) {
        self.date = date
        self.allDay = allDay
        self.timeZoneID = timeZoneID
    }
}

public struct ReminderAlarmPatch: Equatable, Sendable {
    public let absoluteDate: Date?
    public let relativeOffset: TimeInterval?
    public let location: ReminderLocationAlarmPatch?

    public init(
        absoluteDate: Date? = nil,
        relativeOffset: TimeInterval? = nil,
        location: ReminderLocationAlarmPatch? = nil
    ) {
        self.absoluteDate = absoluteDate
        self.relativeOffset = relativeOffset
        self.location = location
    }
}

public struct ReminderLocationAlarmPatch: Equatable, Sendable {
    public let title: String?
    public let radius: Double?
    public let latitude: Double
    public let longitude: Double
    public let proximity: ReminderProximity?

    public init(
        title: String? = nil,
        radius: Double? = nil,
        latitude: Double,
        longitude: Double,
        proximity: ReminderProximity? = nil
    ) {
        self.title = title
        self.radius = radius
        self.latitude = latitude
        self.longitude = longitude
        self.proximity = proximity
    }
}

public enum ReminderProximity: String, Codable, Equatable, Sendable {
    case enter
    case leave
}

public struct ReminderRecurrencePatch: Equatable, Sendable {
    public let frequency: ReminderFrequency
    public let interval: Int
    public let endDate: Date?
    public let occurrenceCount: Int?
    public let daysOfWeek: [ReminderWeekday]
    public let daysOfMonth: [Int]
    public let monthsOfYear: [Int]
    public let setPositions: [Int]

    public init(
        frequency: ReminderFrequency,
        interval: Int = 1,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil,
        daysOfWeek: [ReminderWeekday] = [],
        daysOfMonth: [Int] = [],
        monthsOfYear: [Int] = [],
        setPositions: [Int] = []
    ) {
        self.frequency = frequency
        self.interval = interval
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
        self.daysOfWeek = daysOfWeek
        self.daysOfMonth = daysOfMonth
        self.monthsOfYear = monthsOfYear
        self.setPositions = setPositions
    }
}

public enum ReminderFrequency: String, Codable, Equatable, Sendable {
    case daily
    case weekly
    case monthly
    case yearly
}

public enum ReminderWeekday: String, Codable, CaseIterable, Equatable, Sendable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
}

public enum OptionalPatch<Value: Equatable & Sendable>: Equatable, Sendable {
    case unspecified
    case set(Value)
    case clear
}
