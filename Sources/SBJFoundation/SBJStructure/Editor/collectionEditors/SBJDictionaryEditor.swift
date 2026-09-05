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
    let textStyle: SBJStringStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    let context: SBJEditTraversalContext
    @State private var userIsExpanded = false
    @Environment(\.sbjEditorSearchCriteria) private var searchCriteria
    @Environment(\.sbjEditorHasContent) private var hasContent

    /// Expansion has two independent sources. The user's disclosure choice is
    /// persistent editor state; filtering/search may temporarily require this
    /// node to be open. Search never mutates the user's choice.
    private var searchIsExpanded: Bool {
        searchCriteria.forcesExpansion(hasContent: hasContent)
    }

    private var resolvedIsExpanded: Bool {
        userIsExpanded || searchIsExpanded
    }

    private var disclosureBinding: Binding<Bool> {
        Binding(
            get: { resolvedIsExpanded },
            set: { newValue in
                // While search/filtering requires the node to be visible, the
                // disclosure cannot visually close. More importantly, do not let
                // that temporary presentation overwrite the user's saved state.
                if !searchIsExpanded {
                    userIsExpanded = newValue
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
        return !SBJStructuralCompare.equals(entryValue, old)
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
                treeLevel: context.treeLevel,
                isExpanded: disclosureBinding,
                leadingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.leadingView }
                        SBJAddButton(accessibilityLabel: "Add \(label)") {
                            guard let (key, entryValue) = addCandidate else { return }
                            value.updateValue(entryValue, forKey: key)
                            userIsExpanded = true
                        }
                        .disabled(addCandidate == nil)
                    }
                ),
                trailingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.trailingView }
                    }
                )
            )

            if resolvedIsExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    if displayEntries.isEmpty {
                        SBJEditorEmptyDisclosureContent(
                            message: value.isEmpty
                                ? "No entries. Use + to add one."
                                : "No entries match the current filters."
                        )
                    }

                    ForEach(displayEntries) { entry in
                        let key = entry.key
                        let entryValue = entry.value
                        let keyLabel = String(describing: key)
                        let itemContext = context.descended(dictionaryKey: "\(String(reflecting: key))")
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
                            context: itemContext,
                            rename: { old, replacement in
                                value.sbjRenameKey(old, to: replacement)
                            },
                            remove: { value.removeValue(forKey: key) }
                        )
                        .environment(\.sbjEditorSearchCriteria, entrySearchCriteria)
                    }
                }
                .frame(maxWidth: .infinity)

                SBJEditorLevelExitDivider()
            }
        }
    }
}

