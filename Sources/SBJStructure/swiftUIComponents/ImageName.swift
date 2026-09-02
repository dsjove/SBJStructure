import Foundation
import SwiftUI

/// A SwiftUI helper that distinguishes bundled image resources from SF Symbols.
///
/// `ImageName` is intentionally a SwiftUI-layer type. Use `ImageSource` when the
/// responsibility is loading image content rather than naming UI imagery.
public enum ImageName {
    case none
    case bundled(String, Bundle? = nil)
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

public extension Image {
    init(_ name: ImageName) {
        switch name {
        case .none:
            self = Image("")
        case .bundled(let name, let bundle):
            self = Image(name, bundle: bundle)
        case .system(let name):
            self = Image(systemName: name)
        }
    }
}

public extension Label where Title == Text, Icon == Image {
    init(_ title: String, image: ImageName) {
        switch image {
        case .none:
            self = Label(title, image: "")
        case .bundled(let name, let bundle):
            if let bundle {
                self = Label {
                    Text(title)
                } icon: {
                    Image(name, bundle: bundle)
                        .renderingMode(.template)
                }
            } else {
                self = Label(title, image: name)
            }
        case .system(let name):
            self = Label(title, systemImage: name)
        }
    }
}
