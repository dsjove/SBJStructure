import PencilKit
import ImageIO

public protocol ImageEditSource {
	var image: UIImage { get }
	var sharing: ShareItems { get }
	func consume(_ geometry: ImageFraming, _ drawing: PKDrawing) -> Self

	func consume(_ geometry: GeometryModel, _ drawing: PKDrawing) -> Self
}

public protocol ImageEditDataSource: ImageEditSource, DataAttachment {
	init(blob: Data, name: String, utiType: String)
}

public extension ImageEditDataSource {
	var image: UIImage { UIImage(data: blob) ?? UIImage() }

	func shareItems(subDir: String) -> [Any] {
		if let url = try? self.shareURL(subDir: subDir) {
			return [url]
		}
		if let image = UIImage(data: self.blob) {
			return [image]
		}
		return [blob]
	}

	var sharing: ShareItems {
		(shareItems(subDir: "share"), nil)
	}

	@MainActor
	func consume(_ geometry: ImageFraming, _ drawing: PKDrawing) -> Self {
		guard (geometry.hasEdits || drawing.hasEdits) else { return self }
		guard let blob = compositedImageData(geometry, drawing) else { return self }
		return .init(
			blob: blob,
			name: name,
			utiType: utiType)
	}

	@MainActor
	private func compositedImageData(_ geometry: ImageFraming, _ drawing: PKDrawing) -> Data? {
		let composed = self.image.render(geometry, overlay: drawing)
//TODO: break out into seperate function and merge EXIF data
		let originalData = blob
		guard let imageSource = CGImageSourceCreateWithData(originalData as CFData, nil),
			  let uti = CGImageSourceGetType(imageSource),
			  let destinationData = NSMutableData() as CFMutableData?,
			  let destination = CGImageDestinationCreateWithData(destinationData, uti, 1, nil),
			  let cgImage = composed.cgImage
		else {
			return composed.jpegData(compressionQuality: 0.8)
		}
		var metadata = (CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]) ?? [:]
		metadata[kCGImagePropertyOrientation] = 1 as CFNumber
		CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary?)
		guard CGImageDestinationFinalize(destination) else {
			return composed.jpegData(compressionQuality: 0.8)
		}
		return destinationData as Data
	}
}
