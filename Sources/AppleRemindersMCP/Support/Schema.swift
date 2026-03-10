import MCP

enum Schema {
    static func object(
        properties: [String: Value],
        required: [String] = [],
        additionalProperties: Bool = false,
        description: String? = nil
    ) -> Value {
        var object: [String: Value] = [
            "type": "object",
            "properties": .object(properties),
            "additionalProperties": .bool(additionalProperties),
        ]
        if !required.isEmpty {
            object["required"] = .array(required.map(Value.string))
        }
        if let description {
            object["description"] = .string(description)
        }
        return .object(object)
    }

    static func string(description: String? = nil, enum values: [String] = []) -> Value {
        var object: [String: Value] = ["type": "string"]
        if let description {
            object["description"] = .string(description)
        }
        if !values.isEmpty {
            object["enum"] = .array(values.map(Value.string))
        }
        return .object(object)
    }

    static func integer(description: String? = nil, minimum: Int? = nil, maximum: Int? = nil) -> Value {
        var object: [String: Value] = ["type": "integer"]
        if let description {
            object["description"] = .string(description)
        }
        if let minimum {
            object["minimum"] = .int(minimum)
        }
        if let maximum {
            object["maximum"] = .int(maximum)
        }
        return .object(object)
    }

    static func number(description: String? = nil) -> Value {
        var object: [String: Value] = ["type": "number"]
        if let description {
            object["description"] = .string(description)
        }
        return .object(object)
    }

    static func boolean(description: String? = nil) -> Value {
        var object: [String: Value] = ["type": "boolean"]
        if let description {
            object["description"] = .string(description)
        }
        return .object(object)
    }

    static func array(items: Value, description: String? = nil) -> Value {
        var object: [String: Value] = [
            "type": "array",
            "items": items,
        ]
        if let description {
            object["description"] = .string(description)
        }
        return .object(object)
    }
}
