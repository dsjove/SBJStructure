import Foundation
import SwiftUI

struct SBJDictionaryEditor<Key: Codable & Hashable, Value: Codable>: View {
    private struct DisplayEntry: Identifiable {
        let key: Key
        let value: Value
        var id: Key { key }
    }
    let label: String
    @Binding var value: [Key: Value]
    let originalValue: [Key: Value]?
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    let context: SBJEditTraversalContext
    @State private var isExpanded = false
    @Environment(\.sbjEditorSearchCriteria) private var searchCriteria
    @Environment(\.sbjEditorHasContent) private var hasContent

    private var disclosureBinding: Binding<Bool> {
        Binding(
            get: { isExpanded || searchCriteria.forcesExpansion(hasContent: hasContent) },
            set: { newValue in
                if !searchCriteria.isActive {
                    isExpanded = newValue
                }
            }
        )
    }

    private var displayEntries: [DisplayEntry] {
        SBJCollectionOrdering.sortedEntries(value).compactMap { key, entryValue in
            guard searchCriteria.includes(
                isChanged: entryHasChanged(key: key, value: entryValue),
                containsEmptyContent: SBJContentCheck.containsEmptyContent(
                    entryValue,
                    treatingAsLeaf: { registry.hasCustomEditor($0) }
                ),
                matchesSearch: { query in
                    if sbjPredicated(label, search: query) { return true }
                    return sbjPredicated(
                        label: String(describing: key),
                        value: entryValue,
                        search: query
                    )
                }
            ) else { return nil }
            return DisplayEntry(key: key, value: entryValue)
        }
    }

    private func entryHasChanged(key: Key, value entryValue: Value) -> Bool {
        guard let originalValue, originalValue.keys.contains(key) else { return true }
        guard let old = originalValue[key] else { return true }
        return entryValue.sbjEncodedIsDifferent(from: old)
    }

    private var addCandidate: (Key, Value)? {
        guard let key = registry.create(Key.self),
              !value.keys.contains(key),
              let entryValue = registry.create(Value.self) else { return nil }
        return (key, entryValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SBJEditorDisclosureHeader(
                "\(label) (\(value.count))",
                isExpanded: disclosureBinding,
                leadingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.leadingView }
                        Button {
                            guard let (key, entryValue) = addCandidate else { return }
                            value.updateValue(entryValue, forKey: key)
                            isExpanded = true
                        } label: {
                            Image(.system("plus.circle"))
                        }
                        .buttonStyle(.borderless)
                        .disabled(addCandidate == nil)
                        .accessibilityLabel("Add \(label)")
                    }
                ),
                trailingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.trailingView }
                    }
                )
            )

            if isExpanded || searchCriteria.isActive {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(displayEntries) { entry in
                        let key = entry.key
                        let entryValue = entry.value
                        let keyLabel = String(describing: key)
                        let entryChanged = entryHasChanged(key: key, value: entryValue)
                        let entrySearchCriteria = searchCriteria.descendingPastMatchedLabels(label, keyLabel)
                        SBJDictionaryEntryEditor(
                            key: key,
                            entryValue: Binding(
                                get: { value[key] ?? entryValue },
                                set: { value.updateValue($0, forKey: key) }
                            ),
                            originalValue: originalValue?[key],
                            entryIsChanged: entryChanged,
                            registry: registry,
                            textStyle: textStyle,
                            integerRange: integerRange,
                            numberRange: numberRange,
                            focusRequest: focusRequest,
                            context: context.descended(),
                            rename: { old, replacement in
                                value.sbjRenameKey(old, to: replacement)
                            },
                            remove: { value.removeValue(forKey: key) }
                        )
                        .environment(\.sbjEditorSearchCriteria, entrySearchCriteria)
                    }
                }
                .padding(.leading, 15).frame(maxWidth: .infinity)
            }
        }
    }
}

