import Foundation

/// Declares an allowed Date range for an `@SBJStructure` property.
///
/// Date properties require no annotation for structural participation or native
/// date editing. The range is enforced only when validation is explicitly requested
/// and is also supplied to the editor's `DatePicker`.
@attached(peer)
public macro SBJDate(range: ClosedRange<Date>) = #externalMacro(
    module: "SBJStructureMacros",
    type: "SBJDateMacro"
)
