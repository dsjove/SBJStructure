import Foundation
import SwiftUI

struct SBJBooleanEditor: View {
    let label: String
    @Binding var value: Bool
    let labelIsUnknown: Bool

    var body: some View {
        SBJAdaptiveFieldLayout {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
        } control: {
            Toggle("", isOn: $value)
                .labelsHidden()
                .fixedSize()
                .sbjEditorAccessibleControl(label: label)
        }
    }
}

