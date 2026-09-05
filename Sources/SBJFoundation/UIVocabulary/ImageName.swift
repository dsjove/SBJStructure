import Foundation

/// A concrete image candidate used by reusable UI vocabulary.
///
/// This is not itself localization policy. It is a presentation candidate that
/// may later participate in localization resolution for symbology.
public enum ImageName: Sendable, Hashable {
    case none
    case bundled(String, bundle: BundleReference = .main)
    case system(String)

    public var isEmpty: Bool {
        switch self {
        case .none:
            true
        case .bundled(let name, _):
            name.isEmpty
        case .system(let name):
            name.isEmpty
        }
    }
}
