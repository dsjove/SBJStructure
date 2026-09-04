import Foundation
import SwiftUI

struct SBJSingleLineTextEditor: View {
    let label: String
    @Binding var value: String
    let maximumLength: Int?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        SBJAdaptiveFieldLayout(
            controlWidth: .singleLineText(maximumLength: maximumLength)
        ) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
        } control: {
            field
        }
        .onAppear(perform: claimFocus)
    }

    @ViewBuilder
    private var field: some View {
        let base = TextField("", text: $value)
            .oneLiner(isFocused: $isFocused)
            .sbjEditorAccessibleControl(label: label)

        if let sizing = SBJTextFieldWidth.singleLine(maximumLength: maximumLength) {
            base.sbjPreferredFieldWidth(sizing)
        } else {
            base
        }
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}
