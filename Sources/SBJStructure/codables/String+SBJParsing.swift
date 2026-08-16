import Foundation

public extension String {
    /// Parses a URL after trimming surrounding whitespace and newlines.
    ///
    /// SBJStructure requires an explicit URL scheme so partially entered values
    /// such as `example.com` are not committed by smart editors.
    var sbjURL: URL? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard let candidate = URL(string: trimmed), candidate.scheme != nil else { return nil }
        return candidate
    }

    /// Parses a UUID from canonical, compact, or brace-wrapped text.
    ///
    /// Compact 32-character UUIDs are normalized by inserting the canonical
    /// hyphens before parsing.
    var sbjUUID: UUID? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
        if let direct = UUID(uuidString: trimmed) { return direct }

        let compact = trimmed.replacingOccurrences(of: "-", with: "")
        guard compact.count == 32 else { return nil }
        let positions = Set([8, 12, 16, 20])
        var canonical = ""
        canonical.reserveCapacity(36)
        for (index, character) in compact.enumerated() {
            if positions.contains(index) { canonical.append("-") }
            canonical.append(character)
        }
        return UUID(uuidString: canonical)
    }
}
