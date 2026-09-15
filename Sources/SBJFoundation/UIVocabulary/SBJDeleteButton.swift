import SwiftUI

@MainActor
public struct SBJDeleteButton: View {
    private let accessibilityLabel: String
    private let accessibilityHint: String?
    private let confirmationTitle: String?
    private let confirmationMessage: String?
    private let action: () -> Void

    @State private var showingConfirmation = false

    public init(
        accessibilityLabel: String = "Delete",
        accessibilityHint: String? = nil,
        confirmationTitle: String? = nil,
        confirmationMessage: String? = nil,
        action: @escaping () -> Void
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.confirmationTitle = confirmationTitle
        self.confirmationMessage = confirmationMessage
        self.action = action
    }

    public var body: some View {
        SBJImageButton(
            SBJSemanticImageReference.delete,
            role: .destructive,
            accessibilityLabel: accessibilityLabel,
            accessibilityHint: accessibilityHint
        ) {
            if confirmationTitle == nil {
                action()
            } else {
                showingConfirmation = true
            }
        }
        .alert(confirmationTitle ?? accessibilityLabel, isPresented: $showingConfirmation) {
            Button("Delete", role: .destructive, action: action)
            Button("Cancel", role: .cancel) {}
        } message: {
            if let confirmationMessage {
                Text(confirmationMessage)
            }
        }
    }
}
