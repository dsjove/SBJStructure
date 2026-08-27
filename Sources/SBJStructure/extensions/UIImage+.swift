import UIKit

public extension UIImage {
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
