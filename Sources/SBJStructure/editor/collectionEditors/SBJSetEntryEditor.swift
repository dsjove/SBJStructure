import Foundation
import SwiftUI

struct SBJSetEntryEditor<Element: Codable & Hashable>: View {
    let element: Element
    let originalElement: Element?
    let title: String
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let context: SBJEditTraversalContext
    let replace: (Element, Element) -> Bool
    let remove: () -> Void
    @State private var draft: Element
    @State private var collision = false

    init(
        element: Element,
        originalElement: Element?,
        title: String,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        focusRequest: SBJEditorFocusRequest?,
        context: SBJEditTraversalContext,
        replace: @escaping (Element, Element) -> Bool,
        remove: @escaping () -> Void
    ) {
        self.element = element
        self.originalElement = originalElement
        self.title = title
        self.registry = registry
        self.textStyle = textStyle
        self.integerRange = integerRange
        self.numberRange = numberRange
        self.focusRequest = focusRequest
        self.context = context
        self.replace = replace
        self.remove = remove
        _draft = State(initialValue: element)
    }

    private var isChanged: Bool {
        guard let originalElement else { return true }
        return draft.sbjEncodedIsDifferent(from: originalElement)
    }

    private var isInvalid: Bool {
        SBJInvariantCheck.validationError(
            draft,
            at: SBJValidationKeyPath(\Element.self)
        ) != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Button(action: remove) {
                    Image(.system("minus.circle"))
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove \(title)")

                SBJValueEditor.makeView(
                    label: title,
                    value: $draft,
                    originalValue: originalElement.map { SBJEditorOriginalValue($0) },
                    registry: registry,
                    textStyle: textStyle,
                    integerRange: integerRange,
                    numberRange: numberRange,
                    focusRequest: focusRequest,
                    context: context
                )

                if draft != element {
                    Button {
                        collision = !replace(element, draft)
                    } label: {
                        Image(.system("checkmark.circle"))
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Apply \(title)")
                }
            }
            if collision {
                Text("That value is already in the set.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .environment(\.sbjEditorIsChanged, isChanged)
        .environment(\.sbjEditorHasContent, (draft as? any HasContentCheckable)?.hasContent)
        .environment(\.sbjEditorIsInvalid, isInvalid)
        .sbjEditorValidationLineBackground(isInvalid)
        .onChange(of: element) { _, newValue in
            draft = newValue
            collision = false
        }
        .onChange(of: draft) { _, _ in collision = false }
    }
}
