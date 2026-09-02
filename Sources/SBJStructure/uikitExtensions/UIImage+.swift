#if canImport(UIKit)
import UIKit

public typealias IdentifiableImage = Identified<UIImage>

public extension UIImage {
	convenience init?(data: Data?) {
		guard let data else {
			return nil
		}
		self.init(data: data)
	}

	convenience init?(url: URL?) {
		guard let url else {
			return nil
		}
		let didAccess = url.startAccessingSecurityScopedResource()
		defer {
			if didAccess { url.stopAccessingSecurityScopedResource() }
		}
		self.init(contentsOfFile: url.path)
	}
}

#endif
