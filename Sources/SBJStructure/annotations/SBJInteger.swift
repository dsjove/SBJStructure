/// Adds integer constraints to a coded property handled by `@SBJStructure`.
/// An ordinary integer property requires no annotation.
///
/// A closed `range` constrains both bounds. `min` constrains only the lower
/// bound. Constrained integer editors validate typed input and provide a
/// stepper within the effective range.
@attached(peer)
public macro SBJInteger(range: ClosedRange<Int>) = #externalMacro(
    module: "SBJStructureMacros",
    type: "SBJIntegerMacro"
)

@attached(peer)
public macro SBJInteger(min: Int) = #externalMacro(
    module: "SBJStructureMacros",
    type: "SBJIntegerMacro"
)
