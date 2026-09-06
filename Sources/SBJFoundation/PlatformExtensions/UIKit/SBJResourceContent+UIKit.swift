#if canImport(UIKit)
import UIKit
import UniformTypeIdentifiers

public extension SBJResourceContent {
    /// Decodes image resource content for presentation.
    @MainActor
    var uiImage: UIImage? {
        guard contentType.conforms(to: .image) else { return nil }
        return UIImage(data: data)
    }
}
#endif
