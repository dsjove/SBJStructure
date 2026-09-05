import SwiftUI

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
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(accessibilityLabel)
        .applyIf(accessibilityHint) { view, hint in
            view.accessibilityHint(hint)
        }
    }
}
