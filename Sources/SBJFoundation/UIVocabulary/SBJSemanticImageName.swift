import Foundation

/// Shared semantic UI imagery expressed through `ImageName` rather than raw SF Symbol strings.
///
/// Centralizing these defaults keeps reusable controls on the presentation-resource boundary,
/// where locale, culture, platform, accessibility, or theme can later choose another candidate.
public enum SBJSemanticImageName {
    public static let add: ImageName = .system("plus.circle")
    public static let remove: ImageName = .system("minus.circle")
    public static let apply: ImageName = .system("checkmark.circle")
    public static let selected: ImageName = .system("checkmark")
    public static let clearOptional: ImageName = .system("xmark.circle")
    public static let setOptional: ImageName = .system("circle.dashed")
    public static let regenerate: ImageName = .system("arrow.clockwise.circle")
    public static let information: ImageName = .system("info.circle")
    public static let moveUp: ImageName = .system("arrow.up.circle")
    public static let moveDown: ImageName = .system("arrow.down.circle")
    public static let moveToFirst: ImageName = .system("arrow.up.to.line")
    public static let moveToLast: ImageName = .system("arrow.down.to.line")
    public static let delete: ImageName = .system("trash")
    public static let restore: ImageName = .system("arrow.uturn.backward.circle")
    public static let changed: ImageName = .system("pencil")
    public static let empty: ImageName = .system("rectangle.dashed")

    public static func disclosure(expanded: Bool) -> ImageName {
        .system(expanded ? "chevron.down" : "chevron.right")
    }

    public static func issues(filled: Bool) -> ImageName {
        .system(filled ? "exclamationmark.circle.fill" : "exclamationmark.circle")
    }
}
