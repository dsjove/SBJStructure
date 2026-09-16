import SwiftUI

public struct CroppingState: GeometryTransforming {
	private let editing: Bool
	//TODO: we need a good way of describing min and max scales where the values are always positive.
	private let maxScale: Double

	public private(set) var offset: CGSize = .zero
	public private(set) var scale: CGFloat = 1.0
	public private(set) var rotation: Angle = .zero
	public private(set) var flipX: Bool = false
	public private(set) var flipY: Bool = false
	public private(set) var crop: CGRect = .zero

	private var imgSize: CGSize = .zero
	private var userGestured: Bool = false
	private var lastOffset: CGSize = .zero
	private var lastScale: CGFloat = 1.0

	public init(editing: Bool, maxScale: Double) {
		self.editing = editing
		self.maxScale = maxScale
	}

	public mutating func onChange(cropping: CGRect, of imageSize: CGSize) {
		guard min(cropping.width, cropping.height) > 0 else { return }
		if self.imgSize != imageSize {
			userGestured = false
			self.imgSize = imageSize
		}

		self.crop = cropping

		if !userGestured {
			reset()
		}
	}

	public mutating func reset() {
		offset = .zero
		lastOffset = .zero
		setClampedScale(0, fill: editing) // otherwise fit for viewing
		endScale()
		rotation = .zero
		flipX = false
		flipY = false
	}

	public mutating func onDrag(by value: CGSize) {
		self.userGestured = true
		let test = CGSize(width: lastOffset.width + value.width, height: lastOffset.height + value.height)
		setClampedOffset(test)
	}

	public mutating func endDrag() {
		lastOffset = offset
	}

	private mutating func setClampedOffset(_ value: CGSize) {
		if !editing {
			// Ensure the rotated image AABB intersects the crop by minimally projecting
			// the proposed center back into an overlapping position if necessary.
			let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
			let w = imgSize.width * renderScale * scale
			let h = imgSize.height * renderScale * scale

			let angle = CGFloat(rotation.radians)
			let cosA = abs(cos(angle))
			let sinA = abs(sin(angle))
			let rotatedW = w * cosA + h * sinA
			let rotatedH = w * sinA + h * cosA
			let halfRotW = rotatedW / 2
			let halfRotH = rotatedH / 2

			// Proposed image center from incoming offset value
			var cx = crop.width / 2 + value.width
			var cy = crop.height / 2 + value.height

			// Compute AABB edges for proposed position
			var left = cx - halfRotW
			var right = cx + halfRotW
			var top = cy - halfRotH
			var bottom = cy + halfRotH

			// If no overlap on X, project center minimally back to nearest touching position
			if right < 0 {
				// Move so that right == 0
				let delta = 0 - right
				cx += delta
				right += delta
				left += delta
			} else if left > crop.width {
				// Move so that left == crop.width
				let delta = crop.width - left
				cx += delta
				right += delta
				left += delta
			}

			// If no overlap on Y, project center minimally back to nearest touching position
			if bottom < 0 {
				let delta = 0 - bottom
				cy += delta
				bottom += delta
				top += delta
			} else if top > crop.height {
				let delta = crop.height - top
				cy += delta
				bottom += delta
				top += delta
			}

			// Set offset from corrected center
			self.offset = CGSize(width: cx - crop.width / 2, height: cy - crop.height / 2)
			return
		}
		let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
		let w = imgSize.width * renderScale * scale
		let h = imgSize.height * renderScale * scale
		
		// Compute bounding box of rotated image
		let angle = CGFloat(rotation.radians)
		let cosA = abs(cos(angle))
		let sinA = abs(sin(angle))
		let rotatedW = w * cosA + h * sinA
		let rotatedH = w * sinA + h * cosA
		
		let minX = min(0, (crop.width - rotatedW) / 2)
		let maxX = max(0, (rotatedW - crop.width) / 2)
		let minY = min(0, (crop.height - rotatedH) / 2)
		let maxY = max(0, (rotatedH - crop.height) / 2)
		let x = max(min(value.width, maxX), minX)
		let y = max(min(value.height, maxY), minY)
		self.offset = CGSize(width: x, height: y)
	}

	public mutating func onScale(by value: CGFloat) {
		self.userGestured = true
		let test = lastScale * value
		setClampedScale(test, fill: editing ? true : nil)
	}

	public mutating func endScale() {
		lastOffset = offset
		lastScale = scale
	}

