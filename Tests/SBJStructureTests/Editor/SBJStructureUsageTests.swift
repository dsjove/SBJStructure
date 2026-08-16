import Foundation
import Testing
@testable import SBJStructure

@SBJStructure
private struct TestNestedValue: Codable {
    var note: String = ""
}

@SBJStructure
private struct TestEditableValue: Codable {
    var name: String = ""
    var level: Int = 1
    var nested = TestNestedValue()
    var notes: [String] = []
    var nickname: String?
    @SBJNotEditable var transientState: String = ""
    let immutableIdentifier: Int = 7

    enum CodingKeys: String, CodingKey {
        case name
        case level
        case nested
        case notes
        case nickname
        case transientState
    }
}

struct SBJStructureUsageTests {
    @Test func generatesStructuralMetadataFromCodedStoredProperties() {
        #expect(TestEditableValue.sbjProperties.map(\.sourceName) == [
            "name", "level", "nested", "notes", "nickname", "transientState"
        ])
        #expect(TestEditableValue.sbjProperties.map(\.displayName) == [
            "Name", "Level", "Nested", "Notes", "Nickname", "Transient State"
        ])
    }

    @MainActor
    @Test func generatesFieldsFromCodedMutableProperties() {
        #expect(TestEditableValue.sbjEditorFields.map(\.name) == [
            "Name", "Level", "Nested", "Notes", "Nickname"
        ])
    }
}

@SBJStructure
private enum TestAssociatedEnum: Codable {
    case automatic
    case adjusted(amount: Int, enabled: Bool)
    case fixed(Int)
}

extension SBJStructureUsageTests {
    @MainActor
    @Test func generatesAssociatedEnumCasesAndFields() {
        let cases = TestAssociatedEnum.sbjEditorEnumCases
        #expect(cases.map(\.name) == ["Automatic", "Adjusted", "Fixed"])
        #expect(cases[0].associatedValues.isEmpty)
        #expect(cases[1].associatedValues.map(\.name) == ["Amount", "Enabled"])
        #expect(cases[2].associatedValues.map(\.name) == ["Value"])

        let created = TestAssociatedEnum.sbjCreateEditorValue()
        if case .automatic = created {
            // expected
        } else {
            Issue.record("Expected the first enum case to be the generated default")
        }
    }
}

@SBJStructure
private struct TestContentLeaf: Codable {
    var text: String = ""
}

private enum TestPlainScalarEnum: Codable {
    case first
    case second
}

@SBJStructure
private struct TestGeneratedContent: Codable {
    var scalar: Int = 1
    var text: String = ""
    var optionalText: String?
    var nested = TestContentLeaf()
    var nestedItems: [TestContentLeaf] = []
}

extension SBJStructureUsageTests {
    @Test func generatedHasContentIgnoresDirectNonCheckableScalars() {
        #expect(!TestGeneratedContent().hasContent)
        #expect(!TestGeneratedContent(scalar: 99).hasContent)
        #expect(TestGeneratedContent(text: "x").hasContent)
        #expect(!TestGeneratedContent(optionalText: "").hasContent)
        #expect(TestGeneratedContent(optionalText: "x").hasContent)
        #expect(TestGeneratedContent(nested: TestContentLeaf(text: "x")).hasContent)
        #expect(!TestGeneratedContent(nestedItems: [TestContentLeaf()]).hasContent)
        #expect(TestGeneratedContent(nestedItems: [TestContentLeaf(text: "x")]).hasContent)
    }

    @Test func contentCheckKeepsScalarEditorContentStateNeutral() {
        #expect(!SBJContentCheck.hasContent(0))
        #expect(!SBJContentCheck.hasContent(99))
        #expect(!SBJContentCheck.hasContent(false))
        #expect(!SBJContentCheck.hasContent(TestPlainScalarEnum.first))
        #expect(((0 as Any) as? any HasContentCheckable) == nil)
        #expect(((false as Any) as? any HasContentCheckable) == nil)
        #expect(((TestPlainScalarEnum.first as Any) as? any HasContentCheckable) == nil)
    }

