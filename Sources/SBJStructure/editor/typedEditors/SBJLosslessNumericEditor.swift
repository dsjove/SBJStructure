import Foundation
import SwiftUI

struct SBJLosslessNumericEditor<Value: LosslessStringConvertible>: View {
    let label: String
    @Binding var value: Value
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text: String = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", text: Binding(
                get: { text.isEmpty && !isFocused ? String(value) : text },
                set: { newValue in
                    text = newValue
                    if let parsed = Value(newValue) {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .oneLiner(isFocused: $isFocused)
            .frame(width: SBJNumericFieldWidth.unboundedInteger)
            .invalidDecoration(!isValid)
#if os(iOS)
            .keyboardType(.numbersAndPunctuation)
#endif
        }
        .onAppear {
            text = String(value)
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = String(value)
                isValid = true
            }
        }
    }
}

