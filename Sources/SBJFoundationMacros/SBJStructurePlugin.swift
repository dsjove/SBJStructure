import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct SBJStructurePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        SBJStructureMacro.self,
        SBJDesignatedInitMacro.self,
        SBJNotEditableMacro.self,
        SBJEditorPropertyMacro.self,
        SBJPresentationMacro.self,
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
