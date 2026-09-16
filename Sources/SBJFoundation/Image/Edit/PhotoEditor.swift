#if !os(watchOS) && !os(tvOS) && canImport(UIKit)
import Observation
import SwiftUI
import UIKit
#if canImport(PencilKit)
import PencilKit
#endif

/// Full-screen image editor backed by normalized edit geometry.
///
/// Persistent edits are represented by PhotoEditGeometry. The SwiftUI canvas
/// and PhotoEditRenderer both resolve that same geometry, so crop/placement,
/// rotation and mirror have one source of truth for presentation and export.
@MainActor
public struct PhotoEditor: View {
    private let resource: SBJResourceContent
    private let image: UIImage
    private let title: String?
    private let options: PhotoEditorOptions
    private let onComplete: (SBJResourceContent?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var geometry: PhotoEditGeometry
    @State private var initialGeometry: PhotoEditGeometry
    @State private var canvasSize: CGSize = .zero
    @State private var dragStartGeometry: PhotoEditGeometry?
    @State private var magnificationStartGeometry: PhotoEditGeometry?
    @State private var freeCropStartAspect: Double?
    @State private var freeCropStartFrameSize: CGSize?
    @State private var showsStraightenControl = false
#if canImport(PencilKit)
    @State private var markup = PhotoMarkupState()
    @State private var markupActive = false
    @State private var markupCanvasSize: CGSize = .zero
    private let toolPicker = PKToolPicker()
#endif

    public init?(
        resource: SBJResourceContent,
        title: String? = nil,
        options: PhotoEditorOptions = .default,
        onComplete: @escaping (SBJResourceContent?) -> Void
    ) {
        guard let image = resource.uiImage else { return nil }
        self.resource = resource
        self.image = image
        self.title = title
        self.options = options
        self.onComplete = onComplete

        let initialCrop: PhotoCropOption? = options.allowsNoCrop
            ? nil
            : options.cropOptions.first
        let initial = PhotoEditGeometry(crop: .init(option: initialCrop, sourceSize: image.size))
        self._geometry = State(initialValue: initial)
        self._initialGeometry = State(initialValue: initial)
    }

    public var body: some View {
        SBJSharePresentationHost { sharePresenter in
            NavigationStack {
                GeometryReader { proxy in
                    editorCanvas(size: proxy.size)
                        .onChange(of: proxy.size, initial: true) { _, size in
                            canvasSize = size
                        }
                }
                .background(Color.black.ignoresSafeArea())
                .navigationTitle(title ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { toolbar(sharePresenter: sharePresenter) }
                .overlay(alignment: .bottom) {
                    straightenOverlay
                }
            }
        }
    }

    @ViewBuilder
    private func editorCanvas(size: CGSize) -> some View {
        let layout = PhotoGeometryResolver.resolve(
            sourceSize: image.size,
            containerSize: size,
            geometry: geometry,
            options: options
        )

        ZStack {
            Color.black

            if geometry.crop.option != nil {
                transformedImage(layout: layout)
                    .position(layout.imageCenter)
                    .opacity(0.28)
            }

            ZStack(alignment: .topLeading) {
                transformedImage(layout: layout)
                    .position(layout.imageCenterInFrame)

#if canImport(PencilKit)
                if options.allowsMarkup {
                    PhotoMarkupCanvas(model: markup, isActive: markupActive, toolPicker: toolPicker)
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear { markupCanvasSize = proxy.size }
                                    .onChange(of: proxy.size) { _, newSize in
                                        markupCanvasSize = newSize
                                    }
                            }
                        }
                }
#endif
            }
            .frame(width: layout.frameRect.width, height: layout.frameRect.height)
            .clipped()
            .overlay {
                if geometry.crop.option != nil {
                    Rectangle()
                        .stroke(.white.opacity(0.85), lineWidth: 1)
                        .allowsHitTesting(false)

                    if geometry.crop.option == .free, !isMarkupActive {
                        Circle()
                            .fill(.white)
                            .frame(width: 18, height: 18)
                            .shadow(radius: 2)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                            .offset(x: 5, y: 5)
                            .contentShape(Rectangle().inset(by: -14))
                            .highPriorityGesture(
                                DragGesture()
                                    .onChanged { value in
                                        let start = freeCropStartAspect ?? geometry.crop.freeAspectRatio
                                        let startSize = freeCropStartFrameSize ?? layout.frameRect.size
                                        if freeCropStartAspect == nil {
                                            freeCropStartAspect = start
                                            freeCropStartFrameSize = startSize
                                        }
                                        let newWidth = max(40, startSize.width + value.translation.width)
                                        let newHeight = max(40, startSize.height + value.translation.height)
                                        geometry.crop.freeAspectRatio = min(max(Double(newWidth / newHeight), 0.25), 4)
                                        geometry.placement = .zero
                                        geometry.magnification = 1
                                    }
                                    .onEnded { _ in
                                        freeCropStartAspect = nil
                                        freeCropStartFrameSize = nil
                                        geometry = constrained(geometry)
                                    }
                            )
                            .accessibilityLabel("Resize Free Crop")
                    }
                }
            }
            .position(x: layout.frameRect.midX, y: layout.frameRect.midY)
        }
        .contentShape(Rectangle())
        .photoEditGesture(enabled: geometry.crop.option != nil && !isMarkupActive, editGesture(layout: layout))
        .onTapGesture(count: 2) {
            guard geometry.crop.option != nil, !isMarkupActive else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                geometry.placement = .zero
                geometry.magnification = 1
            }
        }
    }

    @ViewBuilder
    private func transformedImage(layout: PhotoResolvedLayout) -> some View {
        Image(uiImage: image)
            .resizable()
            .frame(width: layout.renderedImageSize.width, height: layout.renderedImageSize.height)
            .scaleEffect(x: layout.mirrorX, y: layout.mirrorY)
            .rotationEffect(.radians(layout.rotationRadians))
    }

    private var isMarkupActive: Bool {
#if canImport(PencilKit)
        markupActive
#else
        false
#endif
    }

    private func editGesture(layout: PhotoResolvedLayout) -> some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let start = dragStartGeometry ?? geometry
                    if dragStartGeometry == nil { dragStartGeometry = start }
                    var proposed = start
                    let startLayout = PhotoGeometryResolver.resolve(
                        sourceSize: image.size,
                        containerSize: canvasSize,
                        geometry: start,
                        options: options
                    )
                    let proposedTranslation = CGSize(
                        width: startLayout.translation.width + value.translation.width,
                        height: startLayout.translation.height + value.translation.height
                    )
                    proposed.placement = PhotoGeometryResolver.normalizedPlacement(
                        for: proposedTranslation,
                        renderedImageSize: startLayout.renderedImageSize
                    )
                    geometry = constrained(proposed)
                }
                .onEnded { _ in dragStartGeometry = nil },
            MagnificationGesture()
                .onChanged { value in
                    let start = magnificationStartGeometry ?? geometry
                    if magnificationStartGeometry == nil { magnificationStartGeometry = start }
                    var proposed = start
                    proposed.magnification = min(
                        max(start.magnification * Double(value), 1),
                        options.maximumMagnification
                    )
                    geometry = constrained(proposed)
                }
                .onEnded { _ in magnificationStartGeometry = nil }
        )
    }

    private func constrained(_ proposed: PhotoEditGeometry) -> PhotoEditGeometry {
        var result = proposed
        let layout = PhotoGeometryResolver.resolve(
            sourceSize: image.size,
            containerSize: canvasSize,
            geometry: proposed,
            options: options
        )
        result.placement = PhotoGeometryResolver.normalizedPlacement(
            for: layout.translation,
            renderedImageSize: layout.renderedImageSize
        )
        result.magnification = min(max(result.magnification, 1), options.maximumMagnification)
        return result
    }

    @ToolbarContentBuilder
    private func toolbar(sharePresenter: SBJSharePresenter) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button("Cancel", role: .cancel) {
                onComplete(nil)
                dismiss()
            }

            if options.allowsShare {
                SBJShareButton(
                    presenter: sharePresenter,
                    prepare: { SBJSharePayload(renderedImageForSharing ?? image) }
                ) {
                    Image(SBJSemanticImageReference.share)
                        .accessibilityLabel("Share Edited Photo")
                }
            }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
