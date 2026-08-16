import Foundation

public extension Set {
    /// Replaces one element without silently collapsing the set when the
    /// replacement already exists.
    ///
    /// Returns `false` and leaves the set unchanged if `oldValue` is absent or
    /// `newValue` would collide with another existing member.
    @discardableResult
    mutating func sbjReplace(_ oldValue: Element, with newValue: Element) -> Bool {
        guard contains(oldValue) else { return false }
        if oldValue != newValue, contains(newValue) { return false }
        remove(oldValue)
        insert(newValue)
        return true
    }
}

public extension Dictionary {
    /// Renames a key without overwriting an existing entry.
    ///
    /// Returns `false` and leaves the dictionary unchanged if `oldKey` is
    /// absent or `newKey` already belongs to another entry.
    @discardableResult
    mutating func sbjRenameKey(_ oldKey: Key, to newKey: Key) -> Bool {
        guard let value = self[oldKey] else { return false }
        if oldKey != newKey, self[newKey] != nil { return false }
        removeValue(forKey: oldKey)
        self[newKey] = value
        return true
    }
}
