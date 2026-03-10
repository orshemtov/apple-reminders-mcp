import MCP

public struct ToolCatalog: Sendable {
    public let allTools: [Tool]

    public init() {
        self.allTools = [
            Self.listSources,
            Self.getDefaultList,
            Self.listLists,
            Self.getList,
            Self.createList,
            Self.updateList,
            Self.deleteList,
            Self.listReminders,
            Self.listCompletedReminders,
            Self.listUpcomingReminders,
            Self.getReminder,
            Self.createReminder,
            Self.updateReminder,
            Self.completeReminder,
            Self.uncompleteReminder,
            Self.bulkCompleteReminders,
            Self.bulkDeleteReminders,
            Self.bulkMoveReminders,
            Self.deleteReminder,
        ]
    }

    private static let listOutput = Schema.object(
        properties: [
            "success": Schema.boolean(),
            "message": Schema.string(),
            "item": Schema.object(properties: [:], additionalProperties: true),
            "items": Schema.array(items: Schema.object(properties: [:], additionalProperties: true)),
            "warnings": Schema.array(items: Schema.string()),
            "nextCursor": Schema.string(),
        ],
        additionalProperties: true
    )

    static let listSources = Tool(
        name: ToolName.listSources,
        description: "List reminder account sources available to the current macOS user.",
        inputSchema: Schema.object(properties: [:]),
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let getDefaultList = Tool(
        name: ToolName.getDefaultList,
        description: "Get the default list used for new reminders.",
        inputSchema: Schema.object(properties: [:]),
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let listLists = Tool(
        name: ToolName.listLists,
        description: "List reminder lists available to the current macOS user.",
        inputSchema: Schema.object(properties: [:]),
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let getList = Tool(
        name: ToolName.getList,
        description: "Get a reminder list by identifier.",
        inputSchema: Schema.object(
            properties: ["list_id": Schema.string(description: "Reminder list identifier")],
            required: ["list_id"]
        ),
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let createList = Tool(
        name: ToolName.createList,
        description: "Create a new reminder list in the selected reminder source.",
        inputSchema: Schema.object(
            properties: [
                "title": Schema.string(description: "New list title"),
                "source_id": Schema.string(description: "Optional source identifier for the new list"),
                "color_hex": Schema.string(description: "Optional list color as #RRGGBB or #RRGGBBAA"),
            ],
            required: ["title"]
        ),
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false),
        outputSchema: listOutput
    )

    static let updateList = Tool(
        name: ToolName.updateList,
        description: "Update an existing reminder list title or color.",
        inputSchema: Schema.object(
            properties: [
                "list_id": Schema.string(description: "Reminder list identifier"),
                "title": Schema.string(description: "Updated title for the list"),
                "color_hex": Schema.string(description: "Replacement list color as #RRGGBB or #RRGGBBAA"),
                "clear_color": Schema.boolean(description: "Remove any existing list color"),
            ],
            required: ["list_id"]
        ),
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let deleteList = Tool(
        name: ToolName.deleteList,
        description: "Delete a reminder list by identifier.",
        inputSchema: Schema.object(
            properties: ["list_id": Schema.string(description: "Reminder list identifier")],
            required: ["list_id"]
        ),
        annotations: .init(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let listReminders = Tool(
        name: ToolName.listReminders,
        description:
            "List reminders with optional list, text, completion, due, completion date, location, recurrence, and priority filters.",
        inputSchema: ReminderToolSchemas.listReminders,
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let listCompletedReminders = Tool(
        name: ToolName.listCompletedReminders,
        description: "List completed reminders, optionally filtered by completion date and list.",
        inputSchema: ReminderToolSchemas.completedReminders,
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let listUpcomingReminders = Tool(
        name: ToolName.listUpcomingReminders,
        description: "List upcoming incomplete reminders due between optional bounds.",
        inputSchema: ReminderToolSchemas.upcomingReminders,
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let getReminder = Tool(
        name: ToolName.getReminder,
        description: "Get a reminder by identifier.",
        inputSchema: Schema.object(
            properties: ["reminder_id": Schema.string(description: "Reminder identifier")],
            required: ["reminder_id"]
        ),
        annotations: .init(readOnlyHint: true, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let createReminder = Tool(
        name: ToolName.createReminder,
        description: "Create a reminder. URL is supported, but file and image attachments are not supported in v1.",
        inputSchema: ReminderToolSchemas.createReminder,
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: false, openWorldHint: false),
        outputSchema: listOutput
    )

    static let updateReminder = Tool(
        name: ToolName.updateReminder,
        description: "Update an existing reminder. Omitted fields are unchanged; clear_* flags remove values.",
        inputSchema: ReminderToolSchemas.updateReminder,
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let completeReminder = Tool(
        name: ToolName.completeReminder,
        description: "Mark a reminder as completed.",
        inputSchema: Schema.object(
            properties: ["reminder_id": Schema.string(description: "Reminder identifier")],
            required: ["reminder_id"]
        ),
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let uncompleteReminder = Tool(
        name: ToolName.uncompleteReminder,
        description: "Mark a reminder as not completed.",
        inputSchema: Schema.object(
            properties: ["reminder_id": Schema.string(description: "Reminder identifier")],
            required: ["reminder_id"]
        ),
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let bulkCompleteReminders = Tool(
        name: ToolName.bulkCompleteReminders,
        description: "Mark multiple reminders as complete, optionally as a dry run.",
        inputSchema: ReminderToolSchemas.bulkMutation,
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let bulkDeleteReminders = Tool(
        name: ToolName.bulkDeleteReminders,
        description: "Delete multiple reminders, optionally as a dry run.",
        inputSchema: ReminderToolSchemas.bulkMutation,
        annotations: .init(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let bulkMoveReminders = Tool(
        name: ToolName.bulkMoveReminders,
        description: "Move multiple reminders to another list, optionally as a dry run.",
        inputSchema: ReminderToolSchemas.bulkMove,
        annotations: .init(readOnlyHint: false, destructiveHint: false, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )

    static let deleteReminder = Tool(
        name: ToolName.deleteReminder,
        description: "Delete a reminder by identifier.",
        inputSchema: Schema.object(
            properties: ["reminder_id": Schema.string(description: "Reminder identifier")],
            required: ["reminder_id"]
        ),
        annotations: .init(readOnlyHint: false, destructiveHint: true, idempotentHint: true, openWorldHint: false),
        outputSchema: listOutput
    )
}

enum ReminderToolSchemas {
    static let date = Schema.object(
        properties: [
            "date": Schema.string(description: "ISO-8601 date or date-time"),
            "all_day": Schema.boolean(description: "Store the reminder date as all-day"),
            "time_zone": Schema.string(description: "Optional IANA time zone identifier; omit for floating dates"),
        ],
        required: ["date"]
    )

    static let locationAlarm = Schema.object(
        properties: [
            "title": Schema.string(description: "Human-readable location name"),
            "radius": Schema.number(description: "Optional geofence radius in meters"),
            "latitude": Schema.number(description: "Latitude in decimal degrees"),
            "longitude": Schema.number(description: "Longitude in decimal degrees"),
            "proximity": Schema.string(description: "Trigger when entering or leaving", enum: ["enter", "leave"]),
        ],
        required: ["latitude", "longitude"]
    )

    static let alarm = Schema.object(
        properties: [
            "absolute_date": Schema.string(description: "ISO-8601 absolute alarm date-time"),
            "relative_offset": Schema.number(description: "Relative offset in seconds from the due date"),
            "location": locationAlarm,
        ]
    )

    static let recurrence = Schema.object(
        properties: [
            "frequency": Schema.string(enum: ["daily", "weekly", "monthly", "yearly"]),
            "interval": Schema.integer(description: "Repeat interval", minimum: 1),
            "end_date": Schema.string(description: "Optional ISO-8601 recurrence end date-time"),
            "occurrence_count": Schema.integer(description: "Optional number of occurrences", minimum: 1),
            "days_of_week": Schema.array(
                items: Schema.string(enum: [
                    "sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday",
                ])),
            "days_of_month": Schema.array(items: Schema.integer()),
            "months_of_year": Schema.array(items: Schema.integer()),
            "set_positions": Schema.array(items: Schema.integer()),
        ],
        required: ["frequency"]
    )

    static let commonReminderFilterProperties: [String: Value] = [
        "list_ids": Schema.array(
            items: Schema.string(), description: "Optional reminder list identifiers to filter by"),
        "search": Schema.string(description: "Optional case-insensitive title, notes, or location search term"),
        "due_starting": Schema.string(description: "Optional ISO-8601 due-date lower bound"),
        "due_ending": Schema.string(description: "Optional ISO-8601 due-date upper bound"),
        "completed_starting": Schema.string(description: "Optional ISO-8601 completion-date lower bound"),
        "completed_ending": Schema.string(description: "Optional ISO-8601 completion-date upper bound"),
        "has_due_date": Schema.boolean(description: "Filter by reminders that do or do not have a due date"),
        "has_location": Schema.boolean(
            description: "Filter by reminders that do or do not have a plain location string"),
        "has_recurrence": Schema.boolean(
            description: "Filter by reminders that do or do not have recurrence rules"),
        "priority_min": Schema.integer(description: "Minimum priority value", minimum: 0, maximum: 9),
        "priority_max": Schema.integer(description: "Maximum priority value", minimum: 0, maximum: 9),
        "limit": Schema.integer(description: "Maximum reminders to return", minimum: 1),
    ]

    static let listReminders = Schema.object(
        properties: commonReminderFilterProperties.merging([
            "include_completed": Schema.boolean(
                description: "Whether completed reminders should be included in the result")
        ]) { current, _ in current }
    )

    static let completedReminders = Schema.object(properties: commonReminderFilterProperties)
    static let upcomingReminders = Schema.object(properties: commonReminderFilterProperties)

    static let createReminder = Schema.object(
        properties: [
            "list_id": Schema.string(
                description: "Optional target list identifier; defaults to the user's default reminder list"),
            "title": Schema.string(description: "Reminder title"),
            "location": Schema.string(description: "Optional reminder location string"),
            "notes": Schema.string(description: "Optional reminder notes"),
            "priority": Schema.integer(
                description: "Optional EventKit reminder priority (1-9)", minimum: 0, maximum: 9),
            "start_date": date,
            "due_date": date,
            "url": Schema.string(description: "Optional URL associated with the reminder"),
            "is_completed": Schema.boolean(description: "Whether the reminder should be marked complete"),
            "completion_date": Schema.string(description: "Optional ISO-8601 completion date-time"),
            "alarms": Schema.array(items: alarm, description: "Optional time-based or location-based alarms"),
            "recurrence": recurrence,
        ],
        required: ["title"]
    )

    static let updateReminder = Schema.object(
        properties: [
            "reminder_id": Schema.string(description: "Reminder identifier"),
            "list_id": Schema.string(description: "Optional new target list identifier"),
            "title": Schema.string(description: "Updated reminder title"),
            "location": Schema.string(description: "Replacement location value"),
            "clear_location": Schema.boolean(description: "Remove existing location"),
            "notes": Schema.string(description: "Replacement notes value"),
            "clear_notes": Schema.boolean(description: "Remove existing notes"),
            "priority": Schema.integer(description: "Replacement priority value", minimum: 0, maximum: 9),
            "clear_priority": Schema.boolean(description: "Remove existing priority"),
            "start_date": date,
            "clear_start_date": Schema.boolean(description: "Remove existing start date"),
            "due_date": date,
            "clear_due_date": Schema.boolean(description: "Remove existing due date"),
            "url": Schema.string(description: "Replacement URL value"),
            "clear_url": Schema.boolean(description: "Remove existing URL"),
            "is_completed": Schema.boolean(description: "Updated completion state"),
            "completion_date": Schema.string(description: "Replacement ISO-8601 completion date-time"),
            "clear_completion_date": Schema.boolean(description: "Remove completion date"),
            "alarms": Schema.array(items: alarm, description: "Replacement alarms array"),
            "clear_alarms": Schema.boolean(description: "Remove all alarms"),
            "recurrence": recurrence,
            "clear_recurrence": Schema.boolean(description: "Remove recurrence rules"),
        ],
        required: ["reminder_id"]
    )

    static let bulkMutation = Schema.object(
        properties: [
            "reminder_ids": Schema.array(items: Schema.string(), description: "Reminder identifiers to mutate"),
            "dry_run": Schema.boolean(description: "Preview the affected reminders without mutating them"),
        ],
        required: ["reminder_ids"]
    )

    static let bulkMove = Schema.object(
        properties: [
            "reminder_ids": Schema.array(items: Schema.string(), description: "Reminder identifiers to move"),
            "target_list_id": Schema.string(description: "Reminder list identifier to move the reminders into"),
            "dry_run": Schema.boolean(description: "Preview the affected reminders without mutating them"),
        ],
        required: ["reminder_ids", "target_list_id"]
    )
}
