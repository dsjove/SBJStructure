#if !os(watchOS)
import Foundation
import UIKit
import UniformTypeIdentifiers

/// Application-level values used while resolving help templates.
///
/// Defaults preserve the historical Software by Jove help contract while
/// allowing an application to override every value when needed.
public struct SBJHelpConfiguration {
    public var aboutAsset: SBJHelpAsset?
    public var styleSheetAsset: SBJHelpAsset?
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
    public var embeddedAssets: [String: SBJHelpAsset]

    public init(
        aboutAsset: SBJHelpAsset? = SBJHelpAsset(title: "About", folder: "help", bundle: .main, contentType: .html),
        styleSheetAsset: SBJHelpAsset? = SBJHelpAsset(title: "StyleSheet", folder: "help", bundle: .main, contentType: .html),
        autoPresentAbout: Bool = true,
        substitutions: [String: String] = [:],
        semanticImages: [String: ImageReference] = Self.standardSemanticImages,
        applicationIcon: ImageReference? = .bundled("HelpIcon", bundle: .main),
        embeddedAssets: [String: SBJHelpAsset] = [
            "SBJ_STRUCTURE_EDITOR_HELP": .structureEditor,
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

    public static var standardSemanticImages: [String: ImageReference] {
        [
            "add": SBJSemanticImageReference.add,
            "remove": SBJSemanticImageReference.remove,
            "apply": SBJSemanticImageReference.apply,
            "clear": SBJSemanticImageReference.clearOptional,
            "set": SBJSemanticImageReference.setOptional,
            "information": SBJSemanticImageReference.information,
            "moveUp": SBJSemanticImageReference.moveUp,
            "moveDown": SBJSemanticImageReference.moveDown,
            "moveToFirst": SBJSemanticImageReference.moveToFirst,
            "moveToLast": SBJSemanticImageReference.moveToLast,
            "delete": SBJSemanticImageReference.delete,
            "restore": SBJSemanticImageReference.restore,
            "edit": SBJSemanticImageReference.edit,
            "share": SBJSemanticImageReference.share,
            "help": SBJSemanticImageReference.help,
            "about": SBJSemanticImageReference.about,
            "duplicate": SBJSemanticImageReference.duplicate,
            "lock": SBJSemanticImageReference.lock,
            "unlock": SBJSemanticImageReference.unlock,
            "characters": SBJSemanticImageReference.characters,
            "newPerson": SBJSemanticImageReference.newPerson,
            "more": SBJSemanticImageReference.more,
            "sections": SBJSemanticImageReference.sections,
            "theme": SBJSemanticImageReference.theme,
            "pageLayout": SBJSemanticImageReference.pageLayout,
            "documentSettings": SBJSemanticImageReference.documentSettings,
            "importDocument": SBJSemanticImageReference.importDocument,
            "exportDocument": SBJSemanticImageReference.exportDocument,
            "showInFolder": SBJSemanticImageReference.showInFolder,
        ]
    }
}

#endif