    @Test func presenceBearingContainersStillCountNonCheckableScalars() {
        let noInteger: Int? = nil
        let integer: Int? = 0

        #expect(!SBJContentCheck.hasContent(noInteger))
        #expect(SBJContentCheck.hasContent(integer))
        #expect(!SBJContentCheck.hasContent([Int]()))
        #expect(SBJContentCheck.hasContent([0]))
    }
}

@SBJStructure
private struct TestValidatedValue: Codable {
    @SBJInteger(range: 1...20)
    var level: Int = 1

    @SBJInteger(min: 0)
    var count: Int = 0

    @SBJText(minLength: 2, maxLength: 5)
    var code: String = "ok"

    @SBJNotEditable
    @SBJText(minLength: 2)
    var hiddenCode: String = "ok"

    @SBJArray(minCount: 1, maxCount: 2)
    var names: [String] = ["one"]

    @SBJOptional(required: true)
    var nickname: String? = "x"

    @SBJNumber(range: 0.0...1.0)
    var ratio: Double = 0.5
}

extension SBJStructureUsageTests {
    @Test func generatedMetadataDescribesDeclaredBusinessRules() {
        let level = TestValidatedValue.propertyMetadata(for: \TestValidatedValue.level)
        #expect(level?.kind == .integer)
        #expect(level?.constraints == [.integerRange(1...20)])

        let code = TestValidatedValue.propertyMetadata(for: \TestValidatedValue.code)
        #expect(code?.kind == .text)
        #expect(code?.constraints == [.textLength(min: 2, max: 5)])

        let nickname = TestValidatedValue.propertyMetadata(for: \TestValidatedValue.nickname)
        #expect(nickname?.kind == .optional)
        #expect(nickname?.constraints == [.required(true)])

        let names = TestValidatedValue.propertyMetadata(for: \TestValidatedValue.names)
        #expect(names?.kind == .array)
        #expect(names?.constraints == [.count(min: 1, max: 2)])
    }

