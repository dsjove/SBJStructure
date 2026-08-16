#if DEBUG
import SwiftUI

private enum SBJEditorPreviewChoice: String, Codable, CaseIterable, Hashable {
    case firstChoice
    case secondChoice
    case thirdChoice
}

@SBJStructure
private enum SBJEditorPreviewAssociatedEnum: Codable {
    case automatic
    case adjusted(amount: Int, enabled: Bool)
    case fixed(Int)
}

private struct SBJEditorPreviewCustom: Codable, Equatable {
    var value: String
}

private protocol SBJEditorPreviewCodable: Codable {}

@SBJStructure
private struct SBJEditorPreviewSingle: SBJEditorPreviewCodable {
    var amount: Int = 0
}

@SBJStructure
private struct SBJEditorPreviewNested: Codable {
    var title: String
    var enabled: Bool
    var single: SBJEditorPreviewSingle
}


private enum SBJEditorPreviewSlotKind: String, Codable, CaseIterable, Hashable {
    case primary
    case secondary
    case utility
}

@SBJStructure
private struct SBJEditorPreviewSlot: Codable, Hashable {
    var kind: SBJEditorPreviewSlotKind = .primary
    var note: String = ""
}

extension SBJEditorPreviewSlot: SBJCollectionElementCreatable {
    static func sbjCreateValue(existing: [Self]) -> Self? {
        let used = Set(existing.map(\.kind))
        guard let kind = SBJEditorPreviewSlotKind.allCases.first(where: { !used.contains($0) }) else { return nil }
        return .init(kind: kind)
    }
}

@SBJStructure
private struct SBJEditorPreviewItem: Codable, Hashable {
    var id = UUID()
    var name = "New Item"
    var quantity = 1
    var note: String? = nil
}

@SBJStructure
private struct SBJEditorPreviewModel: Codable {
    @SBJText(minLength: 1, maxLength: 30)
    var name = "Preview"

    @SBJText(.multiline, minLength: 1, maxLength: 400)
    var notes = "Multiline text\nshows the text editor."

    @SBJInteger(range: 0...20)
    var count = 21

    @SBJNumber(range: 0.0...10.0)
    var ratio = 1.5

    var floatValue: Float = 2.5
    var decimalValue: Decimal = 12.75
    var unsignedValue: UInt16 = 42
    var enabled = true
    // Plain CaseIterable + Hashable enums need no SBJ editor protocol.
    var choice: SBJEditorPreviewChoice = .secondChoice
    var optionalChoice: SBJEditorPreviewChoice?

    @SBJDate(range: Date(timeIntervalSince1970: 0)...Date(timeIntervalSince1970: 4_102_444_800))
    var timestamp = Date()

    @SBJDate(range: Date(timeIntervalSince1970: 0)...Date(timeIntervalSince1970: 4_102_444_800))
    var optionalTimestamp: Date? = Date()

    // No annotation is needed merely to participate or select the smart URL editor.
    var documentationURL = URL(string: "https://www.swift.org")!

    @SBJUUID(nonzero: true)
    var identifier = UUID()

    @SBJData(min: 4, max: 32, modulo: 4)
    var payload = Data([0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])

    @SBJColor(alpha: false)
    var accent = CodableColor(0.15, 0.45, 0.9, 1.0)

    @SBJColor(alpha: false)
    var optionalAccent: CodableColor? = CodableColor(0.8, 0.2, 0.3, 1.0)

    var nested = SBJEditorPreviewNested(title: "Nested", enabled: true, single: .init(amount: 7))
    // The + control uses @SBJStructure-generated sbjDefaultValue(); Codable arrives through the preview protocol tree.
    var optionalNested: SBJEditorPreviewSingle?

    @SBJOptional(required: true)
    var optionalText: String? = "Required optional value"
    var nilText: String?

    @SBJArray(
        reorderable: true,
        title: \SBJEditorPreviewItem.name,
        minCount: 1,
        maxCount: 6,
        uniqueBy: \SBJEditorPreviewItem.id
    )
    var reorderableItems = [
        SBJEditorPreviewItem(id: UUID(), name: "Beta", quantity: 2, note: nil),
        SBJEditorPreviewItem(id: UUID(), name: "Alpha", quantity: 1, note: "Optional note")
    ]

    @SBJArray(reorderable: false, title: \SBJEditorPreviewItem.name)
    var fixedOrderItems = [
        SBJEditorPreviewItem(id: UUID(), name: "First", quantity: 1, note: nil),
        SBJEditorPreviewItem(id: UUID(), name: "Second", quantity: 1, note: nil)
    ]

    @SBJArray(
        title: \SBJEditorPreviewSlot.kind,
        uniqueBy: \SBJEditorPreviewSlot.kind
    )
    var contextualSlots = [SBJEditorPreviewSlot(kind: .primary, note: "Collection-aware + chooses the next unused kind")]

    @SBJSet(minCount: 1, maxCount: 6)
    var tags: Set<String> = ["Arcane", "Melee", "Utility"]

    @SBJDictionary(minCount: 1, maxCount: 6)
    var modifiers: [String: Int] = ["Strength": 2, "Dexterity": 1]

    var custom = SBJEditorPreviewCustom(value: "Registered custom editor")
    var associatedEnum: SBJEditorPreviewAssociatedEnum = .adjusted(amount: 12, enabled: true)

    @SBJNotEditable
    var hiddenFromEditor = "Still structural; not shown in editor"

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        switch keyPath as AnyKeyPath {
        case \Self.name:
            return SBJPropertyInfo(
                title: "Preview Name",
                summary: "Demonstrates reusable property documentation.",
                details: "SBJPropertyInfo is structural metadata and can be consumed by the editor or another UI.",
                accessibilityLabel: "Preview name",
                accessibilityHint: "Enter the display name for this preview model",
                accessibilityValue: "The current preview name"
            )
        case \Self.payload:
            return SBJPropertyInfo(
                summary: "Binary payload displayed as editable hexadecimal.",
                details: "This field declares a byte count of 4 through 32 bytes and a modulo of 4.",
                accessibilityValue: "Eight byte sample payload"
            )
        default:
            return nil
        }
    }
}

@MainActor
private struct SBJStructuredEditorPreviewHost: View {
    @State private var value = SBJEditorPreviewModel()

    private var registry: SBJEditorRegistry {
        var registry = SBJEditorRegistry()
        registry.register(SBJEditorPreviewCustom.self) { label, binding, _ in
            HStack(spacing: 8) {
                Text(label)
                TextField("", text: Binding(
                    get: { binding.wrappedValue.value },
                    set: { binding.wrappedValue.value = $0 }
                ))
                .textFieldStyle(.roundedBorder)
            }
        }
        return registry
    }

    var body: some View {
        Form {
            Section("SBJStructure Feature Preview") {
                Text("CodingKeys define the structure. Property annotations add rules or usage information; ordinary coded properties need no annotation. The intentionally out-of-range Count demonstrates owner-level validation in Editor Issues. Optional Date/Color fields demonstrate scalar metadata propagation. Plain CaseIterable enums need no editor protocol, defaultable @SBJStructure values are created automatically, and contextual collection creation uses SBJCollectionElementCreatable.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            SBJCodableEditorCore(value: $value, registry: registry)
        }
    }
}

#Preview("All SBJStructure Features") {
    SBJStructuredEditorPreviewHost()
        .padding(24)
        .frame(minWidth: 760, minHeight: 1200)
}
#endif
