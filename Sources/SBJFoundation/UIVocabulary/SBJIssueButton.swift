import SwiftUI

@MainActor
public struct SBJIssueButton: View {
    public let hasIssues: Bool?
    private let accessibilityLabel: String
    private let action: () -> Void

    public init(
        hasIssues: Bool?,
        accessibilityLabel: String = "Show issues",
        action: @escaping () -> Void
    ) {
        self.hasIssues = hasIssues
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        SBJImageButton(
            SBJSemanticImageName.issues(filled: hasIssues == true),
            accessibilityLabel: accessibilityLabel,
            action: action
        )
        .foregroundStyle(hasIssues == true ? SBJUIAppearance.issueColor : SBJUIAppearance.inactiveControlColor)
    }
}
