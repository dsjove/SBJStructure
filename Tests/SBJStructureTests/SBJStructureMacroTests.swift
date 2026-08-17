import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
@testable import SBJStructureMacros

final class SBJStructureMacroTests: XCTestCase {
    private let macros: [String: Macro.Type] = [
        "SBJStructure": SBJStructureMacro.self,
        "SBJNotEditable": SBJNotEditableMacro.self,
        "SBJEditorProperty": SBJEditorPropertyMacro.self,
        "SBJText": SBJTextMacro.self,
        "SBJInteger": SBJIntegerMacro.self,
        "SBJNumber": SBJNumberMacro.self,
        "SBJOptional": SBJOptionalMacro.self,
        "SBJArray": SBJArrayMacro.self,
        "SBJSet": SBJSetMacro.self,
        "SBJDictionary": SBJDictionaryMacro.self,
        "SBJURL": SBJURLMacro.self,
        "SBJUUID": SBJUUIDMacro.self,
        "SBJDate": SBJDateMacro.self,
        "SBJData": SBJDataMacro.self,
        "SBJColor": SBJColorMacro.self,
    ]

    func testEmptyStructureGeneratesPublicConsumptionHooksAndEditorConformance() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Empty {}
            """,
            expandedSource: """
            struct Empty {

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [

                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [

                    ]
                }

                var _hasContent: Bool {
                    true
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {

                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }

                static func sbjDefaultValue() -> Self? {
                    .init()
                }
            }

