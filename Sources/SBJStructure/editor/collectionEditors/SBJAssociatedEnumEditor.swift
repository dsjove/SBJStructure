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
                SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
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
                .controlSize(.mini)
                .fixedSize()
                .sbjActiveControl(horizontalPadding: 4, verticalPadding: 0)
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
                .frame(maxWidth: .infinity)

                SBJEditorLevelExitDivider()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
