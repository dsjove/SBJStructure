import SwiftUI
#if !os(watchOS)
import PencilKit

@MainActor
final class MarkupModel2: ObservableObject {
	@Published var drawing: PKDrawing
	@Published var canvasView: PKCanvasView
	let toolPicker: PKToolPicker

	init() {
		self.drawing = PKDrawing()
		self.canvasView = PKCanvasView()
		self.toolPicker = PKToolPicker()
	}

	func overlay(frame: CGRect, hitTest: Bool = true) -> some View {
		PencilCanvasOverlay(
			canvasView: Binding<PKCanvasView>(
				get: { self.canvasView },
				set: { self.canvasView = $0 }
			),
			drawing: Binding<PKDrawing>(
				get: { self.drawing },
				set: { self.drawing = $0 }
			)
		)
			.allowsHitTesting(hitTest)
			.frame(width: frame.width, height: frame.height)
			.position(x: frame.midX, y: frame.midY)
			.onAppear {
				self.canvasView.drawing = self.drawing
				self.canvasView.isOpaque = false
				self.canvasView.backgroundColor = .clear
				self.canvasView.setNeedsDisplay()
				self.toolPicker.setVisible(hitTest, forFirstResponder: self.canvasView)
				self.toolPicker.addObserver(self.canvasView)
				self.canvasView.becomeFirstResponder()
			}
			.onChange(of: hitTest) { _, newValue in
				self.toolPicker.setVisible(newValue, forFirstResponder: self.canvasView)
				if newValue {
					self.canvasView.becomeFirstResponder()
				} else {
					self.canvasView.resignFirstResponder()
				}
			}
			.onDisappear {
				self.toolPicker.setVisible(false, forFirstResponder: self.canvasView)
				self.toolPicker.removeObserver(self.canvasView)
				self.canvasView.resignFirstResponder()
			}
	}

	func clear() {
		canvasView.drawing = PKDrawing()
		drawing = PKDrawing()
	}

	func undo() {
		canvasView.undoManager?.undo()
		drawing = canvasView.drawing
	}

	func redo() {
		canvasView.undoManager?.redo()
		drawing = canvasView.drawing
	}

	func render(on base: UIImage, in cropSize: CGSize? = nil) -> UIImage {
		guard !drawing.strokes.isEmpty else { return base }

		let size = cropSize ?? base.size
		let renderRect = CGRect(origin: .zero, size: size)
		let format = UIGraphicsImageRendererFormat()
		format.scale = UIScreen.main.scale
		let renderer = UIGraphicsImageRenderer(size: size, format: format)

		let composed = renderer.image { ctx in
			base.draw(in: renderRect)
			let drawingImage = drawing.image(from: renderRect, scale: UIScreen.main.scale)
			drawingImage.draw(in: renderRect)
		}
		return composed
	}
}

#endif
