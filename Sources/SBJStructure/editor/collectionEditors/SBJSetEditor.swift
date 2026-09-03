import Foundation
import SwiftUI

struct SBJSetEditor<Element: Codable & Hashable>: View {
    let label: String
    @Binding var value: Set<Element>
    let originalValue: Set<Element>?
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let itemTitleKey: String?
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

    private var displayElements: [Element] {
        SBJCollectionOrdering.sorted(value).filter { element in
            searchCriteria.includes(
                isChanged: originalValue?.contains(element) != true,
                containsEmptyContent: SBJContentCheck.containsEmptyContent(
                    element,
                    treatingAsLeaf: { registry.hasCustomEditor($0) }
                ),
                matchesSearch: { query in
                    if sbjPredicated(label, search: query) { return true }
                    return sbjPredicated(
                        label: SBJCollectionItemIdentification.title(for: element, itemTitleKey: itemTitleKey),
                        value: element,
                        search: query
                    )
                }
            )
        }
    }

    private var addCandidate: Element? {
        guard let candidate = registry.create(Element.self), !value.contains(candidate) else { return nil }
        return candidate
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
                        Button {
                            guard let candidate = addCandidate else { return }
                            value.insert(candidate)
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
                VStack(alignment: .leading, spacing: 8) {
                    if displayElements.isEmpty {
                        SBJEditorEmptyDisclosureContent(
                            message: value.isEmpty
                                ? "No entries. Use + to add one."
                                : "No entries match the current filters."
                        )
                    }

                    ForEach(displayElements, id: \.self) { element in
                        let itemTitle = SBJCollectionItemIdentification.title(for: element, itemTitleKey: itemTitleKey)
                        let itemSearchCriteria = searchCriteria.descendingPastMatchedLabels(label, itemTitle)
                        SBJSetEntryEditor(
                            element: element,
                            originalElement: originalValue?.contains(element) == true ? element : nil,
                            title: itemTitle,
                            registry: registry,
                            textStyle: textStyle,
                            integerRange: integerRange,
                            numberRange: numberRange,
                            focusRequest: focusRequest,
                            context: context.descended(),
                            replace: { old, replacement in
                                value.sbjReplace(old, with: replacement)
                            },
                            remove: { value.remove(element) }
                        )
                        .environment(\.sbjEditorSearchCriteria, itemSearchCriteria)
                    }
                }
                .frame(maxWidth: .infinity)

                SBJEditorLevelExitDivider()
            }
        }
    }
}

