import Foundation

/// Codable value representation of the generic, user-visible portion of a tag.
///
/// Persistent tag models often cannot or should not conform directly to `Codable`
/// because their relationship graph belongs to the persistence layer. This value
/// type provides a stable representation for export, recovery, interchange, and
/// other serialization without coupling Codable to SwiftData relationships.
public struct TagCodableValue<ID: Codable & Equatable>: Codable, Equatable {
    public var id: ID
    public var name: String
    public var color: CodableColor

    public init(id: ID, name: String, color: CodableColor) {
        self.id = id
        self.name = name
        self.color = color
    }

    public init<Tag: Tagging>(_ tag: Tag) where Tag.ID == ID {
        self.init(id: tag.id, name: tag.name, color: tag.color)
    }
}

public extension Tagging where ID: Codable & Equatable {
    var codableValue: TagCodableValue<ID> {
        TagCodableValue(self)
    }
}