    @Test func generatedInvariantUsesDeclaredBusinessRules() throws {
        try TestValidatedValue().invariant(at: \TestValidatedValue.self)

        #expect(throws: SBJValidationError.self) {
            try TestValidatedValue(level: 21).invariant(at: \TestValidatedValue.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestValidatedValue(count: -1).invariant(at: \TestValidatedValue.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestValidatedValue(code: "x").invariant(at: \TestValidatedValue.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestValidatedValue(hiddenCode: "x").invariant(at: \TestValidatedValue.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestValidatedValue(names: []).invariant(at: \TestValidatedValue.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestValidatedValue(nickname: nil).invariant(at: \TestValidatedValue.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestValidatedValue(ratio: 2).invariant(at: \TestValidatedValue.self)
        }
    }
}

@SBJStructure
private struct TestDocumentedValue: Codable {
    var name: String = ""

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        guard (keyPath as AnyKeyPath) == \Self.name else { return nil }
        return SBJPropertyInfo(
            title: "Display Name",
            summary: "A short name.",
            details: "Used to identify the value in user interfaces.",
            accessibilityLabel: "Name field",
            accessibilityHint: "Enter a short name",
            accessibilityValue: "Current name"
        )
    }
}

extension SBJStructureUsageTests {
    @Test func structuralMetadataCarriesReusablePropertyInfo() {
        let property = TestDocumentedValue.propertyMetadata(for: \TestDocumentedValue.name)
        #expect(property?.sourceName == "name")
        #expect(property?.info?.title == "Display Name")
        #expect(property?.info?.accessibilityLabel == "Name field")
        #expect(property?.info?.accessibilityHint == "Enter a short name")
        #expect(property?.info?.accessibilityValue == "Current name")
    }

    @Test func annotationsDoNotEnforceOnAssignmentOrAccess() throws {
        var value = TestValidatedValue()
        value.level = 99
        value.code = "x"
        value.names = []
        value.nickname = nil

        #expect(value.level == 99)
        #expect(value.code == "x")
        #expect(value.names.isEmpty)
        #expect(value.nickname == nil)

        #expect(throws: SBJValidationError.self) {
            try value.invariant(at: \TestValidatedValue.self)
        }
    }
}


private struct TestUniqueItem: Codable, Hashable {
    var id: Int
    var name: String
}

@SBJStructure
private struct TestCollectionRules: Codable {
    @SBJArray(unique: true)
    var tags: [String] = []

    @SBJArray(uniqueBy: \TestUniqueItem.id)
    var items: [TestUniqueItem] = []
}

extension SBJStructureUsageTests {
    @Test func arrayUniquenessRulesAreGeneratedAndDescribed() throws {
        let tags = TestCollectionRules.propertyMetadata(for: \TestCollectionRules.tags)
        #expect(tags?.constraints == [.unique])

        let items = TestCollectionRules.propertyMetadata(for: \TestCollectionRules.items)
        #expect(items?.constraints == [.uniqueBy("\\TestUniqueItem.id")])

        try TestCollectionRules(
            tags: ["a", "b"],
            items: [
                TestUniqueItem(id: 1, name: "one"),
                TestUniqueItem(id: 2, name: "two"),
            ]
        ).invariant(at: \TestCollectionRules.self)

        #expect(throws: SBJValidationError.self) {
            try TestCollectionRules(tags: ["a", "a"]).invariant(at: \TestCollectionRules.self)
        }

        #expect(throws: SBJValidationError.self) {
            try TestCollectionRules(items: [
                TestUniqueItem(id: 1, name: "one"),
                TestUniqueItem(id: 1, name: "another"),
            ]).invariant(at: \TestCollectionRules.self)
        }
    }

    @Test func uniqueByReportsTheDuplicateArrayPosition() {
        let values = [
            TestUniqueItem(id: 1, name: "one"),
            TestUniqueItem(id: 1, name: "two"),
        ]
        let path = SBJValidationKeyPath(\TestCollectionRules.items)

        do {
            try SBJInvariantCheck.requireUnique(values, by: \TestUniqueItem.id, at: path)
            Issue.record("Expected duplicate key validation to fail")
        } catch let error as SBJValidationError {
            #expect(error.keyPath.description.hasSuffix("[1]"))
        } catch {
            Issue.record("Expected SBJValidationError")
        }
    }
}

@SBJStructure
private struct TestInvalidNestedValue: Codable, Hashable {
    @SBJText(minLength: 2)
    var code: String = "ok"
}

@SBJStructure
private struct TestValidationContainers: Codable {
    var keyed: [String: TestInvalidNestedValue] = [:]
    var members: Set<TestInvalidNestedValue> = []
}

extension SBJStructureUsageTests {
    @Test func nestedDictionaryValidationRetainsTheDictionaryKey() {
        let value = TestValidationContainers(
            keyed: ["bad": TestInvalidNestedValue(code: "x")]
        )

        do {
            try value.invariant(at: \TestValidationContainers.self)
            Issue.record("Expected nested dictionary validation to fail")
        } catch let error as SBJValidationError {
            #expect(error.keyPath.description.contains("bad"))
            #expect(error.keyPath.contains(property: \TestValidationContainers.keyed))
        } catch {
            Issue.record("Expected SBJValidationError")
        }
    }

    @Test func nestedSetValidationIdentifiesTheMember() {
        let invalid = TestInvalidNestedValue(code: "x")
        let value = TestValidationContainers(members: [invalid])

        do {
            try value.invariant(at: \TestValidationContainers.self)
            Issue.record("Expected nested set validation to fail")
        } catch let error as SBJValidationError {
            #expect(error.keyPath.description.contains("TestInvalidNestedValue"))
            #expect(error.keyPath.contains(property: \TestValidationContainers.members))
        } catch {
            Issue.record("Expected SBJValidationError")
        }
    }

    @Test func countValidationWorksAcrossCollectionTypes() throws {
        let setPath = SBJValidationKeyPath(\TestValidationContainers.members)
        try SBJInvariantCheck.requireCount(Set([1, 2]), minCount: 1, maxCount: 2, at: setPath)
        #expect(throws: SBJValidationError.self) {
            try SBJInvariantCheck.requireCount(Set<Int>(), minCount: 1, maxCount: nil, at: setPath)
        }

