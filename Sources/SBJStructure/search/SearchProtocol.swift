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

/// Matches display text using the same semantics as the public String/Predicated API.
/// This is intentionally internal: the public search vocabulary remains
/// SearchProtocol + Predicated rather than introducing a second search abstraction.
func sbjPredicated(_ text: String, search: String) -> Bool {
    text.predicated(search: search)
}

/// Matches an arbitrary value for structural/editor search.
///
/// Explicit model search behavior wins in this order:
/// 1. Predicated (the value owns the matching rule)
/// 2. SearchProtocol.text (the value contributes additional searchable text)
/// 3. shared structural description
/// 4. String(describing:) fallback
func sbjPredicated<Value>(_ value: Value, search: String) -> Bool {
    guard search.querify != nil else { return true }

    if let predicated = value as? any Predicated {
        return predicated.predicated(search: search)
    }

    if let searchable = value as? any SearchProtocol,
       searchable.text.predicated(search: search) {
        return true
    }

    if let description = SBJValueDescription.describe(value),
       description.predicated(search: search) {
        return true
    }

    return String(describing: value).predicated(search: search)
}

func sbjPredicated<Value>(label: String, value: Value, search: String) -> Bool {
    guard search.querify != nil else { return true }
    return label.predicated(search: search) || sbjPredicated(value, search: search)
}
