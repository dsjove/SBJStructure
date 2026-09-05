import Foundation
import SwiftUI

struct SBJDecimalEditor: View {
    let label: String
    @Binding var value: Decimal
    let range: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @Environment(\.locale) private var locale
    @State private var text = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    var body: some View {
        SBJAdaptiveFieldLayout {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
        } control: {
            TextField("", text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    if let parsed = parsedDecimal(newValue) {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .oneLiner(isFocused: $isFocused)
                .sbjEditorAccessibleControl(label: label)
            .sbjPreferredFieldWidth(SBJNumericFieldSizing.number(range: range, locale: locale))
            .invalidDecoration(
                !isValid || (range.map { !$0.contains(NSDecimalNumber(decimal: value).doubleValue) } ?? false)
            )
#if os(iOS)
            .keyboardType(.decimalPad)
#endif
        }
        .onAppear {
            text = formattedDecimal(value)
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = formattedDecimal(value)
                isValid = true
            }
        }
        .onChange(of: locale.identifier) { _, _ in
            if !isFocused {
                text = formattedDecimal(value)
            }
        }
    }

    private func formatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        return formatter
    }

    private func parsedDecimal(_ text: String) -> Decimal? {
        formatter().number(from: text)?.decimalValue
    }

    private func formattedDecimal(_ value: Decimal) -> String {
        formatter().string(from: NSDecimalNumber(decimal: value))
            ?? NSDecimalNumber(decimal: value).stringValue
    }
}
