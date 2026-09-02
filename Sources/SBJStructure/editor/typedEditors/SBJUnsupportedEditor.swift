import Foundation
import SwiftUI

struct SBJUnsupportedEditor<Value>: View {
    let label: String
    let type: Value.Type
    let value: Value
    let labelIsUnknown: Bool
    @Environment(\.sbjEditorShowIssues) private var showIssues

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            if let description = SBJValueDescription.describe(value) {
                Text(description)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button(action: showIssues) {
                Image(.system("exclamationmark.circle.fill"))
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Show editor issues")
        }
    }
}
