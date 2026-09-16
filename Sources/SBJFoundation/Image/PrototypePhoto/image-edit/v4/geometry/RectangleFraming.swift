import SwiftUI
import Observation

@Observable
@MainActor
public final class RectangleFraming: @MainActor ImageFraming {

	public init(sourceSize: CGSize = .zero, mirrorHorizOnly: Bool = false) {
		self.sourceSize = sourceSize
		self.mirror = .init(horizontalOnly: mirrorHorizOnly)
		recalcSouceBounds()
	}

	public var sourceSize: CGSize {
		didSet {
			if sourceSize != oldValue {
				recalcSouceBounds()
			}
		}
	}
	public var rotation: Angle = .zero {
		didSet {
			if rotation != oldValue {
				recalcSouceBounds()
			}
		}
	}

	public func rotate(clockwise: Bool = true) {
		let next = rotation.degrees + (clockwise ? 90 : -90)
		rotation = .degrees(next.truncatingRemainder(dividingBy: 360))
	}

	public private(set) var sourcePoints: [CGPoint] = [.zero, .zero, .zero, .zero]
	public private(set) var sourceBounds: CGRect = .zero
	public private(set) var sourceInscribed: CGRect = .zero

	private func recalcSouceBounds() {
		// 1) Reset outputs for empty input
		let w = sourceSize.width
		let h = sourceSize.height
		if w <= 0 || h <= 0 {
			sourcePoints = [.zero, .zero, .zero, .zero]
			sourceBounds = .zero
			sourceInscribed = .zero
			recalcFraming()
			return
		}

		// 2) Define unrotated rectangle corners centered at origin
		let halfW = w / 2
		let halfH = h / 2
		let baseCorners: [CGPoint] = [
			CGPoint(x: -halfW, y: -halfH), // top-left
			CGPoint(x:  halfW, y: -halfH), // top-right
			CGPoint(x:  halfW, y:  halfH), // bottom-right
			CGPoint(x: -halfW, y:  halfH)  // bottom-left
		]

		// 3) Rotate corners by current rotation (in radians)
		let radians = CGFloat(rotation.radians)
		let cosA = cos(radians)
		let sinA = sin(radians)
		let rotatedCorners: [CGPoint] = baseCorners.map { p in
			CGPoint(x: p.x * cosA - p.y * sinA, y: p.x * sinA + p.y * cosA)
		}

		// 4) Compute axis-aligned bounding rect for rotated polygon
		var minX = rotatedCorners[0].x
		var maxX = rotatedCorners[0].x
		var minY = rotatedCorners[0].y
		var maxY = rotatedCorners[0].y
		for p in rotatedCorners.dropFirst() {
			if p.x < minX { minX = p.x }
			if p.x > maxX { maxX = p.x }
			if p.y < minY { minY = p.y }
			if p.y > maxY { maxY = p.y }
		}
		let boundsOrigin = CGPoint(x: minX, y: minY)
		let boundsSize = CGSize(width: maxX - minX, height: maxY - minY)
		sourceBounds = CGRect(origin: boundsOrigin, size: boundsSize)

		// 5) Translate the rotated polygon so that bounds origin is at (0,0)
		sourcePoints = rotatedCorners.map { CGPoint(x: $0.x - boundsOrigin.x, y: $0.y - boundsOrigin.y) }

		// 6) Compute an inscribed axis-aligned rectangle fully inside the rotated rectangle.
		//    We want the largest AABB that fits entirely inside the rotated rect. For a rectangle
		//    rotated by angle theta, the inscribed size can be computed from the original w,h.
		//    Derivation yields the same expressions as fitting the original rect inside its own
		//    rotated bounding box (but inverted). We compute using absolute angle in [0, pi/2].
		func normalizedAngle(_ radians: CGFloat) -> CGFloat {
			let twoPi = 2 * CGFloat.pi
			var a = radians.truncatingRemainder(dividingBy: twoPi)
			if a < 0 { a += twoPi }
			let quarter = (CGFloat.pi / 2)
			let m = a.truncatingRemainder(dividingBy: quarter)
			return m
		}
		let a = normalizedAngle(radians)
		let c = abs(cos(a))
		let s = abs(sin(a))

		// Bounding box of rotated original rectangle
		let bw = w * c + h * s
		let bh = w * s + h * c

		// Largest axis-aligned rect inside the rotated rectangle that maintains original aspect.
		// We scale the bounding box down so that when un-rotated, it fits inside the original.
		// This gives an inscribed rect in the rotated space maintaining center alignment.
		var insetSize: CGSize = .zero
		if bw > 0 && bh > 0 {
			// Scale so that when we rotate the original, the inscribed rect stays inside.
			// Choose the limiting axis so that the inscribed rect is guaranteed inside.
			// The scale ensures that mapping back to the original rect does not exceed w or h.
			let scaleW = w / bw
			let scaleH = h / bh
			let scale = min(scaleW, scaleH)
			insetSize = CGSize(width: bw * scale, height: bh * scale)
		}
		sourceInscribed = CGRect(origin: .zero, size: insetSize)

		// 8) Recalculate framing with updated geometry
		recalcFraming()
	}

