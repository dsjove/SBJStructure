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
    let collectionItemIdentifierKey: String?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    let context: SBJEditTraversalContext
    @State private var userIsExpanded = false
    @State private var pendingFocus: SBJEditorFocusRequest?
    @Environment(\.sbjEditorSearchCriteria) private var searchCriteria
    @Environment(\.sbjEditorHasContent) private var hasContent

    /// Optional rows reserve the disclosure lane only when the populated value
    /// actually uses a disclosure header.  In particular, a one-field structured
    /// value is flattened, so its nil state must not reserve a disclosure column
    /// that disappears as soon as the value is created.
    private var wrappedNeedsDisclosure: Bool {
        guard let editable = Wrapped.self as? any SBJSwiftUIEditable.Type else {
            return false
        }
        return editable._sbjEditorFieldCount > 1
    }

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

    var body: some View {
        if searchCriteria.showEmptyContentOnly && hasContent == false {
            SBJEditorRow(
                treeLevel: context.treeLevel,
                elementAction: itemActions?.leadingView,
                optionalControl: value == nil ? AnyView(setButton) : AnyView(clearButton),
                trailingActions: itemActions?.trailingView
            ) {
                HStack(spacing: 8) {
                    SBJEditorFieldName(text: label, isUnknown: false)
                        .fontWeight((Wrapped.self as? any SBJSwiftUIEditable.Type) != nil ? .semibold : .regular)
                    Spacer(minLength: 0)
                }
            }
        } else if let unwrapped = Binding($value) {
            if let editable = Wrapped.self as? any SBJSwiftUIEditable.Type {
                if editable._sbjEditorFieldCount == 1 {
                    SBJEditorRow(
                        treeLevel: context.treeLevel,
                        elementAction: itemActions?.leadingView,
                        optionalControl: AnyView(clearButton),
                        showsStatusIndicators: false,
                        trailingActions: itemActions?.trailingView
                    ) {
                        editable._sbjMakeEditor(
                            label: label,
                            binding: SBJAnyBinding(unwrapped),
                            originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                            registry: registry,
                            focusRequest: pendingFocus ?? focusRequest,
                            context: context.descended()
                        )
                        .environment(\.sbjEditorRowLayoutSuppressed, true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        SBJEditorDisclosureHeader(
                            label,
                            treeLevel: context.treeLevel,
                            isExpanded: disclosureBinding,
                            leadingActions: itemActions?.leadingView ?? AnyView(EmptyView()),
                            optionalControl: AnyView(clearButton),
                            trailingActions: itemActions?.trailingView ?? AnyView(EmptyView())
                        )

                        if resolvedIsExpanded {
                            let childSearchCriteria = searchCriteria.descendingPastMatchedLabel(label)
                            editable._sbjMakeEditorContents(
                                binding: SBJAnyBinding(unwrapped),
                                originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                                registry: registry,
                                focusRequest: pendingFocus ?? focusRequest,
                                context: context.descended()
                            )
                            .environment(\.sbjEditorSearchCriteria, childSearchCriteria)
                            .frame(maxWidth: .infinity)

                            SBJEditorLevelExitDivider()
                        }
                    }
                }
            } else {
                SBJEditorRow(
                    treeLevel: context.treeLevel,
                    elementAction: itemActions?.leadingView,
                    optionalControl: AnyView(clearButton),
                    showsStatusIndicators: false,
                    trailingActions: itemActions?.trailingView
                ) {
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
                    .environment(\.sbjEditorRowLayoutSuppressed, true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        } else {
            SBJEditorRow(
                treeLevel: context.treeLevel,
                disclosureControl: wrappedNeedsDisclosure ? AnyView(Color.clear) : nil,
                elementAction: itemActions?.leadingView,
                optionalControl: AnyView(setButton),
                trailingActions: itemActions?.trailingView
            ) {
                HStack(spacing: 8) {
                    SBJEditorFieldName(text: label, isUnknown: false)
                        .fontWeight((Wrapped.self as? any SBJSwiftUIEditable.Type) != nil ? .semibold : .regular)
                    Spacer(minLength: 0)
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
        .frame(minHeight: SBJEditorRowMetrics.firstLineHeight, alignment: .center)
        .accessibilityLabel("Clear \(label)")
    }

    private var setButton: some View {
        Button {
            value = registry.create(Wrapped.self)
            if value != nil {
                userIsExpanded = true
                pendingFocus = SBJEditorFocusRequest()
            }
        } label: {
            Image(.system("circle.dashed"))
        }
        .buttonStyle(.borderless)
        .disabled(registry.create(Wrapped.self) == nil)
        .frame(minHeight: SBJEditorRowMetrics.firstLineHeight, alignment: .center)
        .accessibilityLabel("Set \(label)")
    }
}

