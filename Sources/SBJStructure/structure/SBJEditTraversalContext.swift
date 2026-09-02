/// UI-independent position within a recursively edited value tree.
///
/// The same editable field can occur at different depths depending on where its
/// containing value is used, so tree level is traversal context rather than
/// static field metadata. Alternative editors can use this to drive indentation,
/// outline levels, accessibility hierarchy, or other tree-oriented presentation.
public struct SBJEditTraversalContext: Hashable, Sendable {
    public let treeLevel: Int

    public init(treeLevel: Int = 0) {
        precondition(treeLevel >= 0, "treeLevel cannot be negative")
        self.treeLevel = treeLevel
    }

    public static let root = SBJEditTraversalContext()

    public func descended() -> SBJEditTraversalContext {
        SBJEditTraversalContext(treeLevel: treeLevel + 1)
    }
}
