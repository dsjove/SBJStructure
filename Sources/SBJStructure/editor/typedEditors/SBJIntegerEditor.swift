import Foundation
import SwiftUI

struct SBJIntegerEditor: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>?
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
                .sbjPreferredFieldWidth(SBJNumericFieldWidth.integer(range: range, locale: locale))
                .invalidDecoration(range.map { !$0.contains(value) } ?? false)
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif
            Stepper("", value: $value)
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Adjust \(label)")
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}