	private mutating func setClampedScale(_ value: CGFloat, fill: Bool?) {
		// Scale with anchor at the crop center projected onto the image
		// 1) Compute image rect in crop coordinates before scaling
		let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
		let oldScale = scale
		let wOld = imgSize.width * renderScale * oldScale
		let hOld = imgSize.height * renderScale * oldScale
		let imageOriginOld = CGPoint(x: (crop.width - wOld) / 2 + offset.width,
									 y: (crop.height - hOld) / 2 + offset.height)
		let cropCenter = CGPoint(x: crop.width / 2, y: crop.height / 2)
		// Vector from image origin to crop center in crop space
		let vOld = CGPoint(x: cropCenter.x - imageOriginOld.x, y: cropCenter.y - imageOriginOld.y)

		// 2) Apply clamped scale value as before
		if let fill {
			if fill {
				let minScale = max(crop.width / (imgSize.width * renderScale),
											  crop.height / (imgSize.height * renderScale),
											  1.0)
				self.scale = min(max(minScale, value), maxScale)
			} else {
				let maxFitScale = min(crop.width / (imgSize.width * renderScale),
											  crop.height / (imgSize.height * renderScale),
											  1.0)
				self.scale = min(max(1.0, value), min(maxFitScale, maxScale))
			}
		} else {
	//TODO: stop scale down when all edges are inside the crop
			self.scale = min(value, maxScale)
		}

		// 3) Recompute image rect after scaling
		let wNew = imgSize.width * renderScale * scale
		let hNew = imgSize.height * renderScale * scale

		// 4) Adjust offset so that the crop center projects to the same image point
		// When scaling around an anchor A, the delta needed is: A - (A - O) * (new/old),
		// which in our origin-offset formulation becomes:
		// newOrigin = cropCenter - vOld * (scale/oldScale)
		// offset derives from origin relative to centered placement.
		if oldScale != 0 {
			let newOrigin = CGPoint(x: cropCenter.x - vOld.x * (scale / oldScale),
								   y: cropCenter.y - vOld.y * (scale / oldScale))
			let newOffsetX = newOrigin.x - (crop.width - wNew) / 2
			let newOffsetY = newOrigin.y - (crop.height - hNew) / 2
			self.offset = CGSize(width: newOffsetX, height: newOffsetY)
		}

		// 5) Clamp offset considering rotation bounds
		setClampedOffset(offset)
	}

	public mutating func rotate(clockwise: Bool = false) {
		// Preserve crop center focus by adjusting offset based on rotation

		// 1. Calculate the center point of the cropping rect
		let cropCenter = CGPoint(x: crop.width / 2, y: crop.height / 2)

		// 2. Compute current image size and center in the crop coordinate space
		let renderScale = min(crop.width / imgSize.width, crop.height / imgSize.height)
		let w = imgSize.width * renderScale * scale
		let h = imgSize.height * renderScale * scale
		let x = (crop.width - w) / 2 + offset.width
		let y = (crop.height - h) / 2 + offset.height
		let imageCenterInCrop = CGPoint(x: x + w / 2, y: y + h / 2)

		// 3. Compute the vector from crop center to image center
		let vector = CGPoint(x: imageCenterInCrop.x - cropCenter.x, y: imageCenterInCrop.y - cropCenter.y)

		// 4. Rotate this vector by ±90 degrees (depending on clockwise)
		let angle = clockwise ? Double.pi / 2 : -Double.pi / 2
		let rotatedVector = CGPoint(
			x: vector.x * CoreGraphics.cos(angle) - vector.y * CoreGraphics.sin(angle),
			y: vector.x * CoreGraphics.sin(angle) + vector.y * CoreGraphics.cos(angle)
		)

		// 5. Compute the new image center after rotation
		let newImageCenter = CGPoint(x: cropCenter.x + rotatedVector.x, y: cropCenter.y + rotatedVector.y)

		// 6. Update the offset so that image remains centered on the new rotated position
		// Note: width and height swap roles due to rotation of 90 degrees
		let newOffset = CGSize(
			width: newImageCenter.x - (crop.width - h) / 2 - w / 2,
			height: newImageCenter.y - (crop.height - w) / 2 - h / 2
		)
		offset = newOffset
		lastOffset = offset

		// Perform the rotation increment and clamp offset accordingly
		rotation += .init(degrees: clockwise ? 90 : -90)
		setClampedOffset(offset)
	}

	public mutating func flip(horizontal: Bool = true) {
		if horizontal {
			let newOffset = CGSize(width: -offset.width, height: offset.height)
			flipX.toggle()
			offset = newOffset
		} else {
			let newOffset = CGSize(width: offset.width, height: -offset.height)
			flipY.toggle()
			offset = newOffset
		}
		lastOffset = offset
		setClampedOffset(offset)
	}
}
