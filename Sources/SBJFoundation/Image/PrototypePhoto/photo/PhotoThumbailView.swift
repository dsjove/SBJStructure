#if !os(watchOS)
import SwiftUI
import UIKit
import SwiftData

public struct PhotoThumbailView<Source: PhotoSource>: View {
	let source: Source
	let options: PhotoMenuOptions
	let useThumbnail: Bool
	let size: CGSize

	public init(
			source: Source,
			options: PhotoMenuOptions = .all,
			useThumbnail: Bool = true,
			size: CGSize = .init(width: 44, height: 44)) {
		self.source = source
		self.options = options
		self.useThumbnail = useThumbnail
		self.size = size
	}

	public var body: some View {
		PhotoImportMenu(image: Binding {
					source.photoImage
				} set: {
					source.photoImage = $0
				}, options: options, editImports: true) {
			if useThumbnail && source.hasImage {
				source.thumbnailView(size: size)
			}
			else {
				Image(systemName: "photo")
					.resizable()
					.scaledToFit()
					.frame(width: size.width, height: size.height)
					.clipShape(RoundedRectangle(cornerRadius: 8))
			}
		}
	}
}
#endif
