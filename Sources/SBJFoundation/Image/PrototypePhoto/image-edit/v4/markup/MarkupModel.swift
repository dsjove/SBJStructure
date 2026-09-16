import SwiftUI
import PencilKit
import ImageIO
import Observation

extension PKDrawing {
	var hasEdits: Bool {
		!strokes.isEmpty
	}
}

public extension UIImage {
	@MainActor
	func render(_ model: ImageFraming, overlay: PKDrawing) -> UIImage {
		render(model) {
			// Composite PKDrawing over the base image in the same transformed space.
			// We avoid scaling and offset here per the comments; only mirror and rotation are applied by render(model, overlay: () -> ()).
			let rect = CGRect(origin: .zero, size: self.size)
			let scale = UIScreen.main.scale
			let overlayImage = overlay.image(from: rect, scale: scale)
			overlayImage.draw(in: CGRect(x: -self.size.width / 2,
										 y: -self.size.height / 2,
										 width: self.size.width,
										 height: self.size.height))
		}
	}
}

@MainActor
@Observable
final class MarkupModel {
	var showMarkup: Bool = false {
		didSet {
			ensureToolPickerVisible(showMarkup)
		}
	}

	private var drawing: PKDrawing = PKDrawing() {
		didSet {
			updateUndoState()
		}
	}
	private var toolPicker: PKToolPicker = PKToolPicker()

	@ObservationIgnored
	private weak var canvasView: PKCanvasView?

	init(showMarkup: Bool = false) {
		self.showMarkup = showMarkup
	}

	@ViewBuilder
	func render(contentSize: CGSize, fittedSize: CGSize) -> some View {
		@Bindable var model = self
		PencilCanvasView(
			drawing: $model.drawing,
			isActive: $model.showMarkup,
			contentSize: contentSize,
			fittedSize: fittedSize,
			onMake: { view in
				self.attach(view)
			})
			.frame(width: fittedSize.width, height: fittedSize.height)
			.contentShape(Rectangle())
	}

	private func attach(_ canvasView: PKCanvasView) {
		self.canvasView = canvasView
		toolPicker.addObserver(canvasView)
		if canvasView.drawing != drawing {
			canvasView.drawing = drawing
		}
		if showMarkup {
			ensureToolPickerVisible(true)
		}
	}

	func onAppear() {
		if showMarkup {
			ensureToolPickerVisible(true)
		}
	}

	func hide() {
		syncFromCanvas()
		if showMarkup {
			ensureToolPickerVisible(false)
		}
	}

	func unhide() {
		if showMarkup {
			ensureToolPickerVisible(true)
		}
	}

	func onDisappear() {
		if let canvasView {
			syncFromCanvas()
			toolPicker.setVisible(false, forFirstResponder: canvasView)
			toolPicker.removeObserver(canvasView)
			canvasView.resignFirstResponder()
		}
	}

	@discardableResult
	func syncFromCanvas() -> PKDrawing {
		guard let canvasView else {
			return drawing
		}
		canvasView.endEditing(true)
		let snapshot = canvasView.drawing
		if drawing != snapshot {
			drawing = snapshot
		}
		return snapshot
	}

	func clear() {
		let empty = PKDrawing()
		drawing = empty
		canvasView?.drawing = empty
	}

	func undo() {
		canvasView?.undoManager?.undo()
		syncFromCanvas()
	}

	func redo() {
		canvasView?.undoManager?.redo()
		syncFromCanvas()
	}

	private(set) var hasUndo: Bool = false
	private(set) var hasRedo: Bool = false

	private func updateUndoState() {
		guard let undoManager = canvasView?.undoManager else {
			hasUndo = false
			hasRedo = false
			return
		}
		hasUndo = undoManager.canUndo
		hasRedo = undoManager.canRedo
	}

	private func ensureToolPickerVisible(_ visible: Bool) {
		guard let canvasView else {
			return
		}
		toolPicker.setVisible(visible, forFirstResponder: canvasView)
		if visible {
			canvasView.becomeFirstResponder()
		} else {
			canvasView.resignFirstResponder()
		}
	}
}

