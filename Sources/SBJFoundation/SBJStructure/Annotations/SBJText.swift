/// Declares text presentation metadata and length constraints for `@SBJStructure`.
public enum SBJTextStyle: Sendable, Equatable {
    case singleLine
    case multiline
    /// Uses a compact multiline field with an affordance that promotes editing into a sheet.
    /// This is an editor interaction hint; storage, validation, Codable, and future
    /// localization/text-resolution semantics remain those of ordinary text.
    case sheetEdit
}

/// Adds String presentation and/or length information beyond the Swift type.
/// Unannotated `String` values already participate and default to `.singleLine`.
/// Length constraints are emitted into the containing type's generated `_invariant`.
@attached(peer)
public macro SBJText(
    _ style: SBJTextStyle = .singleLine,
    minLength: Int? = nil,
    maxLength: Int? = nil
) = #externalMacro(module: "SBJFoundationMacros", type: "SBJTextMacro")
