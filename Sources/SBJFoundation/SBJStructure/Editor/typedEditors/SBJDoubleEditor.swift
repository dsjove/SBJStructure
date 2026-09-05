import Foundation
import SwiftUI

struct SBJDoubleEditor: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @Environment(\.locale) private var locale
    @FocusState private var isFocused: Bool

    var body: some View {
        SBJAdaptiveFieldLayout {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
        } control: {
            TextField("", value: $value, format: .number)
                .oneLiner(isFocused: $isFocused)
                .sbjEditorAccessibleControl(label: label)
                .sbjPreferredFieldWidth(SBJNumericFieldSizing.number(range: range, locale: locale))
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
