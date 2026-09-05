import Foundation
import SwiftUI

/// A SwiftUI helper that distinguishes bundled image resources from SF Symbols.
///
/// `ImageName` is intentionally a SwiftUI-layer type. Use `ImageSource` when the
/// responsibility is loading image content rather than naming UI imagery.
///
/// LOCALIZATION / PRESENTATION NOTE: today these cases identify concrete image candidates.
/// Framework controls should still pass imagery through `ImageName` rather than constructing
/// `Image(systemName:)` directly. That gives the shared presentation-resource design one
/// boundary at which locale, culture, vendor, writing direction, accessibility, or theme may
/// later choose a different candidate. See Documentation/LOCALIZATION_AND_PRESENTATION_RESOURCES.md.
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

public extension Image {
    init(_ name: ImageName) {
        switch name {
        case .none:
            self = Image("")
        case .bundled(let name, let bundle):
            self = Image(name, bundle: bundle.bundle)
        case .system(let name):
            self = Image(systemName: name)
        }
    }
}

public extension Label where Title == Text, Icon == Image {
    init(_ title: LocalizedStringKey, image: ImageName) {
        switch image {
        case .none:
            self = Label {
                Text(title)
            } icon: {
                Image("")
            }
        case .bundled(let name, let bundle):
            self = Label {
                Text(title)
            } icon: {
                Image(name, bundle: bundle.bundle)
                    .renderingMode(.template)
            }
        case .system(let name):
            self = Label {
                Text(title)
            } icon: {
                Image(systemName: name)
            }
        }
    }

    init(_ title: String, image: ImageName) {
        switch image {
        case .none:
            self = Label(title, image: "")
        case .bundled(let name, let bundle):
            self = Label {
                Text(title)
            } icon: {
                Image(name, bundle: bundle.bundle)
                    .renderingMode(.template)
            }
        case .system(let name):
            self = Label(title, systemImage: name)
        }
    }
}
