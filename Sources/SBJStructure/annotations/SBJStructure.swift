/// Generates UI-independent SBJStructure metadata and optional editor integration
/// for a `Codable` structure or enum.
///
/// The macro does not wrap stored properties, intercept reads or writes, or
/// automatically validate assignments. Structural rules are consumed only when
/// validation or another SBJStructure consumer is explicitly invoked.
///
/// For structures, coded stored properties become structural metadata. Stored
/// writable properties also become recursive editor fields. Writable computed
/// properties remain outside the structure unless explicitly marked
/// `@SBJEditorProperty`, in which case they become editor-only fields. Immutable
/// `let` properties remain structural but are not included in generated editor fields.
///
/// For enums, each case becomes a selection and its associated values become
/// recursively editable fields. Changing an associated value reconstructs the
/// enum case while preserving the other associated values.
@attached(
    member,
    names: named(sbjProperties), named(sbjEditorFields), named(sbjEditorEnumCases), named(sbjCreateEditorValue), named(sbjCreateEditorValueIfPossible), named(sbjDefaultValue), named(sbjCaseName), named(sbjCaseNames), named(_hasContent), named(hasContent), named(_invariant), named(invariant)
)
@attached(extension, conformances: SBJEditable, SBJEditableAssociatedEnum, SBJStructuredEnum)
public macro SBJStructure() = #externalMacro(
    module: "SBJStructureMacros",
    type: "SBJStructureMacro"
)
