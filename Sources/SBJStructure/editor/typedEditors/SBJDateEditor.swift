import Foundation
import SwiftUI

struct SBJDateEditor: View {
    let label: String
    @Binding var value: Date
    let range: ClosedRange<Date>?
    let labelIsUnknown: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            DatePicker("", selection: $value)
                .labelsHidden()
        }
    }
}

