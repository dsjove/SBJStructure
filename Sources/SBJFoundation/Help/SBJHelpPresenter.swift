#if !os(watchOS)
import SwiftUI
import UniformTypeIdentifiers

/// A content-type-specific help presenter.
///
/// The sheet/chrome is independent of this protocol. New help representations
/// can provide a presenter without changing `SBJHelpAsset` or the surrounding
/// help UI.
@MainActor
public protocol SBJHelpContentPresenter {
    var contentType: UTType { get }
    func makeView(document: SBJHelpDocument) -> AnyView
}

/// Type erasure for injecting an application- or package-defined presenter.
public struct SBJAnyHelpContentPresenter: SBJHelpContentPresenter {
    public let contentType: UTType
    private let make: @MainActor (SBJHelpDocument) -> AnyView

    public init<P: SBJHelpContentPresenter>(_ presenter: P) {
        contentType = presenter.contentType
        make = presenter.makeView
    }

    public init(
        contentType: UTType,
        makeView: @escaping @MainActor (SBJHelpDocument) -> AnyView
    ) {
        self.contentType = contentType
        self.make = makeView
    }

    public func makeView(document: SBJHelpDocument) -> AnyView {
        make(document)
    }
}

@MainActor
public enum SBJHelpPresenters {
    public static func builtIn(for contentType: UTType) -> SBJAnyHelpContentPresenter? {
        if contentType.conforms(to: .html) {
            return SBJAnyHelpContentPresenter(SBJHTMLHelpPresenter())
        }
		if #available(macCatalyst 27.0, *) {
			if #available(iOS 27.0, *) {
				if contentType.conforms(to: .markdown) {
					return SBJAnyHelpContentPresenter(SBJMarkdownHelpPresenter())
				}
			} else {
				// Fallback on earlier versions
			}
		} else {
			// Fallback on earlier versions
		}
        return nil
    }
}
#endif
