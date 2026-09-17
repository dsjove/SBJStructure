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

        let initialCrop = options.cropOptions.first ?? .none
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

            if geometry.crop.option != .none, options.renderCropGhost > 0 {
                transformedImage(layout: layout)
                    .position(layout.imageCenter)
                    .opacity(min(options.renderCropGhost, 1))
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
                if geometry.crop.option != .none {
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
                            .accessibility(freeCropInfo)
                    }
                }
            }
            .position(x: layout.frameRect.midX, y: layout.frameRect.midY)
        }
        .contentShape(Rectangle())
        .photoEditGesture(enabled: geometry.crop.option != .none && !isMarkupActive, editGesture(layout: layout))
        .onTapGesture(count: 2) {
            guard geometry.crop.option != .none, !isMarkupActive else { return }
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
                        .accessibility(AccessibleItem(label: "Share Edited Photo"))
                }
            }

            SBJHelpLink(
                asset: .imageEdit,
                auto: false,
                configuration: .image
            )
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
#if canImport(PencilKit)
            if options.allowsMarkup, markupActive {
                SBJImageButton(
                    SBJImageSemanticImageReference.eraseMarkup,
                    accessibilityLabel: "Clear Markup",
                    action: markup.clear
                )
                .disabled(!markup.hasDrawing)

                SBJImageButton(
                    SBJImageSemanticImageReference.undoMarkup,
                    accessibilityLabel: "Undo Markup",
                    action: markup.undo
                )
                .disabled(!markup.canUndo)

                SBJImageButton(
                    SBJImageSemanticImageReference.redoMarkup,
                    accessibilityLabel: "Redo Markup",
                    action: markup.redo
                )
                .disabled(!markup.canRedo)
            } else {
                geometryToolbarButtons
            }

            if options.allowsMarkup {
                SBJImageButton(
                    markupActive ? SBJImageSemanticImageReference.hideMarkup : SBJImageSemanticImageReference.markup,
                    accessibilityLabel: markupActive ? "Hide Markup Tools" : "Show Markup Tools"
                ) {
                    markupActive.toggle()
                }
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
        if !options.cropOptions.isEmpty {
            Menu {
                ForEach(options.cropOptions) { option in
                    Button {
                        setCrop(option)
                    } label: {
                        if geometry.crop.option == option {
                            Label(cropTitle(for: option), image: SBJSemanticImageReference.selected)
                        } else {
                            Text(cropTitle(for: option))
                        }
                    }
                    .labelStyle(.titleAndIcon)
                }

                Divider()

                Toggle(isOn: cropDimensionsSwappedBinding) {
                    Label("Swap Width & Height", image: SBJImageSemanticImageReference.swapCropDimensions)
                }
                .accessibility(swapDimensionsInfo)

                Button {
                    resetPlacementAndMagnification()
                } label: {
                    Label("Reset Pan & Zoom", image: SBJImageSemanticImageReference.resetPanZoom)
                }
                .disabled(!hasPlacementOrMagnificationEdits)
                .accessibility(
                    label: "Reset Pan and Zoom",
                    hint: "\(placementInfo.summary) \(magnificationInfo.summary)"
                )
            } label: {
                Image(SBJImageSemanticImageReference.crop)
            }
            .accessibility(cropOptionInfo)
            .accessibilityValue(currentCropTitle)
        }

        if options.availableMirrorAxes.contains(.horizontal) {
            SBJImageButton(
                SBJImageSemanticImageReference.mirrorHorizontal,
                propertyInfo: horizontalMirrorInfo
            ) {
                geometry.mirror.toggle(.horizontal)
            }
        }

        if options.allowsQuarterTurnRotation {
            SBJImageButton(
                SBJImageSemanticImageReference.rotateLeft,
                accessibilityLabel: "Rotate Left 90 Degrees",
                accessibilityHint: quarterTurnInfo.accessibilityHint ?? quarterTurnInfo.summary
            ) {
                geometry.rotation.rotate(clockwise: false)
                geometry = constrained(geometry)
            }
        }

        if options.availableMirrorAxes.contains(.vertical) {
            SBJImageButton(
                SBJImageSemanticImageReference.mirrorVertical,
                propertyInfo: verticalMirrorInfo
            ) {
                geometry.mirror.toggle(.vertical)
            }
        }

        if options.allowsFreeRotation {
            SBJImageButton(
                SBJImageSemanticImageReference.straighten,
                propertyInfo: straightenInfo
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showsStraightenControl.toggle()
                }
            }
            .accessibilityValue(showsStraightenControl ? "Control Shown" : "Control Hidden")
        }
    }

    @ViewBuilder
    private var straightenOverlay: some View {
        if !isMarkupActive && options.allowsFreeRotation && showsStraightenControl {
            HStack {
                Text("Straighten")
                    .font(.caption)

                if options.allowsQuarterTurnRotation {
                    SBJImageButton(
                        SBJImageSemanticImageReference.rotateLeft,
                        accessibilityLabel: "Rotate Left 90 Degrees",
                        accessibilityHint: quarterTurnInfo.accessibilityHint ?? quarterTurnInfo.summary
                    ) {
                        geometry.rotation.rotate(clockwise: false)
                        geometry = constrained(geometry)
                    }
                }

                Slider(value: $geometry.rotation.fineDegrees, in: -15...15)
                    .accessibility(straightenInfo)
                    .accessibilityValue(String(format: "%.1f degrees", geometry.rotation.fineDegrees))

                Text("\(geometry.rotation.degrees, specifier: "%.1f")°")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 54, alignment: .trailing)

                if options.allowsQuarterTurnRotation {
                    SBJImageButton(
                        SBJImageSemanticImageReference.rotateRight,
                        accessibilityLabel: "Rotate Right 90 Degrees",
                        accessibilityHint: quarterTurnInfo.accessibilityHint ?? quarterTurnInfo.summary
                    ) {
                        geometry.rotation.rotate(clockwise: true)
                        geometry = constrained(geometry)
                    }
                }

                SBJImageButton(
                    SBJImageSemanticImageReference.resetStraighten,
                    accessibilityLabel: "Reset Straighten",
                    accessibilityHint: straightenInfo.summary,
                    action: resetStraighten
                )
                .disabled(!hasStraightenEdit)
            }
            .onChange(of: geometry.rotation.fineDegrees) { _, _ in
                constrainCurrentGeometryIfNeeded()
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(.regularMaterial)
        }
    }

    private var cropOptionInfo: SBJPropertyInfo {
        PhotoCropState.propertyInfo(for: \PhotoCropState.option)!
    }

    private var freeCropInfo: SBJPropertyInfo {
        PhotoCropState.propertyInfo(for: \PhotoCropState.freeAspectRatio)!
    }

    private var swapDimensionsInfo: SBJPropertyInfo {
        PhotoCropState.propertyInfo(for: \PhotoCropState.swapsDimensions)!
    }

    private var horizontalMirrorInfo: SBJPropertyInfo {
        PhotoMirrorState.propertyInfo(for: \PhotoMirrorState.horizontal)!
    }

    private var verticalMirrorInfo: SBJPropertyInfo {
        PhotoMirrorState.propertyInfo(for: \PhotoMirrorState.vertical)!
    }

    private var placementInfo: SBJPropertyInfo {
        PhotoEditGeometry.propertyInfo(for: \PhotoEditGeometry.placement)!
    }

    private var magnificationInfo: SBJPropertyInfo {
        PhotoEditGeometry.propertyInfo(for: \PhotoEditGeometry.magnification)!
    }

    private var quarterTurnInfo: SBJPropertyInfo {
        PhotoRotation.propertyInfo(for: \PhotoRotation.quarterTurns)!
    }

    private var straightenInfo: SBJPropertyInfo {
        PhotoRotation.propertyInfo(for: \PhotoRotation.fineDegrees)!
    }

    private var currentCropTitle: String {
        cropTitle(for: geometry.crop.option)
    }

    private func cropTitle(for option: PhotoCropOption) -> String {
        option.title(swappingDimensions: geometry.crop.swapsDimensions)
    }

    private var cropDimensionsSwappedBinding: Binding<Bool> {
        Binding(
            get: { geometry.crop.swapsDimensions },
            set: { isSwapped in
                geometry.crop.swapsDimensions = isSwapped
                geometry.placement = .zero
                geometry.magnification = 1
                geometry = constrained(geometry)
            }
        )
    }

    private func setCrop(_ option: PhotoCropOption) {
        geometry.crop.option = option
        geometry.placement = .zero
        geometry.magnification = 1
        geometry = constrained(geometry)
    }

    private var hasGeometryEdits: Bool {
        effectiveGeometryForEditComparison(geometry)
            != effectiveGeometryForEditComparison(initialGeometry)
    }

    private func effectiveGeometryForEditComparison(_ value: PhotoEditGeometry) -> PhotoEditGeometry {
        var result = value
        guard case .ratio = result.crop.option else {
            result.crop.swapsDimensions = false
            return result
        }
        return result
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
        geometry.crop.option != .none || hasEdits
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
