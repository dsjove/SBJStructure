import CoreGraphics

public extension CGSize {
	func scale(for content: CGSize, mode: ScaleMode?) -> CGFloat {
		guard self.width > 0,
			  self.height > 0,
			  content.width > 0,
			  content.height > 0
		else { return .zero }
		guard let mode else { return 1 }
		let widthRatio = self.width / content.width
		let heightRatio = self.height / content.height
		return mode == .fit ? min(widthRatio, heightRatio) : max(widthRatio, heightRatio)
	}

	func scaled(_ value: CGFloat) -> CGSize {
		.init(width: width * value, height: height * value)
	}

	func scaled(_ value: CGSize) -> CGSize {
		.init(width: width * value.width, height: height * value.height)
	}
}

public extension CGPoint {
	func scaled(_ value: CGFloat) -> CGPoint {
		.init(x: x * value, y: y * value)
	}

	func offset(_ value: CGSize) -> CGPoint {
		.init(x: x + value.width, y: y + value.height)
	}

	func distance(to b: CGPoint) -> CGFloat {
		let dx = self.x - b.x
		let dy = self.y - b.y
		return sqrt(dx*dx + dy*dy)
	}
}
