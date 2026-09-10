import SwiftUI
import UniformTypeIdentifiers

/// Native SwiftUI presenter for Markdown help assets.
@available(iOS 27.0, *)
@available(macCatalyst 27.0, *)
public struct SBJMarkdownHelpPresenter: SBJHelpContentPresenter {
    public let contentType: UTType = .markdown

    public init() {}

    @MainActor
    public func makeView(source: String) -> AnyView {
        let attributed: AttributedString
        do {
            attributed = try AttributedString(
                markdown: source,
                options: .init(interpretedSyntax: .full)
            )
        } catch {
            attributed = AttributedString(source)
        }

        return AnyView(
            ScrollView {
                Text(attributed)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        )
    }
}
