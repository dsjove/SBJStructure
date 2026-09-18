#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers

public extension SBJResourceContent {
    /// Decodes ordinary image content, or resolves an SBJ image document to its persisted thumbnail (source fallback).
    var uiImage: UIImage? {
#if !os(watchOS) && !os(tvOS)
        if contentType == .sbjImageDocument {
            return (try? SBJImageDocument(serializedRepresentation: data))?.thumbnailImage
        }
#endif
        guard contentType.conforms(to: .image) else { return nil }
        return UIImage(data: data)
    }
}
#endif
