/// Excludes a stored property from `SBJCodableEditor` field generation.
///
/// The property remains part of `@SBJStructure` structural metadata, content
/// inspection, and explicit invariant validation. Use this marker when a coded
/// property belongs to the model declaration but should not be edited by the
/// generic editor. It also suppresses the immutable-property editor warning.
@attached(peer)
public macro SBJNotEditable() = #externalMacro(
    module: "SBJStructureMacros",
    type: "SBJNotEditableMacro"
)
