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

#if canImport(ImageIO)
import ImageIO

public extension SBJResourceContent {
    /// Reconstructs image resource metadata from encoded image bytes.
    ///
    /// This is primarily useful for persisted models that historically stored
    /// only the encoded image `Data`. The encoded format is discovered from the
    /// image source instead of being guessed by the caller.
    init?(imageData data: Data) {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let typeIdentifier = CGImageSourceGetType(source),
            let contentType = UTType(typeIdentifier as String)
        else {
            return nil
        }

        self.init(data: data, contentType: contentType)
    }
}
#endif
