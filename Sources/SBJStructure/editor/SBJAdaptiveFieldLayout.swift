import SwiftUI

/// A label/control pair that preserves the compact editor grammar when it fits,
/// but stacks vertically when Dynamic Type or translated text needs more room.
///
/// The layout is deliberately content-driven rather than locale-driven. Leading
/// and trailing remain semantic, so SwiftUI mirrors the result automatically in
/// right-to-left environments.
@MainActor
struct SBJAdaptiveFieldLayout<Label: View, Control: View>: View {
    private let spacing: CGFloat
    private let label: Label
    private let control: Control
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        spacing: CGFloat = 8,
        @ViewBuilder label: () -> Label,
        @ViewBuilder control: () -> Control
    ) {
        self.spacing = spacing
        self.label = label()
        self.control = control()
    }

    @ViewBuilder
    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            vertical
        } else {
            ViewThatFits(in: .horizontal) {
                horizontal
                    .fixedSize(horizontal: true, vertical: false)
                vertical
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var horizontal: some View {
        HStack(alignment: .center, spacing: spacing) {
            label
                .fixedSize(horizontal: true, vertical: false)
            HStack(spacing: spacing) {
                control
            }
            .fixedSize(horizontal: true, vertical: false)
        }
    }

    private var vertical: some View {
        VStack(alignment: .leading, spacing: 4) {
            label
            HStack(spacing: spacing) {
                control
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
