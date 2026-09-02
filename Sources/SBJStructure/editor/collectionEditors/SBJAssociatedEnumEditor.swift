import SwiftUI

@MainActor
struct SBJAssociatedEnumEditor<Value: SBJEditableAssociatedEnum>: View {
    let label: String
    @Binding var value: Value
    let originalValue: Value?
    let registry: SBJEditorRegistry
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    let context: SBJEditTraversalContext
    @Environment(\.sbjEditorSearchCriteria) private var searchCriteria

    private var selectedCase: SBJEditorEnumCase<Value>? {
        Value.sbjEditorEnumCases.first(where: { $0.matches(value) })
    }

    private var originalForSelectedCase: Value? {
        guard let originalValue, let selectedCase else { return nil }
        return selectedCase.matches(originalValue) ? originalValue : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                SBJAssociatedEnumLabel(text: label, isUnknown: labelIsUnknown)
                Menu {
                    ForEach(Array(Value.sbjEditorEnumCases.enumerated()), id: \.offset) { _, enumCase in
                        Button(enumCase.name) {
                            if let replacement = enumCase.makeDefaultValue() {
                                value = replacement
                            }
                        }
                        .disabled(!enumCase.canCreate)
                    }
                } label: {
                    Text(selectedCase?.name ?? "Unknown")
                }
                .fixedSize()
                Spacer(minLength: 0)
            }

            if let selectedCase, !selectedCase.associatedValues.isEmpty {
                let childSearchCriteria = searchCriteria.descendingPastMatchedLabels(label, selectedCase.name)
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(selectedCase.associatedValues.enumerated()), id: \.offset) { _, field in
                        field.view(
                            root: $value,
                            originalRoot: originalForSelectedCase,
                            registry: registry,
                            focusRequest: focusRequest,
                            context: context.descended()
                        )
                    }
                }
                .environment(\.sbjEditorSearchCriteria, childSearchCriteria)
                .padding(.leading, 15).frame(maxWidth: .infinity)
            }
        }
    }
}

struct SBJAssociatedEnumLabel: View {
    let text: String
    let isUnknown: Bool

    var body: some View {
        HStack(spacing: 5) {
            SBJEditorChangeIndicator()
            SBJEditorEmptyContentIndicator()
            if isUnknown {
                Text(text).fontWeight(.semibold).italic()
            } else {
                Text(text)
            }
        }
    }
}
