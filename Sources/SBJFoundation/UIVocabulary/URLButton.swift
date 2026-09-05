import SwiftUI

/// Shared URL action for reusable interfaces.
/// Opening is routed through the framework's platform `URL.open()` abstraction.
public struct URLButton: View {
    public let url: URL?
    private let accessibilityLabel: String

    public init(url: URL?, accessibilityLabel: String = "Open link") {
        self.url = url
        self.accessibilityLabel = accessibilityLabel
    }

    @MainActor
    private var isOpenable: Bool {
        url?.isValidURL ?? false
    }

    public var body: some View {
        Button {
            URL.open(url)
        } label: {
            Image(.system((url?.absoluteString.isEmpty ?? true) ? "xmark.circle.fill" : "link.circle"))
                .imageScale(.large)
                .foregroundStyle(isOpenable ? SBJUIAppearance.interactiveColor : SBJUIAppearance.inactiveControlColor)
        }
        .buttonStyle(.plain)
        .disabled(!isOpenable)
        .accessibility(label: accessibilityLabel)
    }
}
