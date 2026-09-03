import Foundation
import SwiftUI

struct SBJMultilineTextEditor: View {
    let label: String
    @Binding var value: String
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
            TextEditor(text: $value)
                .sbjMultilineField(isFocused: $isFocused, minHeight: 84)
                .sbjEditorAccessibleControl(label: label)
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

