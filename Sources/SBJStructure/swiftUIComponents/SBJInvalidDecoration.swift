import SwiftUI

private struct InvalidDecorationModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    let isInvalid: Bool
    let cornerRadius: Double
    let lineThickness: Double

    func body(content: Content) -> some View {
        content.overlay {
            if isInvalid {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.red, lineWidth: max(lineThickness, SBJAccessibilityAppearance.borderThickness(colorSchemeContrast)))
                    .allowsHitTesting(false)
            }
        }
    }
}

public extension View {
    /// Draws the standard invalid-value outline used by editable controls.
    func invalidDecoration(
        _ isInvalid: Bool = true,
        cornerRadius: Double = 6.0,
        lineThickness: Double = 1.0
    ) -> some View {
        modifier(
            InvalidDecorationModifier(
                isInvalid: isInvalid,
                cornerRadius: cornerRadius,
                lineThickness: lineThickness
            )
        )
    }
}
