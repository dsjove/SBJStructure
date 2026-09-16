import UIKit
import Foundation

public typealias IdentifiableImage = Identified<UIImage>

public extension UIImage {
	convenience init?(data: Data?) {
		guard let data = data else {
			return nil
		}
		self.init(data: data)
	}

	func normalizedUp() -> UIImage {
		if imageOrientation == .up { return self }
		let format = UIGraphicsImageRendererFormat()
		format.scale = scale
		format.opaque = false
		let renderer = UIGraphicsImageRenderer(size: size, format: format)
		return renderer.image { _ in
			draw(in: CGRect(origin: .zero, size: size))
		}
	}

	func shrinkTo(_ targetSize: CGSize) -> UIImage {
		if self.size.width <= targetSize.width && self.size.height <= targetSize.height {
			return self
		}

		let widthRatio = targetSize.width / size.width
		let heightRatio = targetSize.height / size.height
		let scaleFactor = min(widthRatio, heightRatio)

		// Compute scaled size that fits inside targetSize
		let scaledSize = CGSize(
			width: size.width * scaleFactor,
			height: size.height * scaleFactor
		)
		#if !os(watchOS)
		let renderer = UIGraphicsImageRenderer(size: scaledSize)
		return renderer.image { _ in
			self.draw(in: CGRect(origin: .zero, size: scaledSize))
		}
		#else
		return self //TODO
		#endif
	}
}
