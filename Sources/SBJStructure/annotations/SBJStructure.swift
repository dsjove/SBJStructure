/// Generates UI-independent SBJStructure metadata and optional editor integration
/// for a `Codable` structure or enum.
///
/// The macro does not wrap stored properties, intercept reads or writes, or
/// automatically validate assignments. Structural rules are consumed only when
/// validation or another SBJStructure consumer is explicitly invoked.
///
/// For structures, coded stored properties become structural metadata. Stored
/// writable properties also become recursive editor fields.
/// Immutable `let` properties produce a warning unless explicitly marked
/// `@SBJNotEditable`.
///
/// For enums, each case becomes a selection and its associated values become
/// recursively editable fields. Changing an associated value reconstructs the
/// enum case while preserving the other associated values.
@attached(
    member,
    names: named(sbjProperties), named(sbjEditorFields), named(sbjEditorEnumCases), named(sbjCreateEditorValue), named(sbjCreateEditorValueIfPossible), named(_hasContent), named(hasContent), named(_invariant), named(invariant)
)
@attached(extension, conformances: SBJEditable, SBJEditableAssociatedEnum)
public macro SBJStructure() = #externalMacro(
    module: "SBJStructureMacros",
    type: "SBJStructureMacro"
)
