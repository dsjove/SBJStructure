import SwiftUI

@MainActor
public struct SBJMoveToFirstButton: View {
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let action: () -> Void

    public init(
        accessibilityLabel: String = "Move to first",
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        SBJImageButton(
            SBJSemanticImageName.moveToFirst,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            action: action
        )
    }
}