	public private(set) var sourceMode: ScaleMode = .fit
	public var sourceRect : CGRect { sourceMode == .fit ? sourceBounds : sourceInscribed }

	public var containerSize: CGSize = .zero {
		didSet {
			if containerSize != oldValue {
				recalcFraming()
			}
		}
	}
	public var containerRect: CGRect { CGRect(origin: .zero, size: containerSize) }

	public var frameMode: ScaleMode = .fit {
		didSet {
			if frameMode != oldValue {
				recalcFraming()
			}
		}
	}

	public private(set) var frameScale: CGFloat = 1.0
	public private(set) var frameSize: CGSize = .zero
	public var frameRect: CGRect {
		let size = frameSize
		let origin = CGPoint(x: (containerSize.width - size.width)/2, y: (containerSize.height - size.height)/2)
		return CGRect(origin: origin, size: CGSize(width: size.width, height: size.height))
	}
	public private(set) var framePoints: [CGPoint] = [.zero, .zero, .zero, .zero]

	private func recalcFraming() {
		let w = containerSize.width
		let h = containerSize.height
		if w <= 0 || h <= 0 {
			frameScale = 0.0
			frameSize = .zero
			framePoints = [.zero, .zero, .zero, .zero]
			recalcPositioning()
			return
		}
		frameScale = containerSize.scale(for: sourceRect.size, mode: frameMode)
		frameSize = sourceRect.size.scaled(frameScale)
		framePoints = sourcePoints.map { $0.scaled(frameScale) }
		recalcPositioning()
	}

	public private(set) var mirror: GeometricMirror
	public var magnify: CGFloat = 1.0
	public var offset: CGSize = .zero

	public private(set) var positionedPoints: [CGPoint] = [.zero, .zero, .zero, .zero]
	public private(set) var positionedSize: CGSize = .zero

	public func flip() {
		mirror = mirror.next
	}

	public var containedOffset: CGSize {
		get {
			let toSource = sourceRect.size.scaled(offset)
			let toframe = toSource.scaled(frameScale)
			return toframe
		}
		set {
			let unscaledFrame = newValue.scaled(1.0 / frameScale)
			let sourceRecip = CGSize(width: 1 / sourceRect.size.width, height: 1 / sourceRect.size.height)
			offset = unscaledFrame.scaled(sourceRecip)
		}
	}

	private func recalcPositioning() {
		positionedPoints = framePoints.map { $0.scaled(magnify).offset(containedOffset) }
		positionedSize = CGSize(width: positionedPoints[0].distance(to: positionedPoints[1]), height: positionedPoints[1].distance(to: positionedPoints[2]))
	}

	public var hasEdits: Bool {
		true
	}

	var isNotInFrame: Bool {
		//TODO: rotation needs to check remainder against 180
		offset != .zero || magnify != 1.0 || rotation != .zero
	}

	public func reset() {
		mirror.reset()
		resetPosition()
	}

	func resetPosition() {
		magnify = 1.0
		offset = .zero
		rotation = .zero
	}

//	var crop: CGRect?
//	private func clampOffset() {
//	}
}

