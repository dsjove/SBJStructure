import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SBJStructurePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SBJStructureMacro.self,
        SBJNotEditableMacro.self,
        SBJTextMacro.self,
        SBJIntegerMacro.self,
        SBJNumberMacro.self,
        SBJOptionalMacro.self,
        SBJArrayMacro.self,
        SBJSetMacro.self,
        SBJDictionaryMacro.self,
        SBJURLMacro.self,
        SBJUUIDMacro.self,
        SBJDateMacro.self,
        SBJDataMacro.self,
        SBJColorMacro.self,
    ]
}
