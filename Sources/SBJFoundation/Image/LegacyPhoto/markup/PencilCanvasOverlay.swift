#if !os(watchOS)
import SwiftUI
import UIKit
import PencilKit

public struct PencilCanvasOverlay: UIViewRepresentable {
	@Binding public var canvasView: PKCanvasView
	@Binding public var drawing: PKDrawing

	public func makeCoordinator() -> Coordinator {
		Coordinator(drawing: $drawing)
	}

	public func makeUIView(context: Context) -> PKCanvasView {
		canvasView.drawing = drawing
		canvasView.isOpaque = false
		canvasView.backgroundColor = .clear
		canvasView.setNeedsDisplay()
		canvasView.drawingPolicy = .anyInput
		canvasView.delegate = context.coordinator
		return canvasView
	}

	public func updateUIView(_ uiView: PKCanvasView, context: Context) {
		if uiView.drawing != drawing {
			uiView.drawing = drawing
			uiView.setNeedsDisplay()
		}
	}

	public class Coordinator: NSObject, PKCanvasViewDelegate {
		@Binding var drawing: PKDrawing

		public init(drawing: Binding<PKDrawing>) {
			_drawing = drawing
		}

		public func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
			drawing = canvasView.drawing
		}
	}
}
#endif
