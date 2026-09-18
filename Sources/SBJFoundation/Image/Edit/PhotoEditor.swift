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
    private let onComplete: ((SBJResourceContent?) -> Void)?
    private let onEditComplete: ((PhotoEditResult?) -> Void)?
    private let initialColorAdjustments: PhotoColorAdjustments
    private let allowsUnchangedCompletion: Bool

    @Environment(\.dismiss) private var dismiss
    @State private var editState: PhotoEditState
    @State private var canvasSize: CGSize = .zero
    @State private var dragStartGeometry: PhotoEditGeometry?
    @State private var magnificationStartGeometry: PhotoEditGeometry?
    @State private var freeCropStartAspect: Double?
    @State private var freeCropStartFrameSize: CGSize?
    /// UI preference only; persisted independently from image edit state.
    @AppStorage("SBJFoundation.PhotoEditor.isRotationVisible")
    private var isRotationVisible = false
#if canImport(PencilKit)
    @State private var markup: PhotoMarkupState
    @AppStorage("SBJFoundation.PhotoEditor.markupActive")
    private var markupActive = false
#endif

    public init?(
        resource: SBJResourceContent,
        title: String? = nil,
        options: PhotoEditorOptions = .default,
        allowsUnchangedCompletion: Bool = false,
        onComplete: @escaping (SBJResourceContent?) -> Void
    ) {
        guard let image = resource.uiImage else { return nil }
        self.resource = resource
        self.image = image
        self.title = title
        self.options = options
        self.onComplete = onComplete
        self.onEditComplete = nil
        self.initialColorAdjustments = .init()
        self.allowsUnchangedCompletion = allowsUnchangedCompletion

        let initialCrop = options.cropOptions.first ?? .none
        let initial = PhotoEditGeometry(crop: .init(option: initialCrop, sourceSize: image.size))
        self._editState = State(initialValue: PhotoEditState(
            geometry: initial,
            sourceSize: image.size,
            options: options
        ))
#if canImport(PencilKit)
        self._markup = State(initialValue: PhotoMarkupState())
#endif
    }

    /// Edits reusable in-memory state without flattening it. Callers may persist the result
    /// in an `SBJImageDocument` or render it destructively themselves.
    public init?(
        resource: SBJResourceContent,
        edits: PhotoEditResult,
        title: String? = nil,
        options: PhotoEditorOptions = .default,
        allowsUnchangedCompletion: Bool = false,
        onComplete: @escaping (PhotoEditResult?) -> Void
    ) {
        guard let image = resource.uiImage else { return nil }
        self.resource = resource
        self.image = image
        self.title = title
        self.options = options
        self.onComplete = nil
        self.onEditComplete = onComplete
        self.initialColorAdjustments = edits.color
        self.allowsUnchangedCompletion = allowsUnchangedCompletion
        self._editState = State(initialValue: PhotoEditState(
            geometry: edits.geometry,
            initialGeometry: edits.geometry,
            sourceSize: image.size,
            options: options,
            prepareForEditing: true
        ))
#if canImport(PencilKit)
        self._markup = State(initialValue: PhotoMarkupState(
            drawing: edits.markup?.pencilKitDrawing ?? PKDrawing(),
            canvasSize: edits.markup?.canvasSize.cgSize ?? .zero
        ))
#endif
    }

    /// Convenience non-destructive document editor. The source remains unchanged; completion
    /// atomically applies the edit state and rebuilds the persisted thumbnail cache.
    public init?(
        document: SBJImageDocument,
        title: String? = nil,
        options: PhotoEditorOptions = .default,
        allowsUnchangedCompletion: Bool = false,
        onComplete: @escaping (SBJImageDocument?) -> Void
    ) {
        let input = document.editorInput
        self.init(
            resource: input.source,
            edits: input.edits,
            title: title,
            options: options,
            allowsUnchangedCompletion: allowsUnchangedCompletion
        ) { edits in
            guard let edits else {
                onComplete(nil)
                return
            }
            onComplete(document.applying(edits, options: options))
        }
    }

    public var body: some View {
        SBJSharePresentationHost { sharePresenter in
            NavigationStack {
                GeometryReader { proxy in
                    editorCanvas(size: proxy.size)
                        .onChange(of: proxy.size, initial: true) { _, size in
                            canvasSize = size
                            editState.updateContainerSize(size)
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

    private var geometry: PhotoEditGeometry { editState.geometry }

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
                    PhotoMarkupCanvas(
                        model: markup,
                        isActive: markupActive
                    )
                        .background {
                            GeometryReader { proxy in
                                Color.clear
                                    .onAppear { markup.updateCanvasSize(proxy.size) }
                                    .onChange(of: proxy.size) { _, newSize in
                                        markup.updateCanvasSize(newSize)
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
                                        editState.resizeFreeCrop(to: Double(newWidth / newHeight))
                                    }
                                    .onEnded { _ in
                                        freeCropStartAspect = nil
                                        freeCropStartFrameSize = nil
                                    }
                            )
                            .accessibility(freeCropInfo)
                    }
                }
            }
            .position(x: layout.frameRect.midX, y: layout.frameRect.midY)
        }
        .contentShape(Rectangle())
        .photoEditGesture(enabled: geometry.crop.option != .none && !isMarkupActive, editGesture())
        .onTapGesture(count: 2) {
            guard geometry.crop.option != .none, !isMarkupActive else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                editState.resetPlacementAndMagnification()
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

    /// Toolbar presentation follows the space actually available to this editor,
    /// rather than the horizontal size class. iPad-designed apps can run in a
    /// phone-sized compatibility window while still reporting a regular size class.
    private var usesCompactToolbar: Bool {
        canvasSize.width < 600
    }

    private func editGesture() -> some Gesture {
        SimultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let start = dragStartGeometry ?? geometry
                    if dragStartGeometry == nil { dragStartGeometry = start }
                    editState.pan(from: start, by: value.translation)
                }
                .onEnded { _ in dragStartGeometry = nil },
            MagnificationGesture()
                .onChanged { value in
                    let start = magnificationStartGeometry ?? geometry
                    if magnificationStartGeometry == nil { magnificationStartGeometry = start }
                    editState.magnify(from: start, by: Double(value))
                }
                .onEnded { _ in magnificationStartGeometry = nil }
        )
    }

    @ToolbarContentBuilder
    private func toolbar(sharePresenter: SBJSharePresenter) -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Button("Cancel", role: .cancel) {
                cancel()
            }

            if options.allowsShare {
                Button {
                    guard !sharePresenter.isPresenting,
                          let renderedImageForSharing else { return }
                    _ = sharePresenter.present(SBJSharePayload(renderedImageForSharing))
                } label: {
                    Image(SBJSemanticImageReference.share)
                        .accessibility(AccessibleItem(label: "Share Edited Photo"))
                }
                .disabled(sharePresenter.isPresenting)
            }

			if usesCompactToolbar {
	#if canImport(PencilKit)
				if options.allowsMarkup && markup.extendedToolsSupported {
					markupToggleButton
				}
	#endif
			}
        }

        if usesCompactToolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
				SBJHelpLink(
					asset: .imageEdit,
					auto: false,
					configuration: .image
				)
                doneButton
            }

            ToolbarItemGroup(placement: .bottomBar) {
#if canImport(PencilKit)
                if options.allowsMarkup, markupActive, markup.extendedToolsSupported {
                    compactMarkupActions
                } else {
                    geometryToolbarButtons
                }
#else
                geometryToolbarButtons
#endif
            }
        } else {
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

                if options.allowsMarkup && markup.extendedToolsSupported {
                    markupToggleButton
                }
#else
                geometryToolbarButtons
#endif
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                doneButton
            }
        }
    }

    @ViewBuilder
    private var doneButton: some View {
        Button("Done") {
            complete()
        }
        .fontWeight(.semibold)
        .disabled(!canComplete)
        .opacity(canComplete ? 1 : 0.35)
    }

