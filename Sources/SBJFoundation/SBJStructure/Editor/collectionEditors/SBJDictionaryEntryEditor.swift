import Foundation
import SwiftUI

struct SBJDictionaryEntryEditor<Key: Codable & Hashable, Value: Codable>: View {
    let key: Key
    @Binding var entryValue: Value
    let originalValue: Value?
    let entryIsChanged: Bool
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let context: SBJEditTraversalContext
    let rename: (Key, Key) -> Bool
    let remove: () -> Void
    @State private var draftKey: Key
    @State private var collision = false

    init(
        key: Key,
        entryValue: Binding<Value>,
        originalValue: Value?,
        entryIsChanged: Bool,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        focusRequest: SBJEditorFocusRequest?,
        context: SBJEditTraversalContext,
        rename: @escaping (Key, Key) -> Bool,
        remove: @escaping () -> Void
    ) {
        self.key = key
        _entryValue = entryValue
        self.originalValue = originalValue
        self.entryIsChanged = entryIsChanged
        self.registry = registry
        self.textStyle = textStyle
        self.integerRange = integerRange
        self.numberRange = numberRange
        self.focusRequest = focusRequest
        self.context = context
        self.rename = rename
        self.remove = remove
        _draftKey = State(initialValue: key)
    }

    private var isInvalid: Bool {
        SBJInvariantCheck.validationError(
            entryValue,
            at: SBJValidationKeyPath(\Value.self)
        ) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 8) {
                Button(action: remove) {
                    Image(SBJEditorImageName.remove)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove dictionary entry")

                SBJValueEditor.makeView(
                    label: "Key",
                    value: $draftKey,
                    registry: registry,
                    focusRequest: focusRequest,
                    context: context
                )

                if draftKey != key {
                    Button {
                        collision = !rename(key, draftKey)
                    } label: {
                        Image(SBJEditorImageName.apply)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Apply dictionary key")
                }
            }

            if collision {
                Text("That key already exists.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SBJValueEditor.makeView(
                label: String(describing: key),
                value: $entryValue,
                originalValue: originalValue.map { SBJEditorOriginalValue($0) },
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange,
                context: context
            )
            .frame(maxWidth: .infinity)
        }
        .environment(\.sbjEditorIsChanged, entryIsChanged)
        .environment(\.sbjEditorHasContent, (entryValue as? any HasContentCheckable)?.hasContent)
        .environment(\.sbjEditorIsInvalid, isInvalid)
        .onChange(of: key) { _, newValue in
            draftKey = newValue
            collision = false
        }
        .onChange(of: draftKey) { _, _ in collision = false }
    }
}

