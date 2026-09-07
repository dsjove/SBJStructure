import SwiftUI

/// Shared primitive for compact icon-only actions.
///
/// Semantic wrappers choose the image, role, and accessibility wording. This
/// primitive owns the ordinary button style and compact interaction geometry so
/// callers do not need to repeat those presentation decisions.
@MainActor
public struct SBJImageButton: View {
    public let image: ImageName
    private let role: ButtonRole?
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let action: () -> Void

    public init(
        _ image: ImageName,
        role: ButtonRole? = nil,
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.image = image
        self.role = role
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        Button(role: role, action: action) {
            Image(image)
                .frame(
                    minWidth: SBJUIAppearance.compactButtonMinimumSize,
                    minHeight: SBJUIAppearance.compactButtonMinimumSize
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(accessibilityLabel)
        .applyIf(accessibilityHint) { view, hint in
            view.accessibilityHint(hint)
        }
    }
}
