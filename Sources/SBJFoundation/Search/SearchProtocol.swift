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

extension String: SearchProtocol {
    public var text: String {
        get { self }
        set { self = newValue }
    }
}

/// A value that owns its search matching behavior.
public protocol Predicated {
    func predicated(search: String) -> Bool
}

extension String: Predicated {
    public var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

	public var normalizedSearchText:  String {
		self.lowercased().filter { $0.isLetter || $0.isNumber }
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
        let normalizedQuery = query.normalizedSearchText
        guard !normalizedQuery.isEmpty else { return true }
        return self.normalizedSearchText.contains(normalizedQuery)
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
