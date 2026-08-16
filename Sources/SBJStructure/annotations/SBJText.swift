/// Declares text presentation metadata and length constraints for `@SBJStructure`.
public enum SBJTextStyle: Sendable, Equatable {
    case singleLine
    case multiline
}

/// Adds String presentation and/or length information beyond the Swift type.
/// Unannotated `String` values already participate and default to `.singleLine`.
/// Length constraints are emitted into the containing type's generated `_invariant`.
@attached(peer)
public macro SBJText(
    _ style: SBJTextStyle = .singleLine,
    minLength: Int? = nil,
    maxLength: Int? = nil
) = #externalMacro(module: "SBJStructureMacros", type: "SBJTextMacro")
