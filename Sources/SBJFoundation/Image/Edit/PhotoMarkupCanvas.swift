#if !os(watchOS) && !os(tvOS) && canImport(UIKit) && canImport(PencilKit)
import Observation
import PencilKit
import SwiftUI

@MainActor
@Observable
final class PhotoMarkupState {
    var drawing = PKDrawing()
    var canUndo = false
    var canRedo = false
    weak var canvas: PKCanvasView?

    var hasDrawing: Bool { !drawing.bounds.isEmpty }

    func clear() {
        drawing = PKDrawing()
        canvas?.drawing = drawing
        canvas?.undoManager?.removeAllActions()
        refreshUndoState()
    }

    func undo() {
        canvas?.undoManager?.undo()
        syncFromCanvas()
    }

    func redo() {
        canvas?.undoManager?.redo()
        syncFromCanvas()
    }

    func syncFromCanvas() {
        if let canvas { drawing = canvas.drawing }
        refreshUndoState()
    }

    func refreshUndoState() {
        canUndo = canvas?.undoManager?.canUndo ?? false
        canRedo = canvas?.undoManager?.canRedo ?? false
    }
}

struct PhotoMarkupCanvas: UIViewRepresentable {
    let model: PhotoMarkupState
    let isActive: Bool
    let toolPicker: PKToolPicker

    func makeCoordinator() -> Coordinator {
        Coordinator(model: model)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let view = PKCanvasView()
        view.backgroundColor = .clear
        view.isOpaque = false
        view.drawingPolicy = .anyInput
        view.delegate = context.coordinator
        view.drawing = model.drawing
        model.canvas = view
        return view
    }

    func updateUIView(_ view: PKCanvasView, context: Context) {
        model.canvas = view
        view.isUserInteractionEnabled = isActive
        toolPicker.setVisible(isActive, forFirstResponder: view)
        toolPicker.addObserver(view)
        if isActive {
            DispatchQueue.main.async { view.becomeFirstResponder() }
        } else {
            view.resignFirstResponder()
        }
        model.refreshUndoState()
    }

    static func dismantleUIView(_ uiView: PKCanvasView, coordinator: Coordinator) {
        uiView.resignFirstResponder()
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        let model: PhotoMarkupState

        init(model: PhotoMarkupState) {
            self.model = model
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            model.drawing = canvasView.drawing
            model.refreshUndoState()
        }
    }
}
#endif
