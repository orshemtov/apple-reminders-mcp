import Foundation

public struct ReminderSource: Codable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let type: String
    public let listCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case type
        case listCount = "list_count"
    }
}

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

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case sourceID = "source_id"
        case sourceTitle = "source_title"
        case sourceType = "source_type"
        case colorHex = "color_hex"
        case allowsModifications = "allows_modifications"
        case isImmutable = "is_immutable"
        case isDefault = "is_default"
    }
}

public struct Reminder: Codable, Equatable, Sendable {
    public let id: String
    public let externalID: String?
    public let listID: String
    public let listTitle: String
    public let sourceID: String
    public let sourceTitle: String
    public let title: String
    public let location: String?
    public let notes: String?
    public let priority: Int?
    public let isCompleted: Bool
    public let completionDate: String?
    public let startDate: ReminderDate?
    public let dueDate: ReminderDate?
    public let url: String?
    public let alarms: [ReminderAlarm]
    public let recurrence: ReminderRecurrence?
    public let hasAlarms: Bool
    public let hasRecurrence: Bool
    public let isAllDay: Bool
    public let creationDate: String?
    public let lastModifiedDate: String?

    enum CodingKeys: String, CodingKey {
        case id
        case externalID = "external_id"
        case listID = "list_id"
        case listTitle = "list_title"
        case sourceID = "source_id"
        case sourceTitle = "source_title"
        case title
        case location
        case notes
        case priority
        case isCompleted = "is_completed"
        case completionDate = "completion_date"
        case startDate = "start_date"
        case dueDate = "due_date"
        case url
        case alarms
        case recurrence
        case hasAlarms = "has_alarms"
        case hasRecurrence = "has_recurrence"
        case isAllDay = "is_all_day"
        case creationDate = "creation_date"
        case lastModifiedDate = "last_modified_date"
    }
}

public struct ReminderDate: Codable, Equatable, Sendable {
    public let iso8601: String
    public let allDay: Bool
    public let timeZone: String?

    enum CodingKeys: String, CodingKey {
        case iso8601
        case allDay = "all_day"
        case timeZone = "time_zone"
    }
}

public struct ReminderAlarm: Codable, Equatable, Sendable {
    public let absoluteDate: String?
    public let relativeOffset: Double?
    public let location: ReminderLocationAlarm?

    enum CodingKeys: String, CodingKey {
        case absoluteDate = "absolute_date"
        case relativeOffset = "relative_offset"
        case location
    }
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

    enum CodingKeys: String, CodingKey {
        case frequency
        case interval
        case endDate = "end_date"
        case occurrenceCount = "occurrence_count"
        case daysOfWeek = "days_of_week"
        case daysOfMonth = "days_of_month"
        case monthsOfYear = "months_of_year"
        case setPositions = "set_positions"
    }
}

public struct ToolEnvelope<T: Codable & Sendable>: Codable, Sendable {
    public let success: Bool
    public let message: String
    public let item: T?
    public let items: [T]?
    public let warnings: [String]
    public let nextCursor: String?

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case item
        case items
        case warnings
        case nextCursor = "next_cursor"
    }

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

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case reminder
        case deletedReminderID = "deleted_reminder_id"
        case warnings
    }
}

public struct ReminderListMutationResult: Codable, Equatable, Sendable {
    public let success: Bool
    public let message: String
    public let list: ReminderList?
    public let deletedListID: String?
    public let warnings: [String]

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case list
        case deletedListID = "deleted_list_id"
        case warnings
    }
}

public struct BulkReminderMutationResult: Codable, Equatable, Sendable {
    public let success: Bool
    public let message: String
    public let dryRun: Bool
    public let affectedReminders: [Reminder]
    public let targetListID: String?
    public let warnings: [String]

    enum CodingKeys: String, CodingKey {
        case success
        case message
        case dryRun = "dry_run"
        case affectedReminders = "affected_reminders"
        case targetListID = "target_list_id"
        case warnings
    }
}

public enum ReminderCompletionState: String, Codable, Equatable, Sendable {
    case all
    case incomplete
    case completed
}

public struct ReminderQuery: Equatable, Sendable {
    public var listIDs: [String]
    public var search: String?
    public var completionState: ReminderCompletionState
    public var dueStarting: Date?
    public var dueEnding: Date?
    public var completedStarting: Date?
    public var completedEnding: Date?
    public var hasDueDate: Bool?
    public var hasLocation: Bool?
    public var hasRecurrence: Bool?
    public var priorityMin: Int?
    public var priorityMax: Int?
    public var limit: Int?

    public init(
        listIDs: [String] = [],
        search: String? = nil,
        completionState: ReminderCompletionState = .all,
        dueStarting: Date? = nil,
        dueEnding: Date? = nil,
        completedStarting: Date? = nil,
        completedEnding: Date? = nil,
        hasDueDate: Bool? = nil,
        hasLocation: Bool? = nil,
        hasRecurrence: Bool? = nil,
        priorityMin: Int? = nil,
        priorityMax: Int? = nil,
        limit: Int? = nil
    ) {
        self.listIDs = listIDs
        self.search = search
        self.completionState = completionState
        self.dueStarting = dueStarting
        self.dueEnding = dueEnding
        self.completedStarting = completedStarting
        self.completedEnding = completedEnding
        self.hasDueDate = hasDueDate
        self.hasLocation = hasLocation
        self.hasRecurrence = hasRecurrence
        self.priorityMin = priorityMin
        self.priorityMax = priorityMax
        self.limit = limit
    }
}

public struct ReminderPatch: Equatable, Sendable {
    public var title: String?
    public var location: OptionalPatch<String>
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
        location: OptionalPatch<String> = .unspecified,
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
        self.location = location
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
    public let location: String?
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
        location: String? = nil,
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
        self.location = location
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
    public let colorHex: String?

    public init(title: String, sourceID: String? = nil, colorHex: String? = nil) {
        self.title = title
        self.sourceID = sourceID
        self.colorHex = colorHex
    }
}

public struct ReminderListPatch: Equatable, Sendable {
    public let title: String?
    public let colorHex: OptionalPatch<String>

    public init(title: String? = nil, colorHex: OptionalPatch<String> = .unspecified) {
        self.title = title
        self.colorHex = colorHex
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
