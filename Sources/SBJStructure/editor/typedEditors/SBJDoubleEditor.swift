import Foundation
import SwiftUI

struct SBJDoubleEditor: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", value: $value, format: .number)
                .oneLiner(isFocused: $isFocused)
                .frame(width: SBJNumericFieldWidth.number(range: range))
                .invalidDecoration(range.map { !$0.contains(value) } ?? false)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

