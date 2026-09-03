import SwiftUI

private enum SBJFieldAppearance {
    static let cornerRadius: Double = 6.0
    static let singleLineHeight: Double = 24.0
    static let borderThickness: Double = 1.0
    static let focusThickness: Double = 2.0

    static var borderColor: Color {
        Color.secondary.opacity(0.65)
    }

    static var focusColor: Color {
        Color.accentColor
    }
}


private struct ActiveControlModifier: ViewModifier {
    let horizontalPadding: Double
    let verticalPadding: Double

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(height: SBJFieldAppearance.singleLineHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                    .stroke(
                        SBJFieldAppearance.borderColor,
                        lineWidth: SBJFieldAppearance.borderThickness
                    )
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius))
    }
}

private struct FocusedHighlightModifier: ViewModifier {
    @FocusState private var isFocused: UUID?
    let id = UUID()
    let cornerRadius: Double
    let lineThickness: Double

    func body(content: Content) -> some View {
        content
            .focused($isFocused, equals: id)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.accentColor.opacity(0.5),
                        lineWidth: isFocused == id ? lineThickness : 0
                    )
                    .shadow(
                        color: Color.accentColor.opacity(0.25),
                        radius: isFocused == id ? 5 : 0
                    )
            )
    }
}

private struct BooleanBindingFocusedHighlightModifier: ViewModifier {
    var isFocused: FocusState<Bool>.Binding
    let cornerRadius: Double
    let lineThickness: Double

    func body(content: Content) -> some View {
        content
            .focused(isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.accentColor.opacity(0.5),
                        lineWidth: isFocused.wrappedValue ? lineThickness : 0
                    )
                    .shadow(
                        color: Color.accentColor.opacity(0.25),
                        radius: isFocused.wrappedValue ? 5 : 0
                    )
            )
    }
}

private struct BindingFocusedHighlightModifier<Value: Hashable>: ViewModifier {
    var isFocused: FocusState<Value>.Binding
    let id: Value
    let cornerRadius: Double
    let lineThickness: Double

    func body(content: Content) -> some View {
        content
            .focused(isFocused, equals: id)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        Color.accentColor.opacity(0.5),
                        lineWidth: isFocused.wrappedValue == id ? lineThickness : 0
                    )
                    .shadow(
                        color: Color.accentColor.opacity(0.25),
                        radius: isFocused.wrappedValue == id ? 5 : 0
                    )
            )
    }
}

/// The common single-line editor field treatment.
///
/// The normal and focused strokes deliberately use the same shape. Focus only
/// changes the stroke color/thickness; it never changes the field's geometry.
private struct OneLineFieldModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        decorated(content.focused($isFocused), isFocused: isFocused)
    }

    @ViewBuilder
    private func decorated<V: View>(_ content: V, isFocused: Bool) -> some View {
        content
#if !os(watchOS)
            .textFieldStyle(.plain)
#endif
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(height: SBJFieldAppearance.singleLineHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                    .stroke(
                        SBJFieldAppearance.borderColor,
                        lineWidth: SBJFieldAppearance.borderThickness
                    )
            }
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                        .stroke(
                            SBJFieldAppearance.focusColor,
                            lineWidth: SBJFieldAppearance.focusThickness
                        )
                }
            }
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .submitLabel(.done)
    }
}

private struct FocusableOneLineFieldModifier: ViewModifier {
    var isFocused: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        content
            .focused(isFocused)
#if !os(watchOS)
            .textFieldStyle(.plain)
#endif
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(height: SBJFieldAppearance.singleLineHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                    .stroke(
                        SBJFieldAppearance.borderColor,
                        lineWidth: SBJFieldAppearance.borderThickness
                    )
            }
            .overlay {
                if isFocused.wrappedValue {
                    RoundedRectangle(cornerRadius: SBJFieldAppearance.cornerRadius)
                        .stroke(
                            SBJFieldAppearance.focusColor,
                            lineWidth: SBJFieldAppearance.focusThickness
                        )
                }
            }
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .submitLabel(.done)
    }
}

public extension View {
    /// Gives a non-text editable control the same visual field chrome used by
    /// single-line text fields. This is intended for menus, pickers, and other
    /// controls whose default presentation can otherwise read as static text.
    func sbjActiveControl(
        horizontalPadding: Double = 7,
        verticalPadding: Double = 4
    ) -> some View {
        modifier(
            ActiveControlModifier(
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding
            )
        )
    }

    /// Adds focus handling and the standard custom focus highlight to a view
    /// that does not already use the standard one-line field treatment.
    func focusedHighlight(
        cornerRadius: Double = 6.0,
        lineThickness: Double = 2.0
    ) -> some View {
        modifier(
            FocusedHighlightModifier(
                cornerRadius: cornerRadius,
                lineThickness: lineThickness
            )
        )
    }

    /// Uses an existing Boolean focus state while applying the standard focus highlight.
    func focusedHighlight(
        isFocused: FocusState<Bool>.Binding,
        cornerRadius: Double = 6.0,
        lineThickness: Double = 2.0
    ) -> some View {
        modifier(
            BooleanBindingFocusedHighlightModifier(
                isFocused: isFocused,
                cornerRadius: cornerRadius,
                lineThickness: lineThickness
            )
        )
    }

    /// Uses an existing UUID focus state while applying the standard focus highlight.
    func focusedHighlight(
        isFocused: FocusState<UUID?>.Binding,
        id: UUID,
        cornerRadius: Double = 6.0,
        lineThickness: Double = 2.0
    ) -> some View {
        modifier(
            BindingFocusedHighlightModifier(
                isFocused: isFocused,
                id: id,
                cornerRadius: cornerRadius,
                lineThickness: lineThickness
            )
        )
    }

    /// Standard single-line text-field behavior with a common SBJ border.
    /// The focused border is drawn directly over the normal border using the
    /// same rounded rectangle and corner radius.
    func oneLiner(isFocused: FocusState<Bool>.Binding) -> some View {
        modifier(FocusableOneLineFieldModifier(isFocused: isFocused))
    }

    /// Standard single-line text-field behavior when the caller does not need
    /// to control focus programmatically.
    func oneLiner() -> some View {
        modifier(OneLineFieldModifier())
    }
}
