import Foundation

public extension String {
	func unjoined(separator s: String = ",") -> [String] {
		components(separatedBy: s)
			.map { $0.trimmingCharacters(in: .whitespaces) }
	}
}

public extension Int {
	func signedDescription(apply: Bool = true, zero: Bool = true) -> String {
		if apply && ((zero && self == 0) || (self > 0)) {
			"+\(self)"
		} else {
			"\(self)"
		}
	}
}

public extension String {
    /// Case-insensitive, surrounding-whitespace-insensitive equality.
    func isEquivalent(to other: String?) -> Bool {
        guard let other else { return false }
        return trimmingCharacters(in: .whitespacesAndNewlines)
            .caseInsensitiveCompare(other.trimmingCharacters(in: .whitespacesAndNewlines)) == .orderedSame
    }

    /// Applies a set of literal replacements in sequence.
    func replacingOccurrences(using replacements: [String: String]) -> String {
        replacements.reduce(self) { result, replacement in
            result.replacingOccurrences(of: replacement.key, with: replacement.value)
        }
    }
}
