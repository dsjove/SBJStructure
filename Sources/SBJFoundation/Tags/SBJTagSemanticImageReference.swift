import Foundation

/// Semantic imagery used by tag UI and tag help.
public enum SBJTagSemanticImageReference {
    public static let all: [String: ImageReference] = [
        "tags": .system("tag.fill"),
        "primaryTag": .system("star.fill"),
        "notPrimaryTag": .system("star"),
    ]

    private static func image(_ name: String) -> ImageReference {
        guard let reference = all[name] else {
            preconditionFailure("Unknown tag semantic image: \(name)")
        }
        return reference
    }

    public static let tags = image("tags")
    public static let primaryTag = image("primaryTag")
    public static let notPrimaryTag = image("notPrimaryTag")

    public static var helpConfiguration: SBJHelpConfiguration {
        var configuration = SBJHelpConfiguration.standard
        configuration.semanticImages = SBJSemanticImageReference.vocabulary(adding: all)
        return configuration
    }
}
