import UIKit
import SwiftUI

public protocol ImageFraming {
	var hasEdits: Bool { get }
	var mirror: GeometricMirror { get }
	var rotation: Angle { get }
}

public extension UIImage {
	@MainActor
	func render(_ model: ImageFraming, overlay: (()->())?) -> UIImage {
		let base = self.normalizedUp()

		// We do not scale or offset here per the comment. Only mirror and rotate.
		// Compute the rotated bounding box size for 90-degree increments only (as implied by UI controls).
		// The model.rotation is an Angle; we round to the nearest 90 degrees for pixel-perfect output.
		let degrees = CGFloat((model.rotation.degrees / 90.0).rounded()) * 90.0
		let radians = degrees * .pi / 180

		// Mirroring: horizontal -> flip X, vertical -> flip Y
		let flipX: CGFloat = model.mirror.horizontal ? -1 : 1
		let flipY: CGFloat = model.mirror.vertical ? -1 : 1

		// When rotating by 90 or 270, the output canvas swaps width/height
		let swapWH = Int(abs(degrees).truncatingRemainder(dividingBy: 180)) == 90
		let outputSize = swapWH ? CGSize(width: base.size.height, height: base.size.width) : base.size

		let format = UIGraphicsImageRendererFormat.default()
		format.scale = UIScreen.main.scale
		let renderer = UIGraphicsImageRenderer(size: outputSize, format: format)
		let rendered = renderer.image { ctx in
			// Clear background (transparent)
			ctx.cgContext.setFillColor(UIColor.clear.cgColor)
			ctx.cgContext.fill(CGRect(origin: .zero, size: outputSize))

			// Translate to center of output canvas
			ctx.cgContext.translateBy(x: outputSize.width / 2, y: outputSize.height / 2)

			// Apply rotation first (around center)
			ctx.cgContext.rotate(by: radians)

			// Apply mirroring around center
			ctx.cgContext.scaleBy(x: flipX, y: flipY)

			// After rotation, draw the image centered with its original size
			let drawRect = CGRect(x: -base.size.width / 2,
								  y: -base.size.height / 2,
								  width: base.size.width,
								  height: base.size.height)
			base.draw(in: drawRect)

			// Finally, allow caller to draw overlay in the same coordinate space (centered, rotated and mirrored)
			overlay?()
		}
		return rendered
	}
}
