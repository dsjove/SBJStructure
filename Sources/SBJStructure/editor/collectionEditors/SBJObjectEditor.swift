import SwiftUI

struct SBJObjectEditor<Value: SBJSwiftUIEditable>: View {
    let title: String
    @Binding var value: Value
    let originalValue: Value?
    let registry: SBJEditorRegistry
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    let titleIsUnknown: Bool
    let promotedTitlePropertyName: String?
    let promotedTitlePrefix: String?
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

    private var promotedTitleField: SBJEditorField<Value>? {
        guard let promotedTitlePropertyName else { return nil }
        return Value.sbjEditorFields.first { field in
            field.editableField.structuralMetadata?.sourceName == promotedTitlePropertyName
        }
    }

    private func isPromotedTitleField(_ field: SBJEditorField<Value>) -> Bool {
        guard let promotedTitlePropertyName else { return false }
        return field.editableField.structuralMetadata?.sourceName == promotedTitlePropertyName
    }

    private var isShowingContents: Bool {
        isExpanded || searchCriteria.isActive
    }

    private var bodyFields: [SBJEditorField<Value>] {
        Value.sbjEditorFields.filter { !isPromotedTitleField($0) }
    }


    var body: some View {
        let rootValidation = SBJEditorRootValidationResult.computed(
            SBJInvariantCheck.validationError(
                value,
                at: SBJValidationKeyPath(\Value.self)
            )
        )

        Group {
            if searchCriteria.showEmptyContentOnly && hasContent == false {
                SBJEditorRow(
                    treeLevel: context.treeLevel,
                    elementAction: itemActions?.leadingView,
                    trailingActions: itemActions?.trailingView
                ) {
                    HStack(spacing: 8) {
                        if titleIsUnknown {
                            Text(title).fontWeight(.semibold).italic()
                        } else {
                            Text(title).fontWeight(.semibold)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: SBJEditorRowMetrics.firstLineHeight, alignment: .leading)
                }
                .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else if Value.sbjEditorFields.count == 1, let field = Value.sbjEditorFields.first {
                // A one-field object is visually one row. The outer row owns the
                // item's status/indent/remove/reorder lanes; the field keeps only
                // its local controls (for example Optional's clear/set button).
                // This avoids recursively paying for a second hierarchy/status
                // grammar between the item action and its title.
                SBJEditorRow(
                    treeLevel: context.treeLevel,
                    elementAction: itemActions?.leadingView,
                    trailingActions: itemActions?.trailingView
                ) {
                    field.view(
                        root: $value,
                        originalRoot: originalValue,
                        registry: registry,
                        nameOverride: "\(title) • \(field.name)",
                        focusRequest: focusRequest,
                        labelIsUnknown: titleIsUnknown,
                        context: context.descended(),
                        rootValidation: rootValidation
                    )
                    .environment(\.sbjEditorRowEmbedded, true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    SBJEditorDisclosureHeader(
                        title,
                        treeLevel: context.treeLevel,
                        isExpanded: disclosureBinding,
                        leadingActions: itemActions?.leadingView ?? AnyView(EmptyView()),
                        trailingActions: itemActions?.trailingView ?? AnyView(EmptyView()),
                        infoAction: promotedTitleInfoAction,
                        titleIsUnknown: titleIsUnknown,
                        titleContent: promotedHeaderContent(rootValidation: rootValidation)
                    )

                    if isShowingContents {
                        let childSearchCriteria = searchCriteria.descendingPastMatchedLabel(title)
                        VStack(alignment: .leading, spacing: 8) {
                            if bodyFields.isEmpty {
                                SBJEditorEmptyDisclosureContent(
                                    message: promotedTitleField == nil
                                        ? "No editable properties."
                                        : "No additional editable properties."
                                )
                            }

                            ForEach(
                                Array(bodyFields.enumerated()),
                                id: \.offset
                            ) { _, field in
                                field.view(
                                    root: $value,
                                    originalRoot: originalValue,
                                    registry: registry,
                                    focusRequest: focusRequest,
                                    context: context.descended(),
                                    rootValidation: rootValidation
                                )
                            }
                        }
                        .environment(\.sbjEditorSearchCriteria, childSearchCriteria)
                        .frame(maxWidth: .infinity)

                        SBJEditorLevelExitDivider()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var promotedTitleInfoAction: AnyView? {
        guard let field = promotedTitleField,
              let info = field.editableField.structuralMetadata?.info else {
            return nil
        }
        return AnyView(
            SBJEditorPropertyInfoButton(propertyName: field.name, info: info)
        )
    }

    private func promotedHeaderContent(rootValidation: SBJEditorRootValidationResult) -> AnyView? {
        guard isShowingContents,
              let field = promotedTitleField else {
            return nil
        }

        let prefix = promotedTitlePrefix.map { "\($0) " } ?? ""
        return AnyView(
            field.view(
                root: $value,
                originalRoot: originalValue,
                registry: registry,
                nameOverride: prefix + field.name,
                focusRequest: focusRequest,
                labelIsUnknown: titleIsUnknown,
                context: context.descended(),
                rootValidation: rootValidation
            )
            // The disclosure header already owns the row's disclosure/action/status
            // lanes. Keep the title property's actual editor, but suppress its own
            // nested row grammar so it can live directly in the header content lane.
            .environment(\.sbjEditorRowLayoutSuppressed, true)
            // The parent disclosure row owns the shared trailing info gutter.
            // Suppress the promoted property's local button so it appears exactly
            // once, pinned at the row's trailing edge.
            .environment(\.sbjEditorPropertyInfoHidden, true)
            // The element may be visible because another descendant matched the
            // active search. The promoted title must remain visible as its header
            // even when that title field itself does not match the filter.
            .environment(\.sbjEditorSearchCriteria, SBJEditSearchCriteria())
        )
    }
}
