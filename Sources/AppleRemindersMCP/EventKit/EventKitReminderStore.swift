import CoreLocation
@preconcurrency import EventKit
import Foundation

public actor EventKitReminderStore: ReminderStoreProtocol {
    private let eventStore: EKEventStore

    public init(eventStore: EKEventStore = EKEventStore()) {
        self.eventStore = eventStore
    }

    public func ensureAccess() async throws {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess, .writeOnly:
            return
        case .denied, .restricted:
            throw ToolError.permissionDenied
        case .notDetermined:
            let granted = try await requestReminderAccess()
            guard granted else {
                throw ToolError.permissionDenied
            }
        @unknown default:
            throw ToolError.permissionDenied
        }
    }

    public func lists() async throws -> [ReminderList] {
        try await ensureAccess()
        let defaultID = eventStore.defaultCalendarForNewReminders()?.calendarIdentifier
        return eventStore.calendars(for: .reminder)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { Self.makeReminderList(from: $0, defaultID: defaultID) }
    }

    public func list(id: String) async throws -> ReminderList {
        try await ensureAccess()
        let calendar = try reminderCalendar(id: id)
        return Self.makeReminderList(
            from: calendar,
            defaultID: eventStore.defaultCalendarForNewReminders()?.calendarIdentifier
        )
    }

    public func createList(_ request: ReminderListCreateRequest) async throws -> ReminderList {
        try await ensureAccess()
        let source = try sourceForNewList(sourceID: request.sourceID)
        let calendar = EKCalendar(for: .reminder, eventStore: eventStore)
        calendar.title = request.title
        calendar.source = source
        do {
            try eventStore.saveCalendar(calendar, commit: true)
        } catch {
            throw ToolError.eventKit(error.localizedDescription)
        }
        return try await list(id: calendar.calendarIdentifier)
    }

    public func updateList(id: String, patch: ReminderListPatch) async throws -> ReminderList {
        try await ensureAccess()
        let calendar = try reminderCalendar(id: id)
        try ensureWritable(calendar: calendar)
        if let title = patch.title {
            calendar.title = title
        }
        do {
            try eventStore.saveCalendar(calendar, commit: true)
        } catch {
            throw ToolError.eventKit(error.localizedDescription)
        }
        return try await list(id: id)
    }

    public func deleteList(id: String) async throws {
        try await ensureAccess()
        let calendar = try reminderCalendar(id: id)
        try ensureWritable(calendar: calendar)
        do {
            try eventStore.removeCalendar(calendar, commit: true)
        } catch {
            throw ToolError.eventKit(error.localizedDescription)
        }
    }

    public func reminders(query: ReminderQuery) async throws -> [Reminder] {
        try await ensureAccess()
        let calendars = try calendarsForIDs(query.listIDs)
        return try await fetchReminderModels(query: query, calendars: calendars)
    }

    public func reminder(id: String) async throws -> Reminder {
        try await ensureAccess()
        guard let item = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ToolError.reminderNotFound(id)
        }
        return Self.makeReminder(from: item)
    }

    public func createReminder(_ request: ReminderCreateRequest) async throws -> Reminder {
        try await ensureAccess()
        let reminder = EKReminder(eventStore: eventStore)
        reminder.calendar = try calendarForNewReminder(listID: request.listID)
        try ensureWritable(calendar: reminder.calendar)
        try applyCreateRequest(request, to: reminder)

        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            throw ToolError.eventKit(error.localizedDescription)
        }
        return Self.makeReminder(from: reminder)
    }

    public func updateReminder(id: String, patch: ReminderPatch) async throws -> Reminder {
        try await ensureAccess()
        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ToolError.reminderNotFound(id)
        }
        if let listID = patch.listID {
            reminder.calendar = try reminderCalendar(id: listID)
        }
        try ensureWritable(calendar: reminder.calendar)
        try applyPatch(patch, to: reminder)

        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            throw ToolError.eventKit(error.localizedDescription)
        }
        return Self.makeReminder(from: reminder)
    }

    public func completeReminder(id: String) async throws -> Reminder {
        try await ensureAccess()
        return try await setCompletionState(forReminderID: id, isCompleted: true)
    }

    public func uncompleteReminder(id: String) async throws -> Reminder {
        try await ensureAccess()
        return try await setCompletionState(forReminderID: id, isCompleted: false)
    }

    public func deleteReminder(id: String) async throws {
        try await ensureAccess()
        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ToolError.reminderNotFound(id)
        }
        try ensureWritable(calendar: reminder.calendar)
        do {
            try eventStore.remove(reminder, commit: true)
        } catch {
            throw ToolError.eventKit(error.localizedDescription)
        }
    }

    private func calendarsForIDs(_ ids: [String]) throws -> [EKCalendar]? {
        if ids.isEmpty {
            return nil
        }
        return try ids.map(reminderCalendar(id:))
    }

    private func fetchReminderModels(query: ReminderQuery, calendars: [EKCalendar]?) async throws -> [Reminder] {
        let predicate: NSPredicate
        if query.includeCompleted {
            predicate = eventStore.predicateForReminders(in: calendars)
        } else {
            predicate = eventStore.predicateForIncompleteReminders(
                withDueDateStarting: query.dueStarting,
                ending: query.dueEnding,
                calendars: calendars
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            _ = eventStore.fetchReminders(matching: predicate) { reminders in
                let filtered = (reminders ?? [])
                    .filter { reminder in
                        if !query.includeCompleted && reminder.isCompleted {
                            return false
                        }
                        if let search = query.search?.trimmingCharacters(in: .whitespacesAndNewlines), !search.isEmpty {
                            let haystack = [reminder.title, reminder.notes ?? ""].joined(separator: "\n")
                            if haystack.localizedCaseInsensitiveContains(search) == false {
                                return false
                            }
                        }
                        if query.includeCompleted, let dueStarting = query.dueStarting,
                            let dueDate = reminder.dueDateComponents?.date, dueDate < dueStarting
                        {
                            return false
                        }
                        if let dueEnding = query.dueEnding,
                            let dueDate = reminder.dueDateComponents?.date, dueDate > dueEnding
                        {
                            return false
                        }
                        return true
                    }
                    .sorted { lhs, rhs in
                        switch (lhs.dueDateComponents?.date, rhs.dueDateComponents?.date) {
                        case (let l?, let r?):
                            return l < r
                        case (_?, nil):
                            return true
                        case (nil, _?):
                            return false
                        case (nil, nil):
                            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                        }
                    }

                let limited = query.limit.map { Array(filtered.prefix($0)) } ?? filtered
                continuation.resume(returning: limited.map(Self.makeReminder(from:)))
            }
        }
    }

    private func requestReminderAccess() async throws -> Bool {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Bool, Error>) in
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToReminders { granted, error in
                    if let error {
                        continuation.resume(throwing: ToolError.eventKit(error.localizedDescription))
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            } else {
                eventStore.requestAccess(to: .reminder) { granted, error in
                    if let error {
                        continuation.resume(throwing: ToolError.eventKit(error.localizedDescription))
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    private func reminderCalendar(id: String) throws -> EKCalendar {
        guard let calendar = eventStore.calendar(withIdentifier: id) else {
            throw ToolError.listNotFound(id)
        }
        return calendar
    }

    private func calendarForNewReminder(listID: String?) throws -> EKCalendar {
        if let listID {
            return try reminderCalendar(id: listID)
        }
        guard let calendar = eventStore.defaultCalendarForNewReminders() else {
            throw ToolError.noDefaultList
        }
        return calendar
    }

    private func sourceForNewList(sourceID: String?) throws -> EKSource {
        if let sourceID {
            guard let source = eventStore.sources.first(where: { $0.sourceIdentifier == sourceID }) else {
                throw ToolError.invalidArguments("Reminder source not found: \(sourceID)")
            }
            return source
        }

        if let defaultSource = eventStore.defaultCalendarForNewReminders()?.source {
            return defaultSource
        }
        if let localSource = eventStore.sources.first(where: { $0.sourceType == .local }) {
            return localSource
        }
        guard let first = eventStore.sources.first else {
            throw ToolError.invalidArguments("No reminder source is available for creating a new list.")
        }
        return first
    }

    private func ensureWritable(calendar: EKCalendar) throws {
        guard calendar.allowsContentModifications, calendar.isImmutable == false else {
            throw ToolError.listNotWritable(calendar.calendarIdentifier)
        }
    }

    private func applyCreateRequest(_ request: ReminderCreateRequest, to reminder: EKReminder) throws {
        reminder.title = request.title
        reminder.notes = request.notes
        reminder.priority = request.priority ?? 0
        reminder.url = request.url
        reminder.startDateComponents = request.startDate.map(Self.dateComponents)
        reminder.dueDateComponents = request.dueDate.map(Self.dateComponents)
        reminder.alarms = try request.alarms.map(Self.makeAlarm)
        reminder.recurrenceRules = try request.recurrence.map { [try Self.makeRecurrenceRule(from: $0)] }
        reminder.isCompleted = request.isCompleted
        reminder.completionDate = request.completionDate
    }

    private func applyPatch(_ patch: ReminderPatch, to reminder: EKReminder) throws {
        if let title = patch.title {
            reminder.title = title
        }
        if case .set(let notes) = patch.notes {
            reminder.notes = notes
        } else if case .clear = patch.notes {
            reminder.notes = nil
        }
        if case .set(let priority) = patch.priority {
            reminder.priority = priority
        } else if case .clear = patch.priority {
            reminder.priority = 0
        }
        patch.startDate.apply { value in
            reminder.startDateComponents = Self.dateComponents(value)
        } clear: {
            reminder.startDateComponents = nil
        }
        patch.dueDate.apply { value in
            reminder.dueDateComponents = Self.dateComponents(value)
        } clear: {
            reminder.dueDateComponents = nil
        }
        switch patch.url {
        case .set(let url):
            reminder.url = url
        case .clear:
            reminder.url = nil
        case .unspecified:
            break
        }
        if let isCompleted = patch.isCompleted {
            reminder.isCompleted = isCompleted
            if isCompleted == false, case .unspecified = patch.completionDate {
                reminder.completionDate = nil
            }
        }
        switch patch.completionDate {
        case .set(let date):
            reminder.completionDate = date
        case .clear:
            reminder.completionDate = nil
        case .unspecified:
            break
        }
        switch patch.recurrence {
        case .set(let recurrence):
            reminder.recurrenceRules = [try Self.makeRecurrenceRule(from: recurrence)]
        case .clear:
            reminder.recurrenceRules = nil
        case .unspecified:
            break
        }
        switch patch.alarms {
        case .set(let alarms):
            reminder.alarms = try alarms.map(Self.makeAlarm)
        case .clear:
            reminder.alarms = nil
        case .unspecified:
            break
        }
    }

    private func setCompletionState(forReminderID id: String, isCompleted: Bool) async throws -> Reminder {
        guard let reminder = eventStore.calendarItem(withIdentifier: id) as? EKReminder else {
            throw ToolError.reminderNotFound(id)
        }
        try ensureWritable(calendar: reminder.calendar)
        reminder.isCompleted = isCompleted
        reminder.completionDate = isCompleted ? Date() : nil
        do {
            try eventStore.save(reminder, commit: true)
        } catch {
            throw ToolError.eventKit(error.localizedDescription)
        }
        return Self.makeReminder(from: reminder)
    }

    private static func makeReminderList(from calendar: EKCalendar, defaultID: String?) -> ReminderList {
        ReminderList(
            id: calendar.calendarIdentifier,
            title: calendar.title,
            sourceID: calendar.source.sourceIdentifier,
            sourceTitle: calendar.source.title,
            sourceType: sourceTypeString(calendar.source.sourceType),
            colorHex: ColorFormatting.normalizedHexString(from: String(describing: calendar.cgColor)),
            allowsModifications: calendar.allowsContentModifications,
            isImmutable: calendar.isImmutable,
            isDefault: calendar.calendarIdentifier == defaultID
        )
    }

    private static func makeReminder(from reminder: EKReminder) -> Reminder {
        Reminder(
            id: reminder.calendarItemIdentifier,
            externalID: reminder.calendarItemExternalIdentifier,
            listID: reminder.calendar.calendarIdentifier,
            listTitle: reminder.calendar.title,
            sourceTitle: reminder.calendar.source.title,
            title: reminder.title,
            notes: reminder.notes,
            priority: reminder.priority == 0 ? nil : reminder.priority,
            isCompleted: reminder.isCompleted,
            completionDate: reminder.completionDate.map(DateFormatting.string),
            startDate: reminder.startDateComponents.map(Self.makeReminderDate),
            dueDate: reminder.dueDateComponents.map(Self.makeReminderDate),
            url: reminder.url?.absoluteString,
            alarms: (reminder.alarms ?? []).map(Self.makeReminderAlarm),
            recurrence: reminder.recurrenceRules?.first.map(Self.makeReminderRecurrence)
        )
    }

    private static func makeReminderDate(_ components: DateComponents) -> ReminderDate {
        let date = components.date ?? Date(timeIntervalSince1970: 0)
        let allDay = components.hour == nil && components.minute == nil && components.second == nil
        return ReminderDate(
            iso8601: DateFormatting.string(from: date),
            allDay: allDay,
            timeZone: components.timeZone?.identifier
        )
    }

    private static func makeReminderAlarm(_ alarm: EKAlarm) -> ReminderAlarm {
        ReminderAlarm(
            absoluteDate: alarm.absoluteDate.map(DateFormatting.string),
            relativeOffset: alarm.relativeOffset == 0 && alarm.absoluteDate == nil ? nil : alarm.relativeOffset,
            location: alarm.structuredLocation.map {
                ReminderLocationAlarm(
                    title: $0.title,
                    radius: $0.radius,
                    latitude: $0.geoLocation?.coordinate.latitude ?? 0,
                    longitude: $0.geoLocation?.coordinate.longitude ?? 0,
                    proximity: proximityString(alarm.proximity)
                )
            }
        )
    }

    private static func makeReminderRecurrence(_ recurrence: EKRecurrenceRule) -> ReminderRecurrence {
        ReminderRecurrence(
            frequency: frequencyString(recurrence.frequency),
            interval: recurrence.interval,
            endDate: recurrence.recurrenceEnd?.endDate.map(DateFormatting.string),
            occurrenceCount: recurrence.recurrenceEnd?.occurrenceCount,
            daysOfWeek: recurrence.daysOfTheWeek?.map { weekdayString($0.dayOfTheWeek) },
            daysOfMonth: recurrence.daysOfTheMonth?.map(\.intValue),
            monthsOfYear: recurrence.monthsOfTheYear?.map(\.intValue),
            setPositions: recurrence.setPositions?.map(\.intValue)
        )
    }

    private static func dateComponents(_ patch: ReminderDatePatch) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = patch.timeZoneID.flatMap(TimeZone.init(identifier:)) ?? .current

        var components: Set<Calendar.Component> = [.year, .month, .day]
        if patch.allDay == false {
            components.formUnion([.hour, .minute, .second])
        }
        var dateComponents = calendar.dateComponents(components, from: patch.date)
        dateComponents.calendar = calendar
        dateComponents.timeZone = patch.timeZoneID.flatMap(TimeZone.init(identifier:))
        if patch.allDay {
            dateComponents.hour = nil
            dateComponents.minute = nil
            dateComponents.second = nil
        }
        return dateComponents
    }

    private static func makeAlarm(_ patch: ReminderAlarmPatch) throws -> EKAlarm {
        let alarm: EKAlarm
        if let absoluteDate = patch.absoluteDate {
            alarm = EKAlarm(absoluteDate: absoluteDate)
        } else {
            alarm = EKAlarm(relativeOffset: patch.relativeOffset ?? 0)
        }

        if let location = patch.location {
            let structuredLocation = EKStructuredLocation(title: location.title ?? "Location reminder")
            structuredLocation.geoLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
            if let radius = location.radius {
                structuredLocation.radius = radius
            }
            alarm.structuredLocation = structuredLocation
            if let proximity = location.proximity {
                alarm.proximity = proximity == .enter ? .enter : .leave
            }
        }
        return alarm
    }

    private static func makeRecurrenceRule(from recurrence: ReminderRecurrencePatch) throws -> EKRecurrenceRule {
        guard recurrence.interval > 0 else {
            throw ToolError.invalidArguments("recurrence.interval must be greater than 0")
        }
        let end: EKRecurrenceEnd?
        if let occurrenceCount = recurrence.occurrenceCount {
            end = EKRecurrenceEnd(occurrenceCount: occurrenceCount)
        } else if let endDate = recurrence.endDate {
            end = EKRecurrenceEnd(end: endDate)
        } else {
            end = nil
        }
        return EKRecurrenceRule(
            recurrenceWith: frequency(from: recurrence.frequency),
            interval: recurrence.interval,
            daysOfTheWeek: recurrence.daysOfWeek.isEmpty ? nil : recurrence.daysOfWeek.map(Self.dayOfWeek),
            daysOfTheMonth: recurrence.daysOfMonth.isEmpty ? nil : recurrence.daysOfMonth.map(NSNumber.init(value:)),
            monthsOfTheYear: recurrence.monthsOfYear.isEmpty ? nil : recurrence.monthsOfYear.map(NSNumber.init(value:)),
            weeksOfTheYear: nil,
            daysOfTheYear: nil,
            setPositions: recurrence.setPositions.isEmpty ? nil : recurrence.setPositions.map(NSNumber.init(value:)),
            end: end
        )
    }

    private static func dayOfWeek(_ weekday: ReminderWeekday) -> EKRecurrenceDayOfWeek {
        switch weekday {
        case .sunday:
            return EKRecurrenceDayOfWeek(.sunday)
        case .monday:
            return EKRecurrenceDayOfWeek(.monday)
        case .tuesday:
            return EKRecurrenceDayOfWeek(.tuesday)
        case .wednesday:
            return EKRecurrenceDayOfWeek(.wednesday)
        case .thursday:
            return EKRecurrenceDayOfWeek(.thursday)
        case .friday:
            return EKRecurrenceDayOfWeek(.friday)
        case .saturday:
            return EKRecurrenceDayOfWeek(.saturday)
        }
    }

    private static func frequency(from frequency: ReminderFrequency) -> EKRecurrenceFrequency {
        switch frequency {
        case .daily:
            return .daily
        case .weekly:
            return .weekly
        case .monthly:
            return .monthly
        case .yearly:
            return .yearly
        }
    }

    private static func frequencyString(_ frequency: EKRecurrenceFrequency) -> String {
        switch frequency {
        case .daily:
            return ReminderFrequency.daily.rawValue
        case .weekly:
            return ReminderFrequency.weekly.rawValue
        case .monthly:
            return ReminderFrequency.monthly.rawValue
        case .yearly:
            return ReminderFrequency.yearly.rawValue
        @unknown default:
            return "unknown"
        }
    }

    private static func weekdayString(_ day: EKWeekday) -> String {
        switch day {
        case .sunday:
            return ReminderWeekday.sunday.rawValue
        case .monday:
            return ReminderWeekday.monday.rawValue
        case .tuesday:
            return ReminderWeekday.tuesday.rawValue
        case .wednesday:
            return ReminderWeekday.wednesday.rawValue
        case .thursday:
            return ReminderWeekday.thursday.rawValue
        case .friday:
            return ReminderWeekday.friday.rawValue
        case .saturday:
            return ReminderWeekday.saturday.rawValue
        @unknown default:
            return "unknown"
        }
    }

    private static func proximityString(_ proximity: EKAlarmProximity) -> String? {
        switch proximity {
        case .enter:
            return ReminderProximity.enter.rawValue
        case .leave:
            return ReminderProximity.leave.rawValue
        case .none:
            return nil
        @unknown default:
            return nil
        }
    }

    private static func sourceTypeString(_ sourceType: EKSourceType) -> String {
        switch sourceType {
        case .local:
            return "local"
        case .exchange:
            return "exchange"
        case .calDAV:
            return "caldav"
        case .mobileMe:
            return "mobileme"
        case .subscribed:
            return "subscribed"
        case .birthdays:
            return "birthdays"
        @unknown default:
            return "unknown"
        }
    }
}

extension OptionalPatch {
    fileprivate func apply(set: (Value) throws -> Void, clear: () throws -> Void) rethrows {
        switch self {
        case .set(let value):
            try set(value)
        case .clear:
            try clear()
        case .unspecified:
            break
        }
    }
}
