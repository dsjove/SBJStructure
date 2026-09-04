import Foundation

/// Shared semantic editor imagery expressed through `ImageName` rather than SF Symbol strings
/// at button call sites across SBJStructure and application-specific editors.
///
/// Keeping editor controls on this vocabulary boundary lets the future presentation /
/// localization resolver substitute culturally appropriate, vendor-specific, or otherwise
/// contextual imagery without rewriting the editor views. The values below are today's
/// default visual candidates, not a promise that a semantic action is permanently tied to
/// one SF Symbol.
public enum SBJEditorImageName {
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

    /// Disclosure used by the generic structured editor hierarchy.
    public static func disclosure(expanded: Bool) -> ImageName {
        .system(expanded ? "chevron.down" : "chevron.right")
    }

    /// Disclosure for application section-settings rows. This is intentionally
    /// a separate semantic action from the structured editor's disclosure even
    /// though today's default candidate is the same chevron pair.
    public static func sectionSettingsDisclosure(expanded: Bool) -> ImageName {
        .system(expanded ? "chevron.down" : "chevron.right")
    }

    public static func issues(filled: Bool) -> ImageName {
        .system(filled ? "exclamationmark.circle.fill" : "exclamationmark.circle")
    }
}
