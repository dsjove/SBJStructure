import Foundation
import SwiftUI

struct SBJBooleanEditor: View {
    let label: String
    @Binding var value: Bool
    let labelIsUnknown: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            Toggle("", isOn: $value)
                .labelsHidden()
                .fixedSize()
            Spacer(minLength: 0)
        }
    }
}