#if canImport(PencilKit)
            if options.allowsMarkup, markupActive {
                Button { markup.clear() } label: { Image(.system("eraser")) }
                    .disabled(!markup.hasDrawing)
                    .accessibilityLabel("Clear Markup")
                Button { markup.undo() } label: { Image(.system("arrow.uturn.backward")) }
                    .disabled(!markup.canUndo)
                    .accessibilityLabel("Undo Markup")
                Button { markup.redo() } label: { Image(.system("arrow.uturn.forward")) }
                    .disabled(!markup.canRedo)
                    .accessibilityLabel("Redo Markup")
            } else {
                geometryToolbarButtons
            }

            if options.allowsMarkup {
                Button {
                    markupActive.toggle()
                } label: {
                    Image(.system(markupActive ? "pencil.slash" : "pencil.tip"))
                }
                .accessibilityLabel(markupActive ? "Hide Markup Tools" : "Show Markup Tools")
            }
#else
            geometryToolbarButtons
#endif

            Button("Done") {
                complete()
            }
            .fontWeight(.semibold)
            .disabled(!hasEdits)
        }
    }

    @ViewBuilder
    private var geometryToolbarButtons: some View {
        if options.allowsQuarterTurnRotation {
            Button {
                geometry.rotation.rotate(clockwise: false)
                geometry = constrained(geometry)
            } label: {
                Image(.system("rotate.left"))
            }
            .accessibilityLabel("Rotate Left 90 Degrees")
        }

        if options.availableMirrorAxes.contains(.horizontal) {
            Button {
                geometry.mirror.toggle(.horizontal)
            } label: {
                Image(.system("arrow.left.and.right.righttriangle.left.righttriangle.right"))
            }
            .accessibilityLabel("Mirror Horizontally")
        }

        if options.availableMirrorAxes.contains(.vertical) {
            Button {
                geometry.mirror.toggle(.vertical)
            } label: {
                Image(.system("arrow.up.and.down"))
            }
            .accessibilityLabel("Mirror Vertically")
        }

        if showsCropControls {
            Menu {
                if options.allowsNoCrop {
                    Button("None") { setCrop(nil) }
                }
                ForEach(options.cropOptions) { option in
                    Button(option.title) { setCrop(option) }
                }

                Divider()

                Button {
                    resetPlacementAndMagnification()
                } label: {
                    Label("Reset Pan & Zoom", systemImage: "arrow.down.left.and.arrow.up.right.rectangle")
                }
                .disabled(!hasPlacementOrMagnificationEdits)
            } label: {
                Image(.system("crop"))
            }
            .accessibilityLabel("Crop: \(currentCropTitle)")
        }

        if options.allowsFreeRotation {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsStraightenControl.toggle()
                }
            } label: {
                Image(.system("dial.medium"))
            }
            .accessibilityLabel(showsStraightenControl ? "Hide Straighten Control" : "Straighten")
        }
    }

    @ViewBuilder
    private var straightenOverlay: some View {
        if !isMarkupActive && options.allowsFreeRotation && showsStraightenControl {
            HStack {
                Text("Straighten")
                    .font(.caption)
                Slider(value: $geometry.rotation.fineDegrees, in: -15...15)
                Text("\(geometry.rotation.fineDegrees, specifier: "%.1f")°")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 46, alignment: .trailing)
                Button {
                    resetStraighten()
                } label: {
                    Image(.system("arrow.counterclockwise"))
                }
                .buttonStyle(.plain)
                .disabled(!hasStraightenEdit)
                .accessibilityLabel("Reset Straighten")
            }
            .onChange(of: geometry.rotation.fineDegrees) { _, _ in
                constrainCurrentGeometryIfNeeded()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }

    private var showsCropControls: Bool {
        options.allowsNoCrop || !options.cropOptions.isEmpty
    }

    private var currentCropTitle: String {
        geometry.crop.option?.title ?? "None"
    }

    private func setCrop(_ option: PhotoCropOption?) {
        geometry.crop.option = option
        geometry.placement = .zero
        geometry.magnification = 1
        geometry = constrained(geometry)
    }

    private var hasGeometryEdits: Bool {
        geometry != initialGeometry
    }

    private var hasPlacementOrMagnificationEdits: Bool {
        geometry.placement != initialGeometry.placement
            || geometry.magnification != initialGeometry.magnification
    }

    private var hasStraightenEdit: Bool {
        geometry.rotation.fineDegrees != initialGeometry.rotation.fineDegrees
    }

    private var hasEdits: Bool {
#if canImport(PencilKit)
        hasGeometryEdits || markup.hasDrawing
#else
        hasGeometryEdits
#endif
    }

    private var requiresRendering: Bool {
        geometry.crop.option != nil || hasEdits
    }

    private func constrainCurrentGeometryIfNeeded() {
        let adjusted = constrained(geometry)
        guard adjusted != geometry else { return }
        geometry = adjusted
    }

    private func resetPlacementAndMagnification() {
        geometry.placement = initialGeometry.placement
        geometry.magnification = initialGeometry.magnification
        constrainCurrentGeometryIfNeeded()
        dragStartGeometry = nil
        magnificationStartGeometry = nil
    }

    private func resetStraighten() {
        geometry.rotation.fineDegrees = initialGeometry.rotation.fineDegrees
        constrainCurrentGeometryIfNeeded()
    }

    private func complete() {
        if !requiresRendering {
            onComplete(resource)
            dismiss()
            return
        }

        let rendered = PhotoEditRenderer.render(
            resource: resource,
            geometry: geometry,
            options: options,
            markup: markupForRendering,
            markupCanvasSize: markupSizeForRendering
        )
        onComplete(rendered)
        dismiss()
    }

    private var markupForRendering: Any? {
#if canImport(PencilKit)
        markup.drawing
#else
        nil
#endif
    }

    private var markupSizeForRendering: CGSize {
#if canImport(PencilKit)
        markupCanvasSize
#else
        .zero
#endif
    }

    private var renderedImageForSharing: UIImage? {
        PhotoEditRenderer.render(
            resource: resource,
            geometry: geometry,
            options: options,
            markup: markupForRendering,
            markupCanvasSize: markupSizeForRendering
        )?.uiImage
    }
}
#endif
