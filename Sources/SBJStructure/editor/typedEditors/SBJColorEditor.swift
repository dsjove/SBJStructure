import Foundation
import SwiftUI

struct SBJColorEditor: View {
    let label: String
    @Binding var value: CodableColor
    let supportsAlpha: Bool
    let labelIsUnknown: Bool
    @Environment(\.self) private var environment

    private var colorBinding: Binding<Color> {
        Binding(
            get: { value.swiftUIColor },
            set: { newColor in
                value = CodableColor(color: newColor.resolve(in: environment))
            }
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            ColorPicker("", selection: colorBinding, supportsOpacity: supportsAlpha)
                .labelsHidden()
            Spacer()
        }
        .accessibilityValue(
            supportsAlpha
                ? "Red \(Int((value.red * 255).rounded())), green \(Int((value.green * 255).rounded())), blue \(Int((value.blue * 255).rounded())), opacity \(Int((value.opacity * 100).rounded())) percent"
                : "Red \(Int((value.red * 255).rounded())), green \(Int((value.green * 255).rounded())), blue \(Int((value.blue * 255).rounded()))"
        )
    }
}

