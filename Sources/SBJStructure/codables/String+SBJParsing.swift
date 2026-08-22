import Foundation

public extension String {
    /// Parses a URL after trimming surrounding whitespace and newlines.
    ///
    /// This helper intentionally applies no business-rule policy. Relative URLs and
    /// unusual schemes remain representable; `@SBJURL` constraints are evaluated
    /// only by explicit invariant validation.
    var sbjURL: URL? {
        URL(string: trimmingCharacters(in: .whitespacesAndNewlines))
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

    func unjoined(separator s: String) -> [String] {
		components(separatedBy: ",")
			.map { $0.trimmingCharacters(in: .whitespaces) }
	}
}

public extension Collection {
    var second: Element? {
        guard count > 1 else { return nil }
        return self[index(after: startIndex)]
    }
}
