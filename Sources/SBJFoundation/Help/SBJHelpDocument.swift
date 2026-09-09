#if !os(watchOS)
import Foundation

/// Loaded, token-expanded help content ready for a format-specific presenter.
public struct SBJHelpDocument {
    public let asset: SBJHelpAsset
    public let source: String

    public init(asset: SBJHelpAsset, source: String) {
        self.asset = asset
        self.source = source
    }
}
#endif
