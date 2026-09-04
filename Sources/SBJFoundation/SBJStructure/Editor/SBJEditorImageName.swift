import Foundation

/// Semantic editor imagery expressed through `ImageName` rather than SF Symbol strings
/// at button call sites.
///
/// Keeping editor controls on this vocabulary boundary lets the future presentation /
/// localization resolver substitute culturally appropriate, vendor-specific, or otherwise
/// contextual imagery without rewriting the editor views. The values below are today's
/// default visual candidates, not a promise that a semantic action is permanently tied to
/// one SF Symbol.
enum SBJEditorImageName {
    static let add: ImageName = .system("plus.circle")
    static let remove: ImageName = .system("minus.circle")
    static let apply: ImageName = .system("checkmark.circle")
    static let selected: ImageName = .system("checkmark")
    static let clearOptional: ImageName = .system("xmark.circle")
    static let setOptional: ImageName = .system("circle.dashed")
    static let regenerate: ImageName = .system("arrow.clockwise.circle")
    static let information: ImageName = .system("info.circle")
    static let moveUp: ImageName = .system("arrow.up.circle")
    static let moveDown: ImageName = .system("arrow.down.circle")
    static let changed: ImageName = .system("pencil")
    static let empty: ImageName = .system("rectangle.dashed")

    static func disclosure(expanded: Bool) -> ImageName {
        .system(expanded ? "chevron.down" : "chevron.right")
    }

    static func issues(filled: Bool) -> ImageName {
        .system(filled ? "exclamationmark.circle.fill" : "exclamationmark.circle")
    }
}
