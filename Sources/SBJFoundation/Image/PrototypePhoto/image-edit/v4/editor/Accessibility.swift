import SwiftUI

let ImageDeleteNoun = "Photo"
let ImageDeleteHint = "Cancel this captured photo."

public struct ImageZoomReset: AccessibleImage {
	public var image: ImageName { .system("inset.filled.square.dashed") }
	public var label: String { "Reset Zoom" }
}

public struct ImageRotate: AccessibleImage {
	let clockwise: Bool
	public var image: ImageName { .system(clockwise ? "rotate.right" :"rotate.left") }
	public var label: String { clockwise ? "Rotate Clockwise" : "Rotate Counterclockwise" }
}

struct ImageEditContinue: AccessibleImage {
	var image: ImageName { .system("hand.thumbsup") }
	var label: String { "Done Editing" }
}

struct MarkupToolsToggle: AccessibleImage {
	let enabled: Bool
	var image: ImageName { .system(enabled ? "pencil.slash" : "pencil.tip") }
	var label: String { enabled ? "Hide Markup Tools" : "Show Markup Tools" }
}

struct MarkupClear: AccessibleImage {
	var image: ImageName { .system("eraser") }
	var label: String { "Clear Markup" }
}

struct MarkupUndo: AccessibleImage {
	let redo: Bool
	var image: ImageName { .system(redo ? "arrow.uturn.forward" : "arrow.uturn.backward") }
	var label: String { redo ? "Markup Redo" : "Markup Undo" }
}

struct ImageMirror: AccessibleImage {
	let mirror: GeometricMirror
	var image: ImageName {
		let name = {
			if mirror.horizontalOnly {
				return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
			}
			if !mirror.horizontal {
				if !mirror.vertical {
					return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right"
				}
				return "arrow.trianglehead.up.and.down.righttriangle.up.righttriangle.down.fill"
			}
			if mirror.vertical {
				return "arrow.trianglehead.left.and.right.righttriangle.left.righttriangle.right.fill"
			}
			return "arrow.trianglehead.up.and.down.righttriangle.up.righttriangle.down"
		}()
		return .system(name)
	}
	var label: String {
		if mirror.horizontalOnly {
			return "Flip"
		}
		if !mirror.horizontal {
			if !mirror.vertical {
				return "Flip Horizontal"
			}
			return "Reset Flip"
		}
		if mirror.vertical {
			return "Flip Vertical"
		}
		return "Flip Horizontal and Vertical"
	}
}
