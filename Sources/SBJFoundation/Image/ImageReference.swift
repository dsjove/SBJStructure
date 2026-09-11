import Foundation

/// A concrete reference to image content used by reusable UI vocabulary.
///
/// `ImageReference` unifies named presentation imagery and file-backed image content without
/// committing model code to SwiftUI or UIKit. Platform-specific realization is provided by
/// extensions below.
public enum ImageReference: Sendable, Hashable {
    case none
    case bundled(String, bundle: Bundle? = nil)
    case system(String)
//TODO: support async non-file URLs
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

import SwiftUI

#if canImport(ImageIO)
import ImageIO
#endif

public extension Image {
    init(_ reference: ImageReference) {
        switch reference {
        case .none:
            self = Image("")
        case .bundled(let name, let bundle):
            self = Image(name, bundle: bundle)
                .renderingMode(.template)
        case .system(let name):
            self = Image(systemName: name)
        case .file(let url):
            #if canImport(ImageIO)
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess { url.stopAccessingSecurityScopedResource() }
            }

            if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
               let image = CGImageSourceCreateImageAtIndex(source, 0, nil) {
                self = Image(decorative: image, scale: 1)
            } else {
                self = Image("")
            }
            #else
            self = Image("")
            #endif
        }
    }
}

public extension Label where Title == Text, Icon == Image {
    init(_ title: LocalizedStringKey, image: ImageReference) {
        self = Label {
            Text(title)
        } icon: {
            Image(image)
        }
    }

    init(_ title: String, image: ImageReference) {
        self = Label {
            Text(title)
        } icon: {
            Image(image)
        }
    }
}

#if canImport(UIKit)
import UIKit

public extension ImageReference {
    var image: UIImage? {
        switch self {
        case .none:
            nil
        case .bundled(let name, let bundle):
#if os(watchOS)
            UIImage(named: name)
#else
            UIImage(named: name, in: bundle, compatibleWith: nil)
#endif
        case .system(let name):
            UIImage(systemName: name)
        case .file(let url):
            UIImage(url: url)
        }
    }

    var data: Data? {
        image?.pngData()
    }
}
#endif
