import SwiftUI
import Observation

@Observable
public class GeometryModel {
	public init(sourceSize: CGSize, fitFrame: Bool? = true, maxScale: CGFloat = 8.0) {
		self.sourceSize = sourceSize
		self.fitFrame = fitFrame
		self.maxScale = maxScale
	}

// MARK: Framing
	public let fitFrame: Bool?

	public var containerSize: CGSize = .zero {
		didSet {
			if containerSize != oldValue {
				updateFrames()
			}
		}
	}

	public var sourceSize: CGSize = .zero {
		didSet {
			if sourceSize != oldValue {
				updateFrames()
			}
		}
	}

	//Rotation of content
	public var rotation: Angle = .zero {
		didSet {
			if rotation != oldValue {
				updateFrames()
			}
		}
	}

	//Source Size after rotation applied
	private(set) var rotatedSize: CGSize = .zero

	private func updateFrames() {
		rotatedSize = calcRotationSize()
		frameSize = calcframeSize()
	}

	//Rotated Size after placed in Container
	private(set) var frameSize: CGSize = .zero

	//Source Size after rotation applied
	func calcRotationSize(inside: Bool = true) -> CGSize {
		let w = sourceSize.width
		let h = sourceSize.height
		guard w > 0, h > 0 else { return .zero }

		let degRaw = rotation.degrees.truncatingRemainder(dividingBy: 360)
		let deg = degRaw < 0 ? degRaw + 360 : degRaw
		let epsilon: Double = 1e-7
		let is0   = abs(deg - 0)   < epsilon || abs(deg - 360) < epsilon
		let is180 = abs(deg - 180) < epsilon
		if is0 || is180 {
			return CGSize(width: w, height: h)
		}
		let is90  = abs(deg - 90)  < epsilon
		let is270 = abs(deg - 270) < epsilon
		if is90 || is270 {
			return CGSize(width: h, height: w)
		}

		let rad = deg * .pi / 180
		let c = abs(cos(rad))
		let s = abs(sin(rad))

		if inside {
			let denomW = w * s + h * c
			let denomH = w * c + h * s
			guard denomW > 0, denomH > 0 else { return .zero }
			let newW = (w * h) / denomW
			let newH = (w * h) / denomH
			return CGSize(width: newW, height: newH)
		} else {
			let newW = w * c + h * s
			let newH = w * s + h * c
			return CGSize(width: newW, height: newH)
		}
	}

	private func calcframeSize() -> CGSize {
		let contentSize = self.rotatedSize
		guard contentSize.width > 0,
			  contentSize.height > 0,
			  containerSize.width > 0,
			  containerSize.height > 0
		else {
			return .zero
		}
		if let fitFrame {
			let widthRatio = containerSize.width / contentSize.width
			let heightRatio = containerSize.height / contentSize.height
			let scale = fitFrame ?
				min(widthRatio, heightRatio) :
				max(widthRatio, heightRatio)
			return CGSize(
				width: contentSize.width * scale,
				height: contentSize.height * scale)
		}
		return containerSize
	}

// MARK: Positioning
	public let clampToFill: Bool? = true
	public let maxScale: Double
	public var minScale: CGFloat { CGFloat(1.0 / maxScale) }
	public private(set) var offset: CGSize = .zero
	public private(set) var scale: CGFloat = 1.0
	private var lastOffset: CGSize = .zero
	private var lastScale: CGFloat = 1.0

	var isNotInFrame: Bool {
		offset != .zero || scale != 1.0
	}

	var realizedOffset: CGSize {
		let realized = offset
		return realized
	}

// MARK: Edits

	public private(set) var mirror: GeometricMirror = .init()
	//public private(set) var crop: CGRect?

	var hasEdits: Bool {
		mirror.hasEdits
	}

	public func flip() {
		mirror = mirror.next
	}

	public func rotate(clockwise: Bool = false) {
		doRotate(clockwise)
	}

// MARK: Gestures
	func resetZoom() {
		offset = .zero
		scale = 1.0
		lastOffset = offset
		lastScale = scale
	}

