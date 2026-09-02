import Foundation
import SwiftUI

struct SBJDecimalEditor: View {
    let label: String
    @Binding var value: Decimal
    let range: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    if let parsed = Decimal(string: newValue, locale: Locale(identifier: "en_US_POSIX")) {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .oneLiner(isFocused: $isFocused)
            .frame(width: SBJNumericFieldWidth.number(range: range))
            .invalidDecoration(
                !isValid || (range.map { !$0.contains(NSDecimalNumber(decimal: value).doubleValue) } ?? false)
            )
#if os(iOS)
            .keyboardType(.decimalPad)
#endif
        }
        .onAppear {
            text = NSDecimalNumber(decimal: value).stringValue
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = NSDecimalNumber(decimal: value).stringValue
                isValid = true
            }
        }
    }
}

