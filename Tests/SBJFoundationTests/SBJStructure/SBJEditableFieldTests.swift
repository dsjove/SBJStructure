import Testing
@testable import SBJFoundation

@SBJStructure
private struct EditableFieldModel: Codable {
    var title: String
    var count: Int

    @SBJEditorProperty
    var summary: String {
        get { "\(title): \(count)" }
        set { title = newValue }
    }
}

struct SBJEditableFieldTests {
    @Test func generatedEditableFieldsAreUIIndependentAndWritable() {
        let fields = EditableFieldModel.sbjEditableFields
        #expect(fields.map(\.name) == ["Title", "Count", "Summary"])

        var value = EditableFieldModel(title: "Before", count: 2)
        let title = fields[0]

        #expect(title.value(in: value) as? String == "Before")
        #expect(title.setValue("After", in: &value))
        #expect(value.title == "After")
        #expect(!title.setValue(42, in: &value))
    }

    @Test func generatedEditableFieldCarriesStructuralMetadata() {
        let fields = EditableFieldModel.sbjEditableFields

        #expect(fields[0].structuralMetadata?.sourceName == "title")
        #expect(fields[1].structuralMetadata?.sourceName == "count")
        #expect(fields[2].structuralMetadata == nil)
        #expect(fields[0].participatesInStructuralValidation)
        #expect(!fields[2].participatesInStructuralValidation)
    }

    @Test func generatedEditableFieldProvidesSharedSearchAndChangeSemantics() {
        let field = EditableFieldModel.sbjEditableFields[0]
        let original = EditableFieldModel(title: "Original", count: 2)
        let changed = EditableFieldModel(title: "Changed", count: 2)

        #expect(field.matchesSearch(in: changed, query: "changed"))
        #expect(!field.hasChanged(in: original, from: original))
        #expect(field.hasChanged(in: changed, from: original))
    }
}
