import SwiftUI

@MainActor
public struct SBJAddButton: View {
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let action: () -> Void

    public init(
        accessibilityLabel: String = "Add",
        accessibilityHint: String? = nil,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
    }

    public var body: some View {
        SBJImageButton(
            SBJSemanticImageName.add,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint,
            action: action
        )
    }
}
