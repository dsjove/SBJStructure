#if !os(watchOS)
import Foundation
import UIKit
import UniformTypeIdentifiers

/// Application-level values used while resolving help templates.
///
/// Defaults preserve the historical Software by Jove help contract while
/// allowing an application to override every value when needed.
public struct SBJHelpConfiguration {
    public var companyName: String
    public var supportEmail: String
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
        companyName: String = "Software by Jove",
        supportEmail: String = "softwarebyjove@gmail.com",
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
        self.companyName = companyName
        self.supportEmail = supportEmail
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

public enum SBJHelpApplicationInfo {
    public static var displayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Unknown App"
    }

    public static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Unknown"
    }

    public static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "Unknown"
    }

    public static var fullVersion: String { "\(version) (\(build))" }

    public static var icon: UIImage? {
        if let named = UIImage(named: "HelpIcon") { return named }

        if let iconName = Bundle.main.object(forInfoDictionaryKey: "CFBundleIconName") as? String {
            if let named = UIImage(named: iconName) { return named }
            if let url = Bundle.main.url(forResource: iconName, withExtension: "icns"),
               let image = UIImage(contentsOfFile: url.path) {
                return image
            }
        }

        let dictionaries = ["CFBundleIcons", "CFBundleIcons~ipad"]
        for key in dictionaries {
            guard
                let icons = Bundle.main.infoDictionary?[key] as? [String: Any],
                let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
                let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String]
            else { continue }

            for iconFile in iconFiles.reversed() {
                if let named = UIImage(named: iconFile) { return named }
                let ns = iconFile as NSString
                let ext = ns.pathExtension.isEmpty ? nil : ns.pathExtension
                let name = ext == nil ? iconFile : ns.deletingPathExtension
                if let url = Bundle.main.url(forResource: name, withExtension: ext),
                   let image = UIImage(contentsOfFile: url.path) {
                    return image
                }
            }
        }
        return nil
    }
}
#endif
