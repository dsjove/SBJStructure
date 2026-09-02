import Foundation
import SwiftUI

struct SBJOptionalEditor<Wrapped: Codable>: View {
    let label: String
    @Binding var value: Wrapped?
    let originalValue: Wrapped??
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let dateRange: ClosedRange<Date>?
    let colorSupportsAlpha: Bool
    let collectionReorderable: Bool
    let collectionItemTitleKey: String?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    let context: SBJEditTraversalContext
    @State private var isExpanded = false
    @State private var pendingFocus: SBJEditorFocusRequest?
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
        if searchCriteria.showEmptyContentOnly && hasContent == false {
            HStack(alignment: .center, spacing: 8) {
                if let itemActions {
                    itemActions.leadingView
                }
                if value != nil {
                    clearButton
                }
                SBJEditorFieldName(text: label, isUnknown: false)
                    .fontWeight((Wrapped.self as? any SBJSwiftUIEditable.Type) != nil ? .semibold : .regular)
                Spacer(minLength: 0)
                if let itemActions {
                    itemActions.trailingView
                }
            }
        } else if let unwrapped = Binding($value) {
            if let editable = Wrapped.self as? any SBJSwiftUIEditable.Type {
                if editable._sbjEditorFieldCount == 1 {
                    HStack(alignment: .center, spacing: 8) {
                        if let itemActions {
                            itemActions.leadingView
                        }
                        clearButton
                        editable._sbjMakeEditor(
                            label: label,
                            binding: SBJAnyBinding(unwrapped),
                            originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                            registry: registry,
                            focusRequest: pendingFocus ?? focusRequest,
                            context: context.descended()
                        )
                        if let itemActions {
                            itemActions.trailingView
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        SBJEditorDisclosureHeader(
                            label,
                            isExpanded: disclosureBinding,
                            leadingActions: AnyView(
                                HStack(spacing: 6) {
                                    if let itemActions {
                                        itemActions.leadingView
                                    }
                                    clearButton
                                }
                            ),
                            trailingActions: itemActions?.trailingView ?? AnyView(EmptyView())
                        )

                        if isExpanded || searchCriteria.isActive {
                            let childSearchCriteria = searchCriteria.descendingPastMatchedLabel(label)
                            editable._sbjMakeEditorContents(
                                binding: SBJAnyBinding(unwrapped),
                                originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                                registry: registry,
                                focusRequest: pendingFocus ?? focusRequest,
                                context: context.descended()
                            )
                            .environment(\.sbjEditorSearchCriteria, childSearchCriteria)
                            .padding(.leading, 15).frame(maxWidth: .infinity)

                            Divider()
                        }
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    if let itemActions {
                        itemActions.leadingView
                    }
                    clearButton
                    SBJValueEditor.makeView(
                        label: label,
                        value: unwrapped,
                        originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                        registry: registry,
                        textStyle: textStyle,
                        integerRange: integerRange,
                        numberRange: numberRange,
                        dateRange: dateRange,
                        colorSupportsAlpha: colorSupportsAlpha,
                        collectionReorderable: collectionReorderable,
                        collectionItemTitleKey: collectionItemTitleKey,
                        focusRequest: pendingFocus ?? focusRequest,
                        context: context.descended()
                    )
                    if let itemActions {
                        itemActions.trailingView
                    }
                }
            }
        } else {
            HStack(spacing: 8) {
                if let itemActions {
                    itemActions.leadingView
                }
                if Wrapped.self is any SBJSwiftUIEditable.Type {
                    Color.clear.frame(width: 22, height: 1)
                }
                Button {
                    value = registry.create(Wrapped.self)
                    if value != nil {
                        isExpanded = true
                        pendingFocus = SBJEditorFocusRequest()
                    }
                } label: {
                    Image(.system("circle.dashed"))
                }
                .buttonStyle(.borderless)
                .disabled(registry.create(Wrapped.self) == nil)
                .accessibilityLabel("Set \(label)")
                SBJEditorFieldName(text: label, isUnknown: false)
                    .fontWeight((Wrapped.self as? any SBJSwiftUIEditable.Type) != nil ? .semibold : .regular)
                Spacer()
                if let itemActions {
                    itemActions.trailingView
                }
            }
        }
    }

    private var originalWrapped: Wrapped? {
        guard let originalValue else { return nil }
        return originalValue
    }

    private var clearButton: some View {
        Button {
            value = nil
            pendingFocus = nil
        } label: {
            Image(.system("xmark.circle"))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Clear \(label)")
    }
}

