import SwiftUI

public extension Image {
    init(_ name: ImageName) {
        switch name {
        case .none:
            self = Image("")
        case .bundled(let name, let bundle):
            self = Image(name, bundle: bundle.bundle)
                .renderingMode(.template)
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
