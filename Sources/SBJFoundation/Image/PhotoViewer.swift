#if !os(watchOS) && !os(tvOS) && canImport(UIKit)
import Observation
import SwiftUI
import UIKit

/// Full-screen presentation for inspecting image resource content.
///
/// The viewer intentionally owns only presentation transforms (zoom and pan).
/// Keeping those transforms separate from the encoded resource gives the future
/// editor a place to add persistent transforms such as crop, rotation, mirror,
/// and markup without changing the viewer's presentation contract.
@MainActor
public struct PhotoViewer: View {
    private let resource: SBJResourceContent
    private let image: UIImage
    private let title: String?

    @Environment(\.dismiss) private var dismiss
    @State private var transform: PhotoViewerTransform

    public init?(
        resource: SBJResourceContent,
        title: String? = nil,
        maximumScale: CGFloat = 8
    ) {
        let image: UIImage?
        if resource.contentType == .sbjImageDocument {
            image = (try? SBJImageDocument(serializedRepresentation: resource.data))?.renderedImage()
        } else {
            image = resource.uiImage
        }

        guard let image else { return nil }
        self.resource = resource
        self.image = image
        self.title = title
        self._transform = State(initialValue: PhotoViewerTransform(
            sourceSize: image.size,
            maximumScale: maximumScale
        ))
    }

    public var body: some View {
        SBJSharePresentationHost { sharePresenter in
            NavigationStack {
                GeometryReader { geometry in
                    ZStack {
                        Color.black
                            .ignoresSafeArea()

                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(
                                width: transform.fittedSize.width,
                                height: transform.fittedSize.height
                            )
                            .scaleEffect(transform.scale)
                            .offset(transform.offset)
                            .contentShape(Rectangle())
                            .gesture(transformGesture)
                            .simultaneousGesture(
                                TapGesture(count: 2)
                                    .onEnded { resetPosition() }
                            )
                            .accessibility(AccessibleItem(
                                label: "Photo",
                                hint: "Pinch to magnify, drag to pan, or double tap to reset"
                            ))
                    }
                    .clipped()
                    .onChange(of: geometry.size, initial: true) { _, newSize in
                        transform.containerSize = newSize
                    }
                }
                .navigationTitle(title ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        SBJDismissButton(accessibilityLabel: "Close") {
                            dismiss()
                        }

                        SBJShareButton(
                            presenter: sharePresenter,
                            prepare: { SBJSharePayload(imageForSharing()) }
                        ) {
                            Image(SBJSemanticImageReference.share)
                                .accessibility(AccessibleItem(label: "Share"))
                        }

                        SBJHelpLink(
                            asset: .imageView,
                            auto: false,
                            configuration: .image
                        )
                    }

                    ToolbarItem(placement: .topBarTrailing) {
                        SBJImageButton(
                            SBJImageSemanticImageReference.resetPanZoom,
                            accessibilityLabel: "Reset Magnification and Position",
                            accessibilityHint: "Returns the image to its fitted size and centered position.",
                            action: resetPosition
                        )
                        .disabled(transform.isAtRest)
                    }
                }
            }
        }
    }

    private var transformGesture: some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { transform.dragChanged($0.translation) }
                .onEnded { _ in transform.dragEnded() },
            MagnificationGesture()
                .onChanged { transform.magnificationChanged($0) }
                .onEnded { _ in transform.magnificationEnded() }
        )
    }

    private func resetPosition() {
        withAnimation(.easeInOut(duration: 0.2)) {
            transform.resetPosition()
        }
    }

    /// Shares the flattened, fully rendered representation of an image document.
    /// Ordinary image resources are already flattened and can be shared directly.
    private func imageForSharing() -> UIImage {
        guard resource.contentType == .sbjImageDocument else { return image }
        return (try? SBJImageDocument(serializedRepresentation: resource.data))?.renderedImage() ?? image
    }
}

@MainActor
@Observable
private final class PhotoViewerTransform {
    let sourceSize: CGSize
    let maximumScale: CGFloat

    var containerSize: CGSize = .zero {
        didSet {
            guard containerSize != oldValue else { return }
            clampOffset()
        }
    }

    private(set) var scale: CGFloat = 1
    private(set) var offset: CGSize = .zero

    private var dragStartOffset: CGSize?
    private var magnificationStartScale: CGFloat?

    init(sourceSize: CGSize, maximumScale: CGFloat) {
        self.sourceSize = sourceSize
        self.maximumScale = max(1, maximumScale)
    }

    var fittedSize: CGSize {
        guard sourceSize.width > 0,
              sourceSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0
        else { return .zero }

        let fit = min(
            containerSize.width / sourceSize.width,
            containerSize.height / sourceSize.height
        )
        return CGSize(
            width: sourceSize.width * fit,
            height: sourceSize.height * fit
        )
    }

    var isAtRest: Bool {
        abs(scale - 1) < 0.0001
        && abs(offset.width) < 0.0001
        && abs(offset.height) < 0.0001
    }

    func dragChanged(_ translation: CGSize) {
        let origin = dragStartOffset ?? offset
        if dragStartOffset == nil {
            dragStartOffset = origin
        }
        offset = clampedOffset(CGSize(
            width: origin.width + translation.width,
            height: origin.height + translation.height
        ))
    }

    func dragEnded() {
        dragStartOffset = nil
    }

    func magnificationChanged(_ magnification: CGFloat) {
        let origin = magnificationStartScale ?? scale
        if magnificationStartScale == nil {
            magnificationStartScale = origin
        }
        scale = min(max(origin * magnification, 1), maximumScale)
        clampOffset()
    }

    func magnificationEnded() {
        magnificationStartScale = nil
    }

    func resetPosition() {
        scale = 1
        offset = .zero
        dragStartOffset = nil
        magnificationStartScale = nil
    }

    private func clampOffset() {
        offset = clampedOffset(offset)
    }

    private func clampedOffset(_ proposed: CGSize) -> CGSize {
        let size = fittedSize
        guard size != .zero else { return .zero }

        let renderedWidth = size.width * scale
        let renderedHeight = size.height * scale
        let maxX = max(0, (renderedWidth - containerSize.width) / 2)
        let maxY = max(0, (renderedHeight - containerSize.height) / 2)

        return CGSize(
            width: min(max(proposed.width, -maxX), maxX),
            height: min(max(proposed.height, -maxY), maxY)
        )
    }
}
#endif
