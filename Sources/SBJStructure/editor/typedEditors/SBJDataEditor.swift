import Foundation
import SwiftUI

struct SBJDataEditor: View {
    let label: String
    @Binding var value: Data
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                Spacer()
                Text("\(value.count) byte\(value.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextEditor(text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    do {
                        value = try newValue.sbjHexData()
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            ))
            .font(.system(.body, design: .monospaced))
            .focusedHighlight(isFocused: $isFocused)
            .frame(minHeight: 90)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
            )
            .invalidDecoration(errorMessage != nil)
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        }
        .accessibilityValue("\(value.count) byte\(value.count == 1 ? "" : "s")")
        .onAppear {
            text = value.sbjHexFormat()
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused, errorMessage == nil {
                text = value.sbjHexFormat()
            }
        }
    }
}

