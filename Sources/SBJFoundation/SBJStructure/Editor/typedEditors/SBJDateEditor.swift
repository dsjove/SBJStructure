import Foundation
import SwiftUI

struct SBJDateEditor: View {
    let label: String
    @Binding var value: Date
    let range: ClosedRange<Date>?
    let labelIsUnknown: Bool

    var body: some View {
        SBJAdaptiveFieldLayout {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
        } control: {
            DatePicker("", selection: $value)
                .labelsHidden()
                .fixedSize()
                .sbjEditorAccessibleControl(label: label)
        }
    }
}