	func resetEdits() {
		rotation = .zero
		mirror = .init()
	}

	func onDrag(_ value: DragGesture.Value) {
		let value = value.translation
		let test = CGSize(width: lastOffset.width + value.width, height: lastOffset.height + value.height)
		setClampedOffset(test)
	}

	func endDrag() {
		lastOffset = offset
	}

	func magnify(_ value: MagnificationGesture.Value) {
		let test = lastScale * value
		setClampedScale(test)
	}

	func endMagnify() {
		lastOffset = offset
		lastScale = scale
	}

//MARK: Geometry
	public func doRotate(_ clockwise: Bool = true) {
	}

	private func setClampedOffset(_ value: CGSize) {
		guard let clampToFill else {
			offset = value
			return
		}
		guard frameSize.width > 0, frameSize.height > 0,
			  sourceSize.width > 0, sourceSize.height > 0 else {
			offset = .zero
			return
		}
		if clampToFill {
			// Determine the base render scale used to fit content into the frame
			// This mirrors the logic in calcframeSize: when fitFrame is true, we fit inside the frame
			// and then apply the interactive `scale` on top.
			let fitScale = min(frameSize.width / sourceSize.width, frameSize.height / sourceSize.height)
			let renderedWidth = sourceSize.width * fitScale * scale
			let renderedHeight = sourceSize.height * fitScale * scale

			// Compute min/max offsets that still fully cover the frame on each axis.
			// The image is laid out centered in the frame at zero offset. Positive offset moves it right/down.
			// To keep the frame fully covered, the image's visible rect must be at least as large as the frame
			// and positioned so that no gap appears. When rendered size < frame, we clamp to 0 (centered).
			func clampAxis(rendered: CGFloat, frame: CGFloat, proposed: CGFloat) -> CGFloat {
				if rendered <= frame + 0.0001 {
					// Not large enough to produce gaps by moving; pin to center (no offset)
					return 0
				}
				let maxAbs = (rendered - frame) / 2.0
				return min(max(proposed, -maxAbs), maxAbs)
			}

			let clampedX = clampAxis(rendered: renderedWidth, frame: frameSize.width, proposed: value.width)
			let clampedY = clampAxis(rendered: renderedHeight, frame: frameSize.height, proposed: value.height)

			offset = CGSize(width: clampedX, height: clampedY)
		} else {
			// Center only if the rendered content is smaller than the frame on both axes.
			let fitScale = min(frameSize.width / sourceSize.width, frameSize.height / sourceSize.height)
			let renderedWidth = sourceSize.width * fitScale * scale
			let renderedHeight = sourceSize.height * fitScale * scale

			let epsilon: CGFloat = 0.0001
			let isSmallerOrEqualX = renderedWidth <= frameSize.width + epsilon
			let isSmallerOrEqualY = renderedHeight <= frameSize.height + epsilon

			if isSmallerOrEqualX && isSmallerOrEqualY {
				// Smaller on both axes: keep centered
				offset = .zero
			} else {
				// If larger on an axis, clamp to keep within frame; if smaller, keep centered on that axis.
				func clampAxis(rendered: CGFloat, frame: CGFloat, proposed: CGFloat) -> CGFloat {
					if rendered <= frame + epsilon {
						return 0 // keep centered on that axis
					} else {
						let maxAbs = (rendered - frame) / 2.0
						return min(max(proposed, -maxAbs), maxAbs)
					}
				}

				let clampedX = clampAxis(rendered: renderedWidth, frame: frameSize.width, proposed: value.width)
				let clampedY = clampAxis(rendered: renderedHeight, frame: frameSize.height, proposed: value.height)
				offset = CGSize(width: clampedX, height: clampedY)
			}
		}
	}

	private func setClampedScale(_ value: CGFloat) {
		if let clampToFill {
			if clampToFill && value < 1.0 {
				scale = 1.0
			} else if !clampToFill && value < minScale {
				scale = minScale
			} else if value > maxScale {
				scale = maxScale
			} else {
				scale = value
			}
		} else {
			scale = value
		}
		setClampedOffset(offset)
	}
}
