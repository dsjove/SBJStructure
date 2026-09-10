import Foundation
import UniformTypeIdentifiers

/// Application-level values used while resolving help templates.
///
/// Defaults preserve the historical Software by Jove help contract while
/// allowing an application to override every value when needed.
public struct SBJHelpConfiguration {
    public var aboutAsset: SBJAssetReference?
    public var styleSheetAsset: SBJAssetReference?
    public var autoPresentAbout: Bool
    public var substitutions: [String: String]
    /// Semantic images available to HTML help as `UI_name\` tokens.
    /// Keeping these names semantic lets help use the same image vocabulary as
    /// the application UI instead of repeating SF Symbol names in documentation.
    public var semanticImages: [String: ImageReference]
    /// Optional image used by the standard `ICON` token. Apps can provide a
    /// dedicated help-sized copy of their app icon as an ordinary image asset.
    public var applicationIcon: ImageReference?
    /// Named help documents that may be embedded into another template.
    /// The dictionary key is the token written in the parent help source.
    public var embeddedAssets: [String: SBJAssetReference]

    public init(
        aboutAsset: SBJAssetReference? = .help("About"),
        styleSheetAsset: SBJAssetReference? = .help("Style Sheet"),
        autoPresentAbout: Bool = true,
        substitutions: [String: String] = [:],
        semanticImages: [String: ImageReference] = SBJSemanticImageReference.all,
        applicationIcon: ImageReference? = .bundled("HelpIcon", bundle: .main),
        embeddedAssets: [String: SBJAssetReference] = [
            "SBJ_STRUCTURE_EDITOR_CORE_HELP": .structureEditorCore,
            "SBJ_STRUCTURE_EDITOR_SEARCH_HELP": .structureEditorSearch,
        ]
    ) {
        self.aboutAsset = aboutAsset
        self.styleSheetAsset = styleSheetAsset
        self.autoPresentAbout = autoPresentAbout
        self.substitutions = substitutions
        self.semanticImages = semanticImages
        self.applicationIcon = applicationIcon
        self.embeddedAssets = embeddedAssets
    }

    public static var standard: Self { .init() }

}
