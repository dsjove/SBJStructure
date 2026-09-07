import Foundation

/// Shared semantic UI imagery expressed through `ImageReference` rather than raw SF Symbol strings.
///
/// Centralizing these defaults keeps reusable controls on the presentation-resource boundary,
/// where locale, culture, platform, accessibility, or theme can later choose another candidate.
public enum SBJSemanticImageReference {
    public static let add: ImageReference = .system("plus.circle")
    public static let remove: ImageReference = .system("minus.circle")
    public static let apply: ImageReference = .system("checkmark.circle")
    public static let selected: ImageReference = .system("checkmark")
    public static let clearOptional: ImageReference = .system("xmark.circle")
    public static let setOptional: ImageReference = .system("circle.dashed")
    public static let regenerate: ImageReference = .system("arrow.clockwise.circle")
    public static let information: ImageReference = .system("info.circle")
    public static let moveUp: ImageReference = .system("arrow.up.circle")
    public static let moveDown: ImageReference = .system("arrow.down.circle")
    public static let moveToFirst: ImageReference = .system("arrow.up.to.line")
    public static let moveToLast: ImageReference = .system("arrow.down.to.line")
    public static let delete: ImageReference = .system("trash")
    public static let restore: ImageReference = .system("arrow.uturn.backward.circle")
    public static let changed: ImageReference = .system("pencil")
    public static let empty: ImageReference = .system("rectangle.dashed")
    public static let edit: ImageReference = .system("square.and.pencil")
    public static let link: ImageReference = .system("link.circle")
    public static let unavailableLink: ImageReference = .system("xmark.circle.fill")

    public static func disclosure(expanded: Bool) -> ImageReference {
        .system(expanded ? "chevron.down" : "chevron.right")
    }

    public static func issues(filled: Bool) -> ImageReference {
        .system(filled ? "exclamationmark.circle.fill" : "exclamationmark.circle")
    }
}
