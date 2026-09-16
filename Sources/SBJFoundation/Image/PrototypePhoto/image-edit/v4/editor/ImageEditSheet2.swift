import SwiftUI
import PencilKit
import ImageIO
import Observation

public struct ImageEditSheet2<Doc: ImageEditSource>: View {
	@Environment(\.dismiss) private var dismiss

	let zoomEnabled: Bool
	let cropEnabled: Bool
	let doc: Doc
	let image: UIImage
	let showTools: Binding<Bool>
	let onComplete: ((Doc?) -> Void)?

	@State private var markupModel: MarkupModel?
	@State private var geometryModel: RectangleFraming

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
		self._geometryModel = .init(initialValue: .init(sourceSize: image.size, mirrorHorizOnly: true))
	}

	var editedDoc: Doc {
		let snapshot = markupModel?.syncFromCanvas()
		guard let snapshot else { return doc }
		return doc.consume(geometryModel, snapshot)
	}

	public var body: some View {
		NavigationStack {
			RectangleFramingView(model: geometryModel) {
				ZStack {
					Color.black.ignoresSafeArea()
					Image(uiImage: image).resizable()
						.apply(geometryModel)
						.gesture(geometryModel, enabled: !showTools.wrappedValue)
//					markupModel?.render(contentSize: image.size, fittedSize: geometryModel.frameSize)
				}
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
							geometryModel.resetPosition()
						}
					}
					if let markupModel {
						if !showTools.wrappedValue{
							ActionButton(ImageMirror(mirror: geometryModel.mirror)) {
								geometryModel.flip()
							}
							ActionButton(ImageRotate(clockwise: true)) {
								geometryModel.rotate(clockwise: true)
							}
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

struct PreviewDoc: @MainActor ImageEditDataSource {
	let blob: Data
	let utiType: String
	let name: String

	init() {
		let configuration = UIImage.SymbolConfiguration(
			pointSize: 718,
			weight: .regular,
			scale: .large
		)

		let previewImage = UIImage(
			systemName: "photo.fill",
			withConfiguration: configuration
		)!

		self.init(blob: previewImage.jpegData(compressionQuality: 1.0)!, name: "Preview", utiType: "public.image")
	}

	init(blob: Data, name: String, utiType: String) {
		self.blob = blob
		self.name = name
		self.utiType = utiType
	}
}

#Preview("ImageEditSheet2 Preview") {
    @Previewable @State var value = false
	ImageEditSheet2(doc: PreviewDoc(), showTools: $value)
}
