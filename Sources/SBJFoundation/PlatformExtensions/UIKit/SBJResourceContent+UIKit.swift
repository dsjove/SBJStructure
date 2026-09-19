#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers

public extension SBJResourceContent {
    /// Decodes ordinary image content, or resolves an SBJ image document to its persisted thumbnail (source fallback).
    var uiImage: UIImage? {
#if !os(watchOS) && !os(tvOS)
        if let document = try? SBJImageDocument(resourceContent: self) {
            return document.thumbnailImage
        }
#endif
        guard contentType.conforms(to: .image) else { return nil }
        return UIImage(data: data)
    }
}
#endif
