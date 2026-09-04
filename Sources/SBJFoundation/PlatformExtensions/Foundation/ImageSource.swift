import Foundation

/// Describes where image content comes from without committing to a UI framework.
///
/// Platform-specific image realization lives in the UIKit extension.
public enum ImageSource: Sendable {
    case none
    case bundled(String, Bundle? = nil)
    case system(String)
    case file(URL)

    public var isEmpty: Bool {
        switch self {
        case .none:
            true
        case .bundled(let name, _):
            name.isEmpty
        case .system(let name):
            name.isEmpty
        case .file(let url):
            url.path.isEmpty
        }
    }
}
