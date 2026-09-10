import Foundation
import UniformTypeIdentifiers

public extension SBJAssetReference {
    /// HTML help stored in the standard `help` resource directory.
    static func help(
        _ displayName: String,
        resourceName: String? = nil,
        bundle: Bundle = .main
    ) -> SBJAssetReference {
        SBJAssetReference(
            displayName: displayName,
            resourceName: resourceName,
            subdirectory: "help",
            bundle: bundle,
            contentType: .html
        )
    }

    static var structureEditorCore: SBJAssetReference {
        .help("SBJ Structure Editor Core", bundle: .module)
    }

    static var structureEditorSearch: SBJAssetReference {
        .help("SBJ Structure Editor Search", bundle: .module)
    }
}
