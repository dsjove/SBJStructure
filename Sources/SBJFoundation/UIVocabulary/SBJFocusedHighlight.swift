import SwiftUI


private struct ActiveControlModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    let horizontalPadding: Double
    let verticalPadding: Double

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: SBJUIAppearance.singleLineFieldMinimumHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .stroke(
                        SBJUIAppearance.fieldBorderColor(colorSchemeContrast),
                        lineWidth: SBJUIAppearance.borderThickness(colorSchemeContrast)
                    )
                    .allowsHitTesting(false)
            }
            .contentShape(RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius))
    }
}


private struct MultilineFieldModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var isFocused: FocusState<Bool>.Binding
    let minHeight: Double

    func body(content: Content) -> some View {
        content
            .focused(isFocused)
#if !os(watchOS)
            .scrollContentBackground(.hidden)
#endif
            .padding(.horizontal, 7)
            .padding(.vertical, 6)
            .frame(minHeight: minHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .stroke(
                        SBJUIAppearance.fieldBorderColor(colorSchemeContrast),
                        lineWidth: SBJUIAppearance.borderThickness(colorSchemeContrast)
                    )
            }
            .overlay {
                if isFocused.wrappedValue {
                    RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                        .stroke(
                            SBJUIAppearance.focusColor,
                            lineWidth: SBJUIAppearance.focusThickness(colorSchemeContrast)
                        )
                }
            }
    }
}

private struct FocusedHighlightModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
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
                        SBJUIAppearance.focusStrokeColor(colorSchemeContrast),
                        lineWidth: isFocused == id ? max(lineThickness, SBJUIAppearance.focusThickness(colorSchemeContrast)) : 0
                    )
                    .shadow(
                        color: SBJUIAppearance.focusShadowColor(reduceTransparency: reduceTransparency),
                        radius: (!reduceTransparency && isFocused == id) ? 5 : 0
                    )
            )
    }
}

private struct BooleanBindingFocusedHighlightModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var isFocused: FocusState<Bool>.Binding
    let cornerRadius: Double
    let lineThickness: Double

    func body(content: Content) -> some View {
        content
            .focused(isFocused)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        SBJUIAppearance.focusStrokeColor(colorSchemeContrast),
                        lineWidth: isFocused.wrappedValue ? max(lineThickness, SBJUIAppearance.focusThickness(colorSchemeContrast)) : 0
                    )
                    .shadow(
                        color: SBJUIAppearance.focusShadowColor(reduceTransparency: reduceTransparency),
                        radius: (!reduceTransparency && isFocused.wrappedValue) ? 5 : 0
                    )
            )
    }
}

private struct BindingFocusedHighlightModifier<Value: Hashable>: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
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
                        SBJUIAppearance.focusStrokeColor(colorSchemeContrast),
                        lineWidth: isFocused.wrappedValue == id ? max(lineThickness, SBJUIAppearance.focusThickness(colorSchemeContrast)) : 0
                    )
                    .shadow(
                        color: SBJUIAppearance.focusShadowColor(reduceTransparency: reduceTransparency),
                        radius: (!reduceTransparency && isFocused.wrappedValue == id) ? 5 : 0
                    )
            )
    }
}

/// The common single-line editor field treatment.
///
/// The normal and focused strokes deliberately use the same shape. Focus only
/// changes the stroke color/thickness; it never changes the field's geometry.
private struct OneLineFieldModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
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
            .frame(minHeight: SBJUIAppearance.singleLineFieldMinimumHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .stroke(
                        SBJUIAppearance.fieldBorderColor(colorSchemeContrast),
                        lineWidth: SBJUIAppearance.borderThickness(colorSchemeContrast)
                    )
            }
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                        .stroke(
                            SBJUIAppearance.focusColor,
                            lineWidth: SBJUIAppearance.focusThickness(colorSchemeContrast)
                        )
                }
            }
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .submitLabel(.done)
    }
}

private struct FocusableOneLineFieldModifier: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    var isFocused: FocusState<Bool>.Binding

    func body(content: Content) -> some View {
        content
            .focused(isFocused)
#if !os(watchOS)
            .textFieldStyle(.plain)
#endif
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(minHeight: SBJUIAppearance.singleLineFieldMinimumHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .stroke(
                        SBJUIAppearance.fieldBorderColor(colorSchemeContrast),
                        lineWidth: SBJUIAppearance.borderThickness(colorSchemeContrast)
                    )
            }
            .overlay {
                if isFocused.wrappedValue {
                    RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                        .stroke(
                            SBJUIAppearance.focusColor,
                            lineWidth: SBJUIAppearance.focusThickness(colorSchemeContrast)
                        )
                }
            }
            .multilineTextAlignment(.leading)
            .lineLimit(1)
            .submitLabel(.done)
    }
}

private struct IdentifiedFocusableOneLineFieldModifier<Value: Hashable>: ViewModifier {
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    var isFocused: FocusState<Value?>.Binding
    let id: Value

    func body(content: Content) -> some View {
        content
            .focused(isFocused, equals: id)
#if !os(watchOS)
            .textFieldStyle(.plain)
#endif
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .frame(minHeight: SBJUIAppearance.singleLineFieldMinimumHeight)
            .background {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .fill(.background)
            }
            .overlay {
                RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                    .stroke(
                        SBJUIAppearance.fieldBorderColor(colorSchemeContrast),
                        lineWidth: SBJUIAppearance.borderThickness(colorSchemeContrast)
                    )
            }
            .overlay {
                if isFocused.wrappedValue == id {
                    RoundedRectangle(cornerRadius: SBJUIAppearance.fieldCornerRadius)
                        .stroke(
                            SBJUIAppearance.focusColor,
                            lineWidth: SBJUIAppearance.focusThickness(colorSchemeContrast)
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

    /// Standard multiline text-editor treatment using the same field chrome
    /// as single-line text fields. Focus changes only the shared outer stroke.
    func sbjMultilineField(
        isFocused: FocusState<Bool>.Binding,
        minHeight: Double = 84
    ) -> some View {
        modifier(MultilineFieldModifier(isFocused: isFocused, minHeight: minHeight))
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

    /// Standard single-line text-field behavior using an identified focus value.
    /// Useful for repeated fields that share one `FocusState` keyed by row/item ID.
    func oneLiner<Value: Hashable>(
        isFocused: FocusState<Value?>.Binding,
        id: Value
    ) -> some View {
        modifier(IdentifiedFocusableOneLineFieldModifier(isFocused: isFocused, id: id))
    }

    /// Standard single-line text-field behavior when the caller does not need
    /// to control focus programmatically.
    func oneLiner() -> some View {
        modifier(OneLineFieldModifier())
    }
}
