/// Adds a floating-point range constraint to a coded property handled by `@SBJStructure`.
/// An ordinary floating-point property requires no annotation.
@attached(peer)
public macro SBJNumber(range: ClosedRange<Double>) = #externalMacro(
    module: "SBJStructureMacros",
    type: "SBJNumberMacro"
)
