import SwiftUI

struct SBJObjectEditor<Value: SBJSwiftUIEditable>: View {
    let title: String
    @Binding var value: Value
    let originalValue: Value?
    let registry: SBJEditorRegistry
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    let titleIsUnknown: Bool
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

    var body: some View {
        Group {
            if searchCriteria.showEmptyContentOnly && hasContent == false {
                HStack(alignment: .center, spacing: 8) {
                    if let itemActions {
                        itemActions.leadingView
                    }
                    SBJEditorChangeIndicator()
                    SBJEditorEmptyContentIndicator()
                    if titleIsUnknown {
                        Text(title).fontWeight(.semibold).italic()
                    } else {
                        Text(title).fontWeight(.semibold)
                    }
                    Spacer(minLength: 0)
                    if let itemActions {
                        itemActions.trailingView
                    }
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if Value.sbjEditorFields.count == 1, let field = Value.sbjEditorFields.first {
                HStack(alignment: .center, spacing: 8) {
                    if let itemActions {
                        itemActions.leadingView
                    }
                    field.view(
                        root: $value,
                        originalRoot: originalValue,
                        registry: registry,
                        nameOverride: "\(title) • \(field.name)",
                        focusRequest: focusRequest,
                        labelIsUnknown: titleIsUnknown,
                        context: context.descended()
                    )
                    if let itemActions {
                        itemActions.trailingView
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    SBJEditorDisclosureHeader(
                        title,
                        isExpanded: disclosureBinding,
                        leadingActions: itemActions?.leadingView ?? AnyView(EmptyView()),
                        trailingActions: itemActions?.trailingView ?? AnyView(EmptyView()),
                        titleIsUnknown: titleIsUnknown
                    )

                    if isExpanded || searchCriteria.isActive {
                        let childSearchCriteria = searchCriteria.descendingPastMatchedLabel(title)
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(Value.sbjEditorFields.enumerated()), id: \.offset) { _, field in
                                field.view(root: $value, originalRoot: originalValue, registry: registry, focusRequest: focusRequest, context: context.descended())
                            }
                        }
                        .environment(\.sbjEditorSearchCriteria, childSearchCriteria)
                        .padding(.leading, 15).frame(maxWidth: .infinity)

                        Divider()
                    }
                }
            }
        }
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
        .onAppear {
            if focusRequest != nil {
                isExpanded = true
            }
        }
    }
}
