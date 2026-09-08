import SwiftUI

public struct CollapsingMenu<Content: View>: View {
    @ViewBuilder let content: () -> Content
    private let collapsedContent: (() -> AnyView)?
    private let menuLabel: () -> AnyView

    public init(
        _ title: LocalizedStringKey,
        image: ImageReference,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content
        self.collapsedContent = nil
        self.menuLabel = { AnyView(Label(title, image: image)) }
    }

    /// Uses a custom menu label and, optionally, a separately-rendered form for the
    /// single-item case. `collapsedContent` should produce the same logical actions
    /// as `content`; it exists only so callers can adjust their presentation when the
    /// menu collapses to one action.
    public init<CollapsedContent: View, MenuLabel: View>(
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder collapsedContent: @escaping () -> CollapsedContent,
        @ViewBuilder label: @escaping () -> MenuLabel
    ) {
        self.content = content
        self.collapsedContent = { AnyView(collapsedContent()) }
        self.menuLabel = { AnyView(label()) }
    }

    /// Compatibility convenience for callers that currently name an SF Symbol directly.
    /// New framework code should use the `ImageReference` initializer so imagery stays on the
    /// shared presentation-resource boundary.
    public init(
        _ title: LocalizedStringKey,
        systemImage: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title, image: .system(systemImage), content: content)
    }

    @ViewBuilder
    public var body: some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            collapsingBody
        } else {
            menuBody
        }
    }

    private var menuBody: some View {
        Menu {
            content()
        } label: {
            menuLabel()
        }
        .menuOrder(.fixed)
    }

    @available(iOS 18.0, macOS 15.0, *)
    @ViewBuilder
    private var collapsingBody: some View {
        Group(subviews: content()) { subviews in
            if subviews.isEmpty {
                EmptyView()
            } else if subviews.count == 1 {
                if let collapsedContent {
                    collapsedContent()
                } else {
                    subviews[0]
                }
            } else {
                Menu {
                    ForEach(subviews) { subview in
                        subview
                    }
                } label: {
                    menuLabel()
                }
                .menuOrder(.fixed)
            }
        }
    }
}
