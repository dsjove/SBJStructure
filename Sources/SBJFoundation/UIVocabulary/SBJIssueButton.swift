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
        Button(action: action) {
            Image(SBJSemanticImageName.issues(filled: hasIssues == true))
                .foregroundStyle(hasIssues == true ? SBJUIAppearance.issueColor : SBJUIAppearance.inactiveControlColor)
                .frame(minWidth: 28, minHeight: 28)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(accessibilityLabel)
    }
}
