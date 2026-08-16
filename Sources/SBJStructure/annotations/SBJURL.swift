/// Legacy no-op annotation. URL properties are inferred automatically by `@SBJStructure`.
///
/// URL-specific declarations are intentionally deferred until the URL rule surface
/// is designed. New code should leave ordinary URL properties unannotated.
@available(*, deprecated, message: "URL properties are inferred by @SBJStructure; @SBJURL currently adds no information")
@attached(peer)
public macro SBJURL() = #externalMacro(module: "SBJStructureMacros", type: "SBJURLMacro")