            extension Empty: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testAnnotatedStoredPropertyRemainsStoredProperty() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                @SBJText(minLength: 1, maxLength: 40)
                var displayName: String
            }
            """,
            expandedSource: """
            struct Model {
                var displayName: String

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "displayName", displayName: "displayName".uncamelCased, keyPath: \\Self.displayName, kind: .text, constraints: [.textLength(min: 1, max: 40)], hints: [], info: Self.propertyInfo(for: \\Self.displayName))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "displayName".uncamelCased, \\.displayName)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(displayName)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(displayName, at: keyPath.appending(\\Self.displayName))
                    try SBJInvariantCheck.requireText(displayName, minLength: 1, maxLength: 40, at: keyPath.appending(\\Self.displayName))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testEditorPropertyGeneratesOnlyEditorField() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                var stored: String

                @SBJEditorProperty
                var image: PlatformImage? {
                    get { nil }
                    set {}
                }
            }
            """,
            expandedSource: """
            struct Model {
                var stored: String
                var image: PlatformImage? {
                    get { nil }
                    set {}
                }

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "stored", displayName: "stored".uncamelCased, keyPath: \\Self.stored, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.stored))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "stored".uncamelCased, \\.stored),
                        SBJEditorField<Self>(editorOnlyName: "image".uncamelCased, \\.image)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(stored)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(stored, at: keyPath.appending(\\Self.stored))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testCustomPublicHooksCanExtendGeneratedUnderscoreBehavior() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                var value: String

                var hasContent: Bool {
                    _hasContent && value != "ignored"
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                    try SBJInvariantCheck.require(value != "reserved", at: keyPath, "reserved")
                }
            }
            """,
            expandedSource: """
            struct Model {
                var value: String

                var hasContent: Bool {
                    _hasContent && value != "ignored"
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                    try SBJInvariantCheck.require(value != "reserved", at: keyPath, "reserved")
                }

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "value", displayName: "value".uncamelCased, keyPath: \\Self.value, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.value))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "value".uncamelCased, \\.value)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(value)
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(value, at: keyPath.appending(\\Self.value))
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testNotEditableStillParticipatesInStructureButNotEditorFields() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                @SBJNotEditable
                let identifier: String
            }
            """,
            expandedSource: """
            struct Model {
                let identifier: String

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "identifier", displayName: "identifier".uncamelCased, keyPath: \\Self.identifier, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.identifier))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [

                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(identifier)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(identifier, at: keyPath.appending(\\Self.identifier))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testUniqueByPreservesTypedKeyPathAndEscapesDescriptiveMetadata() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                @SBJArray(uniqueBy: \\Item.id)
                var items: [Item]
            }
            """,
            expandedSource: """
            struct Model {
                var items: [Item]

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "items", displayName: "items".uncamelCased, keyPath: \\Self.items, kind: .array, constraints: [.uniqueBy("\\\\Item.id")], hints: [.reorderable(true)], info: Self.propertyInfo(for: \\Self.items))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "items".uncamelCased, \\.items)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(items)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(items, at: keyPath.appending(\\Self.items))
                    try SBJInvariantCheck.requireUnique(items, by: \\Item.id, at: keyPath.appending(\\Self.items))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testConflictingArrayUniquenessProducesDiagnostic() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                @SBJArray(unique: true, uniqueBy: \\Item.id)
                var items: [Item]
            }
            """,
            expandedSource: """
            struct Model {
                var items: [Item]

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "items", displayName: "items".uncamelCased, keyPath: \\Self.items, kind: .array, constraints: [.uniqueBy("\\\\Item.id")], hints: [.reorderable(true)], info: Self.propertyInfo(for: \\Self.items))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "items".uncamelCased, \\.items)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(items)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(items, at: keyPath.appending(\\Self.items))
                    try SBJInvariantCheck.requireUnique(items, by: \\Item.id, at: keyPath.appending(\\Self.items))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Array property 'items' cannot declare both unique: true and uniqueBy; choose one uniqueness rule",
                    line: 4,
                    column: 9
                )
            ],
            macros: macros
        )
    }

    func testImmutableEditablePropertyProducesWarning() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                let identifier: String
            }
            """,
            expandedSource: """
            struct Model {
                let identifier: String

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "identifier", displayName: "identifier".uncamelCased, keyPath: \\Self.identifier, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.identifier))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [

                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(identifier)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(identifier, at: keyPath.appending(\\Self.identifier))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Immutable property 'identifier' cannot be edited; make it var or mark it @SBJNotEditable",
                    line: 3,
                    column: 9,
                    severity: .warning
                )
            ],
            macros: macros
        )
    }
    func testCodingKeysDefineMembershipAndUnannotatedTypesInferKinds() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                var name: String
                var website: URL
                var ignored: Int

                enum CodingKeys: String, CodingKey {
                    case name
                    case website
                }
            }
            """,
            expandedSource: """
            struct Model {
                var name: String
                var website: URL
                var ignored: Int

                enum CodingKeys: String, CodingKey {
                    case name
                    case website
                }

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "name", displayName: "name".uncamelCased, keyPath: \\Self.name, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.name)),
                        SBJPropertyMetadata<Self>(sourceName: "website", displayName: "website".uncamelCased, keyPath: \\Self.website, kind: .url, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.website))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "name".uncamelCased, \\.name),
                        SBJEditorField<Self>(name: "website".uncamelCased, \\.website)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(name) ||
                    SBJContentCheck.hasContent(website)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(name, at: keyPath.appending(\\Self.name))
                    try SBJInvariantCheck.validate(website, at: keyPath.appending(\\Self.website))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testScalarAnnotationsAddRulesAndHintsRatherThanMembership() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                @SBJUUID(nonzero: true)
                var identifier: UUID
                @SBJDate(range: Date.distantPast ... Date.distantFuture)
                var created: Date
                @SBJColor(alpha: false)
                var color: CodableColor
            }
            """,
            expandedSource: """
            struct Model {
                var identifier: UUID
                var created: Date
                var color: CodableColor

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "identifier", displayName: "identifier".uncamelCased, keyPath: \\Self.identifier, kind: .uuid, constraints: [.uuidNonzero], hints: [], info: Self.propertyInfo(for: \\Self.identifier)),
                        SBJPropertyMetadata<Self>(sourceName: "created", displayName: "created".uncamelCased, keyPath: \\Self.created, kind: .date, constraints: [.dateRange(Date.distantPast ... Date.distantFuture)], hints: [], info: Self.propertyInfo(for: \\Self.created)),
                        SBJPropertyMetadata<Self>(sourceName: "color", displayName: "color".uncamelCased, keyPath: \\Self.color, kind: .color, constraints: [], hints: [.colorSupportsAlpha(false)], info: Self.propertyInfo(for: \\Self.color))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "identifier".uncamelCased, \\.identifier),
                        SBJEditorField<Self>(name: "created".uncamelCased, \\.created),
                        SBJEditorField<Self>(name: "color".uncamelCased, \\.color)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(identifier) ||
                    SBJContentCheck.hasContent(created) ||
                    SBJContentCheck.hasContent(color)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(identifier, at: keyPath.appending(\\Self.identifier))
                    try SBJInvariantCheck.requireNonzero(identifier, at: keyPath.appending(\\Self.identifier))
                    try SBJInvariantCheck.validate(created, at: keyPath.appending(\\Self.created))
                    try SBJInvariantCheck.requireRange(created, Date.distantPast ... Date.distantFuture, at: keyPath.appending(\\Self.created))
                    try SBJInvariantCheck.validate(color, at: keyPath.appending(\\Self.color))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testCodableStructWithDefaultableInitializationSynthesizesDefaultValue() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Defaultable: Codable {
                var name: String = ""
            }
            """,
            expandedSource: """
            struct Defaultable: Codable {
                var name: String = ""

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "name", displayName: "name".uncamelCased, keyPath: \\Self.name, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.name))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "name".uncamelCased, \\.name)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(name)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(name, at: keyPath.appending(\\Self.name))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }

                static func sbjDefaultValue() -> Self? {
                    .init()
                }
            }

            extension Defaultable: SBJEditable {
            }
            """,
            macros: macros
        )
    }


    func testInheritedCodableProtocolStillSynthesizesDefaultValue() {
        assertMacroExpansion(
            """
            protocol ModelCodable: Codable {}

            @SBJStructure
            struct Model: ModelCodable {
                var name = ""
            }
            """,
            expandedSource: """
            protocol ModelCodable: Codable {}

            struct Model: ModelCodable {
                var name = ""

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "name", displayName: "name".uncamelCased, keyPath: \\Self.name, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.name))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "name".uncamelCased, \\.name)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(name)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(name, at: keyPath.appending(\\Self.name))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }

                static func sbjDefaultValue() -> Self? {
                    .init()
                }
            }

            extension Model: SBJEditable {
            }
            """,
            macros: macros
        )
    }

    func testAnnotationTypeMismatchProducesDiagnostic() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                @SBJData
                var payload: String
            }
            """,
            expandedSource: """
            struct Model {
                var payload: String

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "payload", displayName: "payload".uncamelCased, keyPath: \\Self.payload, kind: .text, constraints: [], hints: [], info: Self.propertyInfo(for: \\Self.payload))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "payload".uncamelCased, \\.payload)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(payload)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(payload, at: keyPath.appending(\\Self.payload))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@SBJData on property 'payload' requires Data or Data?; found 'String'",
                    line: 4,
                    column: 9,
                    severity: .error
                )
            ],
            macros: macros
        )
    }

    func testInvalidDataDeclarationProducesDiagnostics() {
        assertMacroExpansion(
            """
            @SBJStructure
            struct Model {
                @SBJData(min: 8, max: 4, modulo: 0)
                var payload: Data
            }
            """,
            expandedSource: """
            struct Model {
                var payload: Data

                static var sbjProperties: [SBJPropertyMetadata<Self>] {
                    [
                        SBJPropertyMetadata<Self>(sourceName: "payload", displayName: "payload".uncamelCased, keyPath: \\Self.payload, kind: .data, constraints: [.dataSize(min: 8, max: 4, modulo: 0)], hints: [], info: Self.propertyInfo(for: \\Self.payload))
                    ]
                }

                @MainActor
                static var sbjEditorFields: [SBJEditorField<Self>] {
                    [
                        SBJEditorField<Self>(name: "payload".uncamelCased, \\.payload)
                    ]
                }

                var _hasContent: Bool {
                    SBJContentCheck.hasContent(payload)
                }

                var hasContent: Bool {
                    _hasContent
                }

                func _invariant(at keyPath: SBJValidationKeyPath) throws {
                    try SBJInvariantCheck.validate(payload, at: keyPath.appending(\\Self.payload))
                    try SBJInvariantCheck.requireData(payload, min: 8, max: 4, modulo: 0, at: keyPath.appending(\\Self.payload))
                }

                func invariant(at keyPath: SBJValidationKeyPath) throws {
                    try _invariant(at: keyPath)
                }
            }

            extension Model: SBJEditable {
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "@SBJData on property 'payload' minimum cannot exceed maximum", line: 4, column: 9, severity: .error),
                DiagnosticSpec(message: "@SBJData on property 'payload' modulo must be greater than zero", line: 4, column: 9, severity: .error)
            ],
            macros: macros
        )
    }

}
