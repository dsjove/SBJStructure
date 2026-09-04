import SwiftUI

@available(iOS 18.0, macOS 15.0, *)
public struct CollapsingMenu<Content: View>: View {
    let title: LocalizedStringKey
    let image: ImageName
    @ViewBuilder let content: () -> Content

    public init(
        _ title: LocalizedStringKey,
        image: ImageName,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.image = image
        self.content = content
    }

    /// Compatibility convenience for callers that currently name an SF Symbol directly.
    /// New framework code should use the `ImageName` initializer so imagery stays on the
    /// shared presentation-resource boundary.
    public init(
        _ title: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title, image: .system(systemImage), content: content)
    }

    public var body: some View {
        Group(subviews: content()) { subviews in
            if subviews.count == 1 {
                subviews[0]
            } else if !subviews.isEmpty {
                Menu {
                    ForEach(subviews) { subview in
                        subview
                    }
                } label: {
                    Label(title, image: image)
                }
                .menuOrder(.fixed)
            }
        }
    }
}
