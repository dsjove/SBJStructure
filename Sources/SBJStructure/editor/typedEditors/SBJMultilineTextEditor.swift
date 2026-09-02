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
            TextEditor(text: $value)
                .focusedHighlight(isFocused: $isFocused)
                .frame(minHeight: 84)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.secondary.opacity(0.35), lineWidth: 1)
                )
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

