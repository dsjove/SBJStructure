import Foundation

/// Shared semantic UI imagery expressed through `ImageReference` rather than raw SF Symbol strings.
///
/// `all` is the single source of truth for both the UI vocabulary and HTML help (`UI_<name>\\`).
/// The typed properties below are only compile-time conveniences for ordinary Swift call sites;
/// they do not repeat or redefine the image mapping.
public enum SBJSemanticImageReference {
    public static let all: [String: ImageReference] = [
        "add": .system("plus.circle"),
        "remove": .system("minus.circle"),
        "apply": .system("checkmark.circle"),
        "selected": .system("checkmark"),
        "clearOptional": .system("xmark.circle"),
        "setOptional": .system("circle.dashed"),
        "regenerate": .system("arrow.clockwise.circle"),
        "information": .system("info.circle"),
        "issues": .system("exclamationmark.circle.fill"),
        "moveUp": .system("arrow.up.circle"),
        "moveDown": .system("arrow.down.circle"),
        "moveToFirst": .system("arrow.up.to.line"),
        "moveToLast": .system("arrow.down.to.line"),
        "delete": .system("trash"),
        "restore": .system("arrow.uturn.backward.circle"),
        "changed": .system("pencil"),
        "empty": .system("rectangle.dashed"),
        "edit": .system("square.and.pencil"),
        "share": .system("square.and.arrow.up"),
        "link": .system("link.circle"),
        "duplicate": .system("plus.square.on.square"),
        "lock": .system("lock"),
        "unlock": .system("lock.open"),
        "characters": .system("person.2"),
        "newPerson": .system("person.badge.plus"),
        "more": .system("ellipsis.circle"),
        "sections": .system("rectangle.grid.1x3"),
        "theme": .system("paintpalette"),
        "pageLayout": .system("inset.filled.rectangle.portrait"),
        "documentSettings": .system("doc.badge.gearshape"),
        "importDocument": .system("arrow.down.document"),
        "exportDocument": .system("arrow.up.document"),
        "showInFolder": .system("folder"),
        "unavailableLink": .system("xmark.circle.fill"),
        "help": .system("questionmark.circle"),
        "about": .system("info.circle"),
        "dismiss": .system("checkmark.circle"),
        "helpUnavailable": .system("questionmark.circle"),
        "unsupportedHelp": .system("doc.questionmark"),
        "scrollPageDown": .system("chevron.down"),
        "scrollToTop": .system("chevron.up.2"),
        "navigateToProperty": .system("chevron.right"),
        "disclosureOpened": .system("chevron.down"),
        "disclosureClosed": .system("chevron.right"),
    ]

    private static func image(_ name: String) -> ImageReference {
        guard let reference = all[name] else {
            preconditionFailure("Unknown standard semantic image: \\(name)")
        }
        return reference
    }

    public static let add = image("add")
    public static let remove = image("remove")
    public static let apply = image("apply")
    public static let selected = image("selected")
    public static let clearOptional = image("clearOptional")
    public static let setOptional = image("setOptional")
    public static let regenerate = image("regenerate")
    public static let information = image("information")
    public static let issues = image("issues")
    public static let moveUp = image("moveUp")
    public static let moveDown = image("moveDown")
    public static let moveToFirst = image("moveToFirst")
    public static let moveToLast = image("moveToLast")
    public static let delete = image("delete")
    public static let restore = image("restore")
    public static let changed = image("changed")
    public static let empty = image("empty")
    public static let edit = image("edit")
    public static let share = image("share")
    public static let link = image("link")
    public static let duplicate = image("duplicate")
    public static let lock = image("lock")
    public static let unlock = image("unlock")
    public static let characters = image("characters")
    public static let newPerson = image("newPerson")
    public static let more = image("more")
    public static let sections = image("sections")
    public static let theme = image("theme")
    public static let pageLayout = image("pageLayout")
    public static let documentSettings = image("documentSettings")
    public static let importDocument = image("importDocument")
    public static let exportDocument = image("exportDocument")
    public static let showInFolder = image("showInFolder")
    public static let unavailableLink = image("unavailableLink")
    public static let help = image("help")
    public static let about = image("about")
    public static let dismiss = image("dismiss")
    public static let helpUnavailable = image("helpUnavailable")
    public static let unsupportedHelp = image("unsupportedHelp")
    public static let scrollPageDown = image("scrollPageDown")
    public static let scrollToTop = image("scrollToTop")
    public static let navigateToProperty = image("navigateToProperty")
    public static let disclosureOpened = image("disclosureOpened")
    public static let disclosureClosed = image("disclosureClosed")

    public static func disclosure(expanded: Bool) -> ImageReference {
        expanded ? disclosureOpened : disclosureClosed
    }
}
