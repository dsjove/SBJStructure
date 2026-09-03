import Foundation
import SwiftUI

struct SBJArrayEditor<Element: Codable>: View {
    let label: String
    @Binding var value: [Element]
    let originalValue: [Element]?
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let reorderable: Bool
    let itemTitleKey: String?
    let itemIdentifierKey: String?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    let context: SBJEditTraversalContext
    @State private var userIsExpanded = false
    @State private var focusIndex: Int?
    @State private var pendingFocus: SBJEditorFocusRequest?
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

    private var isDisplayingFilteredSubset: Bool {
        SBJArrayEditorPresentation.isDisplayingFilteredSubset(criteria: searchCriteria)
    }

    private var displayIndices: [Int] {
        Array(value.indices).filter { index in
            searchCriteria.includes(
                isChanged: itemHasChanged(at: index),
                containsEmptyContent: SBJContentCheck.containsEmptyContent(
                    value[index],
                    treatingAsLeaf: { registry.hasCustomEditor($0) }
                ),
                matchesSearch: { query in
                    if sbjPredicated(label, search: query) { return true }
                    let title = itemTitle(for: value[index], index: index).text
                    return sbjPredicated(label: title, value: value[index], search: query)
                }
            )
        }
    }

    private var displayItems: [SBJEditorSnapshotItem<Int>] {
        displayIndices.map { index in
            let stable = SBJCollectionItemIdentification.stableIdentifier(
                for: value[index],
                itemIdentifierKey: itemIdentifierKey
            ) ?? "slot:\(index)"
            return SBJEditorSnapshotItem(
                itemIdentifier: context.itemIdentifier.appending("item:\(stable)"),
                indexPath: context.indexPath.appending("index:\(index)"),
                content: index
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SBJEditorDisclosureHeader(
                "\(label) (\(value.count))",
                treeLevel: context.treeLevel,
                isExpanded: disclosureBinding,
                leadingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions {
                            itemActions.leadingView
                        }
                        Button {
                            if let newValue = registry.createArrayElement(Element.self, existing: value) {
                                value.append(newValue)
                                focusIndex = value.index(before: value.endIndex)
                                pendingFocus = SBJEditorFocusRequest()
                                userIsExpanded = true
                            }
                        } label: {
                            Image(.system("plus.circle"))
                        }
                        .buttonStyle(.borderless)
                        .disabled(registry.createArrayElement(Element.self, existing: value) == nil)
                        .accessibilityLabel("Add \(label)")
                    }
                ),
                trailingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions {
                            itemActions.trailingView
                        }
                    }
                )
            )

            if resolvedIsExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if displayIndices.isEmpty {
                        SBJEditorEmptyDisclosureContent(
                            message: value.isEmpty
                                ? "No entries. Use + to add one."
                                : "No entries match the current filters."
                        )
                    }

                    ForEach(displayItems) { item in
                        let index = item.content
                        let itemContext = SBJEditTraversalContext(
                            treeLevel: context.treeLevel + 1,
                            itemIdentifier: item.itemIdentifier,
                            indexPath: item.indexPath
                        )
                        let itemLabel = itemTitle(for: value[index], index: index)
                        let itemSearchCriteria = searchCriteria.descendingPastMatchedLabels(label, itemLabel.text)
                        let itemInvalid = SBJInvariantCheck.validationError(
                            value[index],
                            at: SBJValidationKeyPath(\Element.self)
                        ) != nil
                        SBJValueEditor.makeView(
                            label: itemLabel.text,
                            value: Binding(
                                get: { value[index] },
                                set: { value[index] = $0 }
                            ),
                            originalValue: originalElement(at: index).map { SBJEditorOriginalValue($0) },
                            registry: registry,
                            textStyle: textStyle,
                            integerRange: integerRange,
                            numberRange: numberRange,
                            promotedTitlePropertyName: itemTitleKey,
                            promotedTitlePrefix: "\(SBJArrayEditorPresentation.itemNumber(for: index)))",
                            itemActions: actions(for: index),
                            focusRequest: index == focusIndex ? pendingFocus : focusRequest,
                            labelIsUnknown: itemLabel.isUnknown,
                            context: itemContext
                        )
                        .environment(\.sbjEditorSearchCriteria, itemSearchCriteria)
                        .environment(\.sbjEditorIsChanged, itemHasChanged(at: index))
                        .environment(\.sbjEditorHasContent, (value[index] as? any HasContentCheckable)?.hasContent)
                        .environment(\.sbjEditorIsInvalid, itemInvalid)
                        .sbjEditorValidationLineBackground(itemInvalid)
                    }
                }
                .frame(maxWidth: .infinity)

                SBJEditorLevelExitDivider()
            }
        }
    }

    private func originalElement(at index: Int) -> Element? {
        guard let originalValue, originalValue.indices.contains(index) else { return nil }
        return originalValue[index]
    }

    private func itemHasChanged(at index: Int) -> Bool {
        guard value.indices.contains(index) else { return false }
        guard let original = originalElement(at: index) else { return true }
        return value[index].sbjEncodedIsDifferent(from: original)
    }

    private func itemTitle(for element: Element, index: Int) -> (text: String, isUnknown: Bool) {
        let prefix = "\(SBJArrayEditorPresentation.itemNumber(for: index))) "
        guard let title = SBJCollectionItemIdentification.configuredTitle(
            for: element,
            itemTitleKey: itemTitleKey
        ) else {
            return (prefix + label, true)
        }
        return (prefix + title, false)
    }

    private func actions(for index: Int) -> SBJEditorItemActions {
        SBJEditorItemActions(
            remove: {
                guard value.indices.contains(index) else { return }
                value.remove(at: index)
                if focusIndex == index {
                    focusIndex = nil
                    pendingFocus = nil
                } else if let focusIndex, focusIndex > index {
                    self.focusIndex = focusIndex - 1
                }
            },
            moveUp: reorderable && !isDisplayingFilteredSubset && index > value.startIndex ? {
                guard value.indices.contains(index), value.indices.contains(index - 1) else { return }
                value.swapAt(index, index - 1)
            } : nil,
            moveDown: reorderable && !isDisplayingFilteredSubset && value.indices.contains(index + 1) ? {
                guard value.indices.contains(index), value.indices.contains(index + 1) else { return }
                value.swapAt(index, index + 1)
            } : nil
        )
    }
}

