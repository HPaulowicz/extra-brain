import Foundation

enum SessionIDValidator {
    private static let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")

    /// Returns a normalized session ID if safe for filesystem path usage.
    static func normalize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 128 else { return nil }
        guard trimmed.rangeOfCharacter(from: allowedCharacters.inverted) == nil else { return nil }
        guard !trimmed.contains(".."), !trimmed.hasPrefix(".") else { return nil }
        return trimmed
    }
}
