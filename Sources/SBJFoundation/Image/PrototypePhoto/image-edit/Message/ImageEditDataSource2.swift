import PencilKit
import ImageIO

public extension ImageEditDataSource {
	func consume(_ geometry: GeometryModel,_ drawing: PKDrawing) -> Self {
		guard (geometry.hasEdits || drawing.hasEdits) else { return self }
		guard let blob = compositedImageData(geometry, drawing) else { return self }
		return .init(
			blob: blob,
			name: name,
			utiType: utiType)
	}

	private func compositedImageData(_ geometry: GeometryModel, _ drawing: PKDrawing) -> Data? {
		// Normalize the UIImage so drawing coordinates align with an upright image
		let original = image.normalizedUp()
		// Define drawing bounds that match the original image size
		let bounds = CGRect(origin: .zero, size: original.size)
		// Rasterize the PKDrawing into a UIImage at the same scale as the original
		let drawingImage = drawing.image(from: bounds, scale: original.scale)

		// Configure a renderer that matches the original image's scale to avoid blurriness
		let rendererFormat = UIGraphicsImageRendererFormat()
		rendererFormat.scale = original.scale

		// Create a renderer sized to the original image
		let renderer = UIGraphicsImageRenderer(size: original.size, format: rendererFormat)
		// Draw the original image first, then overlay the user's drawing
		let composed = renderer.image { ctx in
			// Apply mirror transforms if needed
			let context = ctx.cgContext
			context.saveGState()
			// Translate to center to perform symmetric flips around image center
			context.translateBy(x: bounds.midX, y: bounds.midY)
			var sx: CGFloat = 1
			var sy: CGFloat = 1
			if geometry.mirror.horizontal { sx *= -1 }
			if geometry.mirror.vertical { sy *= -1 }
			context.scaleBy(x: sx, y: sy)
			// Translate back and draw the original image into mirrored context
			context.translateBy(x: -bounds.midX, y: -bounds.midY)
			original.draw(in: bounds)
			drawingImage.draw(in: bounds)
			context.restoreGState()
		}

		// Keep a reference to the original encoded bytes to read type/metadata later
		let originalData = blob
		// Attempt to preserve the original container type (UTI) and metadata using ImageIO
		guard let imageSource = CGImageSourceCreateWithData(originalData as CFData, nil),
			  let uti = CGImageSourceGetType(imageSource),
			  let destinationData = NSMutableData() as CFMutableData?,
			  let destination = CGImageDestinationCreateWithData(destinationData, uti, 1, nil),
			  let cgImage = composed.cgImage
		else {
			return composed.jpegData(compressionQuality: 0.8) // Fallback: return JPEG data if we can't access original type/metadata
		}

		// Copy metadata from the original image and reset orientation to 'up'
		var metadata = (CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any]) ?? [:]
		metadata[kCGImagePropertyOrientation] = 1 as CFNumber

		// Re-encode the composed CGImage using the original UTI and copied metadata
		CGImageDestinationAddImage(destination, cgImage, metadata as CFDictionary?)
		// Finalize the destination. If it fails, fall back to JPEG.
		guard CGImageDestinationFinalize(destination) else {
			return composed.jpegData(compressionQuality: 0.8)
		}

		return destinationData as Data
	}
}
