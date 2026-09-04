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
        SBJAdaptiveFieldLayout {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
        } control: {
            NumberTextField("", value: $value, in: range, isFocused: $isFocused)
                .sbjEditorAccessibleControl(label: label)
            stepper
                .labelsHidden()
                .fixedSize()
                .accessibilityLabel("Adjust \(label)")
        }
        .onAppear(perform: claimFocus)
    }

    @ViewBuilder
    private var stepper: some View {
        if let range {
            Stepper("", value: $value, in: range)
        } else {
            Stepper("", value: $value)
        }
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}
