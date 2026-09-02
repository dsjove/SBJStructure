import Foundation
import SwiftUI

struct SBJIntegerEditor: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", value: $value, format: .number)
                .oneLiner(isFocused: $isFocused)
                .frame(width: SBJNumericFieldWidth.integer(range: range))
                .invalidDecoration(range.map { !$0.contains(value) } ?? false)
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif
            Stepper("", value: $value)
                .labelsHidden()
                .fixedSize()
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

