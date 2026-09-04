import Foundation

/// A first-class search value. Conforming types can expose more searchable text
/// than is obvious from their normal display representation.
public protocol SearchProtocol {
    var text: String { get set }
    var isEmpty: Bool { get }
}

public extension SearchProtocol {
    var isEmpty: Bool { text.isEmpty }
}

/// A value that owns its search matching behavior.
public protocol Predicated {
    func predicated(search: String) -> Bool
}

private func normalizedSearchText(_ text: String) -> String {
    text.lowercased().filter { $0.isLetter || $0.isNumber }
}

extension String: Predicated {
    public var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Original query interface: trimmed text, or nil when blank.
    public var querify: String? {
        let query = trimmed
        return query.isEmpty ? nil : query
    }

    /// Search matching is deliberately forgiving about case, whitespace, and
    /// punctuation while retaining the original `Predicated` API.
    public func predicated(search: String) -> Bool {
        guard let query = search.querify else { return true }
        let normalizedQuery = normalizedSearchText(query)
        guard !normalizedQuery.isEmpty else { return true }
        return normalizedSearchText(self).contains(normalizedQuery)
    }
}

extension String: SearchProtocol {
    public var text: String {
        get { self }
        set { self = newValue }
    }
}

public extension Array where Element: Predicated {
    func predicated(search: String) -> Bool {
        contains { $0.predicated(search: search) }
    }

    func filter(search: String) -> [Element] {
        filter { $0.predicated(search: search) }
    }
}

// MARK: - Internal structural/editor matching

/// One normalized query reused throughout a structural match.  In particular,
/// this avoids repeatedly allocating a full `String(describing:)` representation
/// for large structs/collections at every ancestor in the editor tree.
private struct SBJStructuralSearchMatcher {
    let originalQuery: String
    let normalizedQuery: String

    init?(_ search: String) {
        guard let query = search.querify else { return nil }
        let normalized = normalizedSearchText(query)
        guard !normalized.isEmpty else { return nil }
        self.originalQuery = query
        self.normalizedQuery = normalized
    }

    func matchesText(_ text: String) -> Bool {
        normalizedSearchText(text).contains(normalizedQuery)
    }

    func matches(_ value: Any, depth: Int = 0) -> Bool {
        // Codable values should not form cycles in normal SBJStructure use, but
        // keep malformed/reflected object graphs from recursing without bound.
        guard depth < 64 else { return false }

        if let predicated = value as? any Predicated {
            return predicated.predicated(search: originalQuery)
        }

        if let searchable = value as? any SearchProtocol,
           matchesText(searchable.text) {
            return true
        }

        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            guard let child = mirror.children.first else { return false }
            return matches(child.value, depth: depth + 1)
        }

        // Foundation/scalar editor values are atomic even when their Mirror
        // representation happens to be a struct. Do not descend into their
        // implementation details.
        if isAtomicValue(value) {
            if let description = SBJValueDescription.describe(value) {
                return matchesText(description)
            }
            return matchesText(String(describing: value))
        }

        if (mirror.displayStyle == .struct || mirror.displayStyle == .class),
           let described = value as? any CustomStringConvertible {
            let text = described.description.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty, matchesText(text) { return true }
        }

        switch mirror.displayStyle {
        case .struct, .class, .collection, .set, .dictionary, .tuple:
            for child in mirror.children {
                if let label = child.label, matchesText(label) { return true }
                if matches(child.value, depth: depth + 1) { return true }
            }
            return false

        case .enum:
            // Associated-value enums expose their payload through Mirror. Search
            // the case/child label first and then each associated value instead
            // of stringifying the complete payload recursively.
            if mirror.children.isEmpty {
                return matchesText(String(describing: value))
            }
            for child in mirror.children {
                if let label = child.label, matchesText(label) { return true }
                if matches(child.value, depth: depth + 1) { return true }
            }
            return false

        default:
            if let description = SBJValueDescription.describe(value) {
                return matchesText(description)
            }
            return matchesText(String(describing: value))
        }
    }

    private func isAtomicValue(_ value: Any) -> Bool {
        switch value {
        case is String, is Character, is Bool,
             is Int, is Int8, is Int16, is Int32, is Int64,
             is UInt, is UInt8, is UInt16, is UInt32, is UInt64,
             is Float, is Double, is Decimal,
             is Date, is URL, is UUID, is Data:
            return true
        default:
            return false
        }
    }
}

/// Matches display text using the same normalized semantics as the public
/// String/Predicated API.
func sbjPredicated(_ text: String, search: String) -> Bool {
    guard let matcher = SBJStructuralSearchMatcher(search) else { return true }
    return matcher.matchesText(text)
}

/// Matches an arbitrary value for structural/editor search without first
/// constructing a recursive textual description of the entire value.
func sbjPredicated<Value>(_ value: Value, search: String) -> Bool {
    guard let matcher = SBJStructuralSearchMatcher(search) else { return true }
    return matcher.matches(value)
}

func sbjPredicated<Value>(label: String, value: Value, search: String) -> Bool {
    guard let matcher = SBJStructuralSearchMatcher(search) else { return true }
    return matcher.matchesText(label) || matcher.matches(value)
}
