import Foundation

/// Semantic imagery used by unit controls and unit-conversion help.
public enum SBJUnitSemanticImageReference {
    public static let all: [String: ImageReference] = [
        "resetValue": .system("1.square"),
        "swapUnits": .system("arrow.left.arrow.right"),
    ]

    private static func image(_ name: String) -> ImageReference {
        guard let reference = all[name] else {
            preconditionFailure("Unknown unit semantic image: \(name)")
        }
        return reference
    }

    public static let resetValue = image("resetValue")
    public static let swapUnits = image("swapUnits")

    public static var helpConfiguration: SBJHelpConfiguration {
        var configuration = SBJHelpConfiguration.standard
        configuration.semanticImages = SBJSemanticImageReference.vocabulary(adding: all)
        return configuration
    }
}
