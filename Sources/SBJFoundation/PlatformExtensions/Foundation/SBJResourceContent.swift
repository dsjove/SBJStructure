import Foundation
import UniformTypeIdentifiers

/// Encoded resource content with its Foundation content type.
///
/// This is intentionally separate from `SBJResourceID`: the ID is semantic
/// identity while this value is the transport/storage payload.
public struct SBJResourceContent: Sendable, Equatable {
    public let data: Data
    public let contentType: UTType

    public init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }
}
