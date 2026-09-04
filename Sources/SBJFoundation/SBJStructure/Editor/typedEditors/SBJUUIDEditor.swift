import Foundation
import SwiftUI

struct SBJUUIDEditor: View {
    let label: String
    @Binding var value: UUID
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    var body: some View {
        SBJAdaptiveFieldLayout {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                .accessibilityHidden(true)
        } control: {
            TextField("", text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    if let parsed = newValue.sbjUUID {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .oneLiner(isFocused: $isFocused)
                .sbjEditorAccessibleControl(label: label)
            .invalidDecoration(!isValid)
#if os(iOS)
            .textInputAutocapitalization(.characters)
#endif
            Button {
                value = UUID()
                text = value.uuidString
                isValid = true
            } label: {
                Image(SBJEditorImageName.regenerate)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Generate new \(label)")
        }
        .accessibilityValue(value.uuidString)
        .onAppear {
            text = value.uuidString
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = value.uuidString
                isValid = true
            }
        }
    }

}