#if canImport(PencilKit)
    @ViewBuilder
    private var markupToggleButton: some View {
        SBJImageButton(
            markupActive ? SBJImageSemanticImageReference.hideMarkup : SBJImageSemanticImageReference.markup,
            accessibilityLabel: markupActive ? "Hide Markup Tools" : "Show Markup Tools"
        ) {
            markupActive.toggle()
        }
    }
#endif

#if canImport(PencilKit)
    @ViewBuilder
    private var compactMarkupActions: some View {
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
    }
#endif

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
                editState.toggleMirror(.horizontal)
            }
            .accessibilityValue(geometry.mirror.horizontal ? "On" : "Off")
        }

        if options.allowsQuarterTurnRotation {
            SBJImageButton(
                SBJImageSemanticImageReference.rotateLeft,
                accessibilityLabel: "Rotate Left 90 Degrees",
                accessibilityHint: quarterTurnInfo.accessibilityHint ?? quarterTurnInfo.summary
            ) {
                rotate(clockwise: false)
            }
        }

        if options.availableMirrorAxes.contains(.vertical) {
            SBJImageButton(
                SBJImageSemanticImageReference.mirrorVertical,
                propertyInfo: verticalMirrorInfo
            ) {
                editState.toggleMirror(.vertical)
            }
            .accessibilityValue(geometry.mirror.vertical ? "On" : "Off")
        }

        if options.allowsFreeRotation {
            SBJImageButton(
                SBJImageSemanticImageReference.straighten,
                propertyInfo: straightenInfo
            ) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRotationVisible.toggle()
                }
            }
            .accessibilityValue(isRotationVisible ? "Control Shown" : "Control Hidden")
        }
    }

    @ViewBuilder
    private var straightenOverlay: some View {
        if !isMarkupActive && options.allowsFreeRotation && isRotationVisible {
            HStack {
                Text("Straighten")
                    .font(.caption)

                if options.allowsQuarterTurnRotation {
                    SBJImageButton(
                        SBJImageSemanticImageReference.rotateLeft,
                        accessibilityLabel: "Rotate Left 90 Degrees",
                        accessibilityHint: quarterTurnInfo.accessibilityHint ?? quarterTurnInfo.summary
                    ) {
                        rotate(clockwise: false)
                    }
                }

                Slider(value: fineRotationBinding, in: -15...15)
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
                        rotate(clockwise: true)
                    }
                }

                SBJImageButton(
                    SBJImageSemanticImageReference.resetStraighten,
                    accessibilityLabel: "Reset Straighten",
                    accessibilityHint: straightenInfo.summary,
                    action: resetRotation
                )
                .disabled(!hasStraightenEdit)
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

    private var fineRotationBinding: Binding<Double> {
        Binding(
            get: { geometry.rotation.fineDegrees },
            set: { degrees in
                editState.setFineRotation(degrees)
            }
        )
    }

    private var cropDimensionsSwappedBinding: Binding<Bool> {
        Binding(
            get: { geometry.crop.swapsDimensions },
            set: { isSwapped in
                editState.setCropDimensionsSwapped(isSwapped)
            }
        )
    }

    private func setCrop(_ option: PhotoCropOption) {
        editState.selectCrop(option)
    }

    private var hasGeometryEdits: Bool {
        editState.hasGeometryEdits
    }

    /// Reset controls describe the semantic neutral value of that adjustment,
    /// not the value that happened to be present when this editing session opened.
    /// This matters for re-editing a non-destructive document: a saved pan/zoom
    /// or straighten value must still be resettable back to the unadjusted state.
    private var hasPlacementOrMagnificationEdits: Bool {
        editState.hasPlacementOrMagnificationEdits
    }

    private var hasStraightenEdit: Bool {
        editState.hasStraightenEdit
    }

    private var canComplete: Bool {
        hasEdits || allowsUnchangedCompletion
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

    private func resetPlacementAndMagnification() {
        editState.resetPlacementAndMagnification()
        dragStartGeometry = nil
        magnificationStartGeometry = nil
    }

    private func rotate(clockwise: Bool) {
        editState.rotate(clockwise: clockwise)
    }

    private func resetRotation() {
        editState.resetRotation()
    }

    private func resetStraighten() {
        editState.resetStraighten()
    }

    private func cancel() {
        // The editor owns its presentation dismissal. Deliver the cancellation
        // after SwiftUI has begun dismissing so a parent that also clears its
        // presentation binding does not race the local dismiss action.
        dismiss()
        Task { @MainActor in
            await Task.yield()
            onComplete?(nil)
            onEditComplete?(nil)
        }
    }

    private func complete() {
        let resourceResult: SBJResourceContent?
        let editResult: PhotoEditResult?

        if !requiresRendering {
            resourceResult = resource
            editResult = currentEditResult
        } else {
            resourceResult = PhotoEditRenderer.render(
                resource: resource,
                geometry: geometry,
                options: options,
                markup: markupForRendering,
                markupCanvasSize: markupSizeForRendering
            )
            editResult = currentEditResult
        }

        dismiss()
        Task { @MainActor in
            await Task.yield()
            if let onEditComplete {
                onEditComplete(editResult)
            } else {
                onComplete?(resourceResult)
            }
        }
    }

    private var currentEditResult: PhotoEditResult {
        PhotoEditResult(
            geometry: geometry,
            color: initialColorAdjustments,
            markup: currentMarkup
        )
    }

    private var currentMarkup: PhotoMarkup? {
#if canImport(PencilKit)
        markup.markup
#else
        nil
#endif
    }

    private var markupForRendering: Any? {
#if canImport(PencilKit)
        markup.drawingForRendering
#else
        nil
#endif
    }

    private var markupSizeForRendering: CGSize {
#if canImport(PencilKit)
        markup.canvasSizeForRendering
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
