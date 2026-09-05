import SwiftUI

@MainActor
public struct SBJMoveToLastButton: View {
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let action: () -> Void

    public init(
        accessibilityLabel: String = "Move to last",
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        SBJImageButton(
            SBJSemanticImageName.moveToLast,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            action: action
        )
    }
}
