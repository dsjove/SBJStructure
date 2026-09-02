import SwiftUI

/// Shared URL action used by the structured editor and client applications.
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
                .foregroundStyle(isOpenable ? Color.accentColor : Color.secondary)
        }
        .buttonStyle(.plain)
        .disabled(!isOpenable)
        .accessibility(label: accessibilityLabel)
    }
}

/// Shared read-only URL presentation using the same URL-opening behavior as
/// `URLButton` rather than SwiftUI's separate `Link`/`openURL` path.
public struct URLText: View {
    public let name: String
    public let url: URL?

    public init(name: String = "", url: URL?) {
        self.name = name
        self.url = url
    }

    @MainActor
    private var isOpenable: Bool {
        url?.isValidURL ?? false
    }

    public var body: some View {
        if let url {
            let simpleName = name.isEmpty ? (url.host ?? url.absoluteString) : name
            if isOpenable {
                Button(simpleName) { url.open() }
                    .buttonStyle(.plain)
                    .foregroundStyle(.tint)
            } else {
                Text(simpleName)
            }
        } else if !name.isEmpty {
            Text(name)
        }
    }
}
