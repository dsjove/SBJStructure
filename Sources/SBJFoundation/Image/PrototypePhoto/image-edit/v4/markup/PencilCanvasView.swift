import SwiftUI
import PencilKit
import Observation

struct PencilCanvasView: UIViewRepresentable {
	@Binding var drawing: PKDrawing
	@Binding var isActive: Bool

	let contentSize: CGSize
	let fittedSize: CGSize
	let onMake: (PKCanvasView) -> Void

	func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	func makeUIView(context: Context) -> PKCanvasView {
		let canvas = PKCanvasView()
		canvas.backgroundColor = .clear
		canvas.isOpaque = false
		canvas.drawing = drawing
		canvas.drawingPolicy = .anyInput
		canvas.delegate = context.coordinator

		canvas.isScrollEnabled = false
		canvas.alwaysBounceHorizontal = false
		canvas.alwaysBounceVertical = false
		canvas.showsHorizontalScrollIndicator = false
		canvas.showsVerticalScrollIndicator = false
		canvas.minimumZoomScale = 1
		canvas.maximumZoomScale = 1

		configure(canvas)

		onMake(canvas)
		return canvas
	}

	func updateUIView(_ uiView: PKCanvasView, context: Context) {
		if uiView.drawing != drawing {
			if drawing.strokes.isEmpty && !uiView.drawing.strokes.isEmpty {
				drawing = uiView.drawing
			} else {
				uiView.drawing = drawing
			}
		}

		uiView.isUserInteractionEnabled = isActive
		configure(uiView)
	}

	private func configure(_ canvas: PKCanvasView) {
		guard contentSize.width > 0,
			  contentSize.height > 0,
			  fittedSize.width > 0,
			  fittedSize.height > 0
		else {
			return
		}

		let zoomScale = min(
			fittedSize.width / contentSize.width,
			fittedSize.height / contentSize.height)

		canvas.contentSize = contentSize
		canvas.minimumZoomScale = zoomScale
		canvas.maximumZoomScale = zoomScale
		canvas.zoomScale = zoomScale
		canvas.contentOffset = .zero
	}

	final class Coordinator: NSObject, PKCanvasViewDelegate {
		var parent: PencilCanvasView

		init(_ parent: PencilCanvasView) {
			self.parent = parent
		}

		func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
			parent.drawing = canvasView.drawing
		}
	}
}