        let dictionaryPath = SBJValidationKeyPath(\TestValidationContainers.keyed)
        try SBJInvariantCheck.requireCount(["one": 1], minCount: nil, maxCount: 1, at: dictionaryPath)
        #expect(throws: SBJValidationError.self) {
            try SBJInvariantCheck.requireCount(["one": 1, "two": 2], minCount: nil, maxCount: 1, at: dictionaryPath)
        }
    }
}

extension SBJStructureUsageTests {
    @Test func dataByteConstraintsAreCentralized() throws {
        let path = SBJValidationKeyPath(\TestDataConstraintHolder.payload)

        try SBJInvariantCheck.requireData(Data(repeating: 0, count: 8), min: 4, max: 12, modulo: 4, at: path)

        #expect(throws: SBJValidationError.self) {
            try SBJInvariantCheck.requireData(Data(repeating: 0, count: 2), min: 4, at: path)
        }
        #expect(throws: SBJValidationError.self) {
            try SBJInvariantCheck.requireData(Data(repeating: 0, count: 16), max: 12, at: path)
        }
        #expect(throws: SBJValidationError.self) {
            try SBJInvariantCheck.requireData(Data(repeating: 0, count: 6), modulo: 4, at: path)
        }
    }
}

private struct TestDataConstraintHolder {
    var payload = Data()
}

@SBJStructure
private struct TestPhase4Collections: Codable {
    @SBJArray(reorderable: false, title: \TestUniqueItem.name, minCount: 1, maxCount: 3, uniqueBy: \TestUniqueItem.id)
    var items: [TestUniqueItem] = [TestUniqueItem(id: 1, name: "one")]

    @SBJSet(title: \TestUniqueItem.name, minCount: 1, maxCount: 2)
    var members: Set<TestUniqueItem> = [TestUniqueItem(id: 1, name: "one")]

    @SBJDictionary(minCount: 1, maxCount: 2)
    var labels: [String: Int] = ["one": 1]
}

extension SBJStructureUsageTests {
    @Test func phase4CollectionAnnotationsGenerateKindsRulesAndHints() {
        let items = TestPhase4Collections.propertyMetadata(for: \TestPhase4Collections.items)
        #expect(items?.kind == .array)
        #expect(items?.constraints == [
            .count(min: 1, max: 3),
            .uniqueBy("\\TestUniqueItem.id"),
        ])
        #expect(items?.hints == [
            .reorderable(false),
            .itemTitle("name"),
        ])

        let members = TestPhase4Collections.propertyMetadata(for: \TestPhase4Collections.members)
        #expect(members?.kind == .set)
        #expect(members?.constraints == [.count(min: 1, max: 2)])
        #expect(members?.hints == [.itemTitle("name")])

        let labels = TestPhase4Collections.propertyMetadata(for: \TestPhase4Collections.labels)
        #expect(labels?.kind == .dictionary)
        #expect(labels?.constraints == [.count(min: 1, max: 2)])
        #expect(labels?.hints.isEmpty == true)
    }

    @Test func phase4SetAndDictionaryCountsParticipateInExplicitInvariant() throws {
        try TestPhase4Collections().invariant(at: \TestPhase4Collections.self)

        #expect(throws: SBJValidationError.self) {
            try TestPhase4Collections(members: []).invariant(at: \TestPhase4Collections.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestPhase4Collections(labels: [:]).invariant(at: \TestPhase4Collections.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestPhase4Collections(
                labels: ["one": 1, "two": 2, "three": 3]
            ).invariant(at: \TestPhase4Collections.self)
        }
    }

    @Test func setReplacementRejectsCollisionsWithoutChangingCollection() {
        var values: Set<String> = ["one", "two"]
        let collisionRejected = !values.sbjReplace("one", with: "two")
        #expect(collisionRejected)
        #expect(values == ["one", "two"])

        let replacementSucceeded = values.sbjReplace("one", with: "three")
        #expect(replacementSucceeded)
        #expect(values == ["two", "three"])
    }

    @Test func dictionaryRenameRejectsCollisionsAndPreservesValues() {
        var values = ["one": 1, "two": 2]
        let collisionRejected = !values.sbjRenameKey("one", to: "two")
        #expect(collisionRejected)
        #expect(values == ["one": 1, "two": 2])

        let renameSucceeded = values.sbjRenameKey("one", to: "three")
        #expect(renameSucceeded)
        #expect(values == ["three": 1, "two": 2])
    }

    @MainActor
    @Test func setAndDictionaryPresentationIsDeterministicForNaturalScalarTypes() {
        #expect(SBJValueEditor.deterministicallySorted(Set(["10", "2", "1"])) == ["1", "2", "10"])
        #expect(SBJValueEditor.deterministicallySorted(Set([3, 1, 2])) == [1, 2, 3])

        let dictionary = ["10": 10, "2": 2, "1": 1]
        #expect(SBJValueEditor.deterministicallySortedDictionary(dictionary).map(\.0) == ["1", "2", "10"])
    }
}

