import Foundation
import SwiftUI

struct SBJFontFamilyEditor: View {
    let label: String
    @Binding var value: String?
    let labelIsUnknown: Bool

    private var fontFamilies: [String] {
        let available = CodableFontCache.shared.availableFontFamilies
        guard let current = value, !available.contains(current) else {
            return available
        }
        return [current] + available
    }

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            Picker("", selection: $value) {
                Text("System").tag(Optional<String>.none)
                ForEach(fontFamilies, id: \.self) { family in
                    Text(family).tag(Optional(family))
                }
            }
            .labelsHidden()
#if os(iOS)
            .pickerStyle(.menu)
#endif
            Spacer(minLength: 0)
        }
    }
}

