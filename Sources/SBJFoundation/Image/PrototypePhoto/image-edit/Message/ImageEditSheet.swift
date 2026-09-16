import SwiftUI
import PencilKit
import ImageIO
import Observation

public struct ImageEditSheet<Doc: ImageEditSource>: View {
	@Environment(\.dismiss) private var dismiss

	let zoomEnabled: Bool
	let cropEnabled: Bool
	let doc: Doc
	let image: UIImage
	let showTools: Binding<Bool>
	let onComplete: ((Doc?) -> Void)?

	@State private var markupModel: MarkupModel?
	@State private var geometryModel: GeometryModel

	public init(
		markupEnabled: Bool = true,
		zoomEnabled: Bool = true,
		cropEnabled: Bool = false,
		doc: Doc,
		showTools: Binding<Bool>,
		onComplete: ((Doc?) -> Void)? = nil)
	{
		self.zoomEnabled = zoomEnabled
		self.cropEnabled = cropEnabled
		self.doc = doc
		self.image = doc.image
		self.showTools = showTools
		self.onComplete = onComplete

		self._markupModel = .init(initialValue: markupEnabled ? .init(showMarkup: showTools.wrappedValue) : nil)
		self._geometryModel = .init(initialValue: .init(sourceSize: image.size))
	}

	var editedDoc: Doc {
		let snapshot = markupModel?.syncFromCanvas()
		guard let snapshot else { return doc }
		return doc.consume(geometryModel, snapshot)
	}

	public var body: some View {
		NavigationStack {
			GeometryReader { geometry in
				let frameSize = geometryModel.frameSize
				ZStack {
					Color.black.ignoresSafeArea()
					if zoomEnabled && geometryModel.isNotInFrame {
						Rectangle()
							.stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [6, 6]))
							.frame(width: frameSize.width, height: frameSize.height)
							.allowsHitTesting(false)
					}
					if cropEnabled {
						ZStack {
							Image(uiImage: image)
								.resizable()
								.aspectRatio(contentMode: .fit)
								.frame(width: frameSize.width, height: frameSize.height)
						}
						.opacity(0.3)
						.apply(geometryModel, clip: false)
					}
					ZStack {
						Image(uiImage: image)
							.resizable()
							.aspectRatio(contentMode: .fit)
							.frame(width: frameSize.width, height: frameSize.height)
						markupModel?.render(contentSize: image.size, fittedSize: frameSize)
					}
					.apply(geometryModel, clip: cropEnabled)
				}
				.onChange(of: geometry.size) { _, newSize in
					geometryModel.containerSize = newSize
				}
				.gesture(geometryModel, enabled: zoomEnabled && !showTools.wrappedValue)
				.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
			}
			.onAppear {
				markupModel?.onAppear()
				markupModel?.showMarkup = showTools.wrappedValue
			}
			.onDisappear {
				markupModel?.onDisappear()
			}
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItemGroup(placement: .topBarLeading) {
					if let onComplete {
						ActionButton(ImageEditContinue()) {
							let result = editedDoc
							dismiss()
							onComplete(result)
						}
						DeleteButton(ImageDeleteNoun, accessibilityHint: ImageDeleteHint) {
							dismiss()
							onComplete(nil)
						}
					} else {
						DismissButton() {
							dismiss()
						}
					}
					ShareButton(ImageDeleteNoun) {
						editedDoc.sharing
					} appear: {
						markupModel?.hide()
					} dismissed: {
						markupModel?.unhide()
					}
				}
				ToolbarItemGroup(placement: .topBarTrailing) {
				HStack(spacing: 2) {
					if let markupModel, showTools.wrappedValue {
						ActionButton(MarkupClear()) {
							markupModel.clear()
						}
						ActionButton(MarkupUndo(redo: false)) {
							markupModel.undo()
						}
						.disabled(!markupModel.hasUndo)
						ActionButton(MarkupUndo(redo: true)) {
							markupModel.redo()
						}
						.disabled(!markupModel.hasRedo)
					} else if cropEnabled {
//						TODO: crop style: original portions, square
					} else if zoomEnabled {
						ActionButton(ImageZoomReset()) {
							geometryModel.resetZoom()
						}
					}
					if let markupModel {
						if !showTools.wrappedValue{
							ActionButton(ImageMirror(mirror: geometryModel.mirror)) {
								geometryModel.flip()
							}
//							ActionButton(ImageRotate(clockwise: true)) {
//								geometryModel.rotate(clockwise: true)
//							}
						}
						ActionButton(MarkupToolsToggle(enabled: showTools.wrappedValue)) {
							showTools.wrappedValue.toggle()
							markupModel.showMarkup = showTools.wrappedValue
						}
					}
				}
				}
			}
		}
	}
}