@SBJStructure
private struct TestScalarAnnotations: Codable {
    var url = URL(string: "https://example.com")!
    @SBJUUID(nonzero: true) var uuid = UUID()
    @SBJDate(range: Date(timeIntervalSince1970: 0)...Date(timeIntervalSince1970: 100)) var date = Date(timeIntervalSince1970: 0)
    @SBJData(min: 4, max: 8, modulo: 4) var data = Data([0, 1, 2, 3])
    @SBJColor(alpha: false) var color = CodableColor(1, 0, 0)
}

extension SBJStructureUsageTests {
    @Test func scalarAnnotationsProduceStructuralKindsAndDataRules() throws {
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.url)?.kind == .url)
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.uuid)?.kind == .uuid)
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.date)?.kind == .date)
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.color)?.kind == .color)
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.data)?.constraints == [
            .dataSize(min: 4, max: 8, modulo: 4)
        ])
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.uuid)?.constraints == [.uuidNonzero])
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.date)?.constraints == [
            .dateRange(Date(timeIntervalSince1970: 0)...Date(timeIntervalSince1970: 100))
        ])
        #expect(TestScalarAnnotations.propertyMetadata(for: \TestScalarAnnotations.color)?.hints == [.colorSupportsAlpha(false)])

        try TestScalarAnnotations().invariant(at: \TestScalarAnnotations.self)
        #expect(throws: SBJValidationError.self) {
            try TestScalarAnnotations(data: Data([0, 1, 2])).invariant(at: \TestScalarAnnotations.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestScalarAnnotations(data: Data(repeating: 0, count: 12)).invariant(at: \TestScalarAnnotations.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestScalarAnnotations(uuid: .sbjZero).invariant(at: \TestScalarAnnotations.self)
        }
        #expect(throws: SBJValidationError.self) {
            try TestScalarAnnotations(date: Date(timeIntervalSince1970: 101)).invariant(at: \TestScalarAnnotations.self)
        }
    }

    @Test func hexEditingFormatRoundTripsAndRejectsIncompleteBytes() throws {
        let data = Data([0x01, 0x23, 0xAB, 0xCD])
        let text = data.sbjHexFormat(bytesPerRow: 2)
        #expect(text == "01 23\nAB CD")
        #expect(try text.sbjHexData() == data)
        #expect(try "01.23 AB-CD".sbjHexData() == data)
        #expect(throws: SBJHexError.incompleteByte) {
            try "ABC".sbjHexData()
        }
    }
}

@SBJStructure
private struct TestPhase6MetadataDrivenEditor: Codable {
    @SBJText(.multiline, minLength: 2, maxLength: 20)
    var notes: String = "ok"

    @SBJInteger(range: 1...9)
    var count: Int = 1
}

extension SBJStructureUsageTests {
    @Test func phase6PresentationAndConstraintsAreAvailableThroughStructuralMetadata() {
        let notes = TestPhase6MetadataDrivenEditor.propertyMetadata(for: \TestPhase6MetadataDrivenEditor.notes)
        #expect(notes?.hints == [.textStyle(.multiline)])
        #expect(notes?.constraints == [.textLength(min: 2, max: 20)])

        let count = TestPhase6MetadataDrivenEditor.propertyMetadata(for: \TestPhase6MetadataDrivenEditor.count)
        #expect(count?.constraints == [.integerRange(1...9)])
    }
}
