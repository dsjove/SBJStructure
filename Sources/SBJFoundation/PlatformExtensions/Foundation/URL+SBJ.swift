import Foundation

#if os(iOS)
import UIKit
#elseif os(watchOS)
import WatchKit
#endif

public typealias IdentifiedURL = Identified<URL>

public extension String {
    /// Parses a URL after trimming surrounding whitespace and newlines.
    ///
    /// This helper intentionally applies no business-rule policy. Relative URLs and
    /// unusual schemes remain representable; `@SBJURL` constraints are evaluated
    /// only by explicit invariant validation.
    var sbjURL: URL? {
        URL(string: trimmingCharacters(in: .whitespacesAndNewlines))
    }
}

/// Platform URL behavior shared by SBJStructure's editor and client UI.
///
/// This deliberately does not use SwiftUI's `openURL` environment. Keeping the
/// behavior on `URL` makes it available to non-SwiftUI callers and preserves the
/// platform-opening path used by existing applications.
@MainActor
public extension URL {
    var isValidURL: Bool {
        guard !absoluteString.isEmpty, scheme != nil else { return false }

#if os(iOS)
#if WIDGET_TARGET
        return true
#else
        return UIApplication.shared.canOpenURL(self)
#endif
#elseif os(watchOS)
        return true
#else
        return true
#endif
    }

    @discardableResult
    static func open(_ urlString: String) -> URL? {
        let url = URL(string: urlString)
        open(url)
        return url
    }

    static func open(_ url: URL?) {
        url?.open()
    }

    func open() {
#if os(iOS)
#if !WIDGET_TARGET
        UIApplication.shared.open(self, options: [:], completionHandler: nil)
#endif
#elseif os(watchOS)
        WKExtension.shared().openSystemURL(self)
#endif
    }
}
