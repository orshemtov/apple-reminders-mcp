import Foundation

enum ColorFormatting {
    static func normalizedHexString(from cgColorDescription: String?) -> String? {
        guard let cgColorDescription else { return nil }
        let trimmed = cgColorDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") {
            return trimmed
        }
        return nil
    }
}
