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

    static var editTags: SBJAssetReference {
        .help("Edit Tags", bundle: .module)
    }

    static var attachmentsHelp: SBJAssetReference {
        .help("Attachments", bundle: .module)
    }

    static var unitConversionHelp: SBJAssetReference {
        .help("Unit Conversion", bundle: .module)
    }

    static var structureEditorCore: SBJAssetReference {
        .help("SBJ Structure Editor Core", bundle: .module)
    }

    static var structureEditorSearch: SBJAssetReference {
        .help("SBJ Structure Editor Search", bundle: .module)
    }

    static var imageEdit: SBJAssetReference {
        .help("Image Edit", bundle: .module)
    }

    static var imageView: SBJAssetReference {
        .help("Image View", bundle: .module)
    }
}
