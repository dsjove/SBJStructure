import Foundation

/// Semantic imagery used by attachment UI and attachment help.
public enum SBJAttachmentSemanticImageReference {
    public static let all: [String: ImageReference] = [
        "attachments": .system("paperclip"),
        "previewAttachment": .system("doc.text.magnifyingglass"),
    ]

    private static func image(_ name: String) -> ImageReference {
        guard let reference = all[name] else {
            preconditionFailure("Unknown attachment semantic image: \(name)")
        }
        return reference
    }

    public static let attachments = image("attachments")
    public static let previewAttachment = image("previewAttachment")

    public static var helpConfiguration: SBJHelpConfiguration {
        var configuration = SBJHelpConfiguration.standard
        configuration.semanticImages = SBJSemanticImageReference.vocabulary(adding: all)
        return configuration
    }
}
