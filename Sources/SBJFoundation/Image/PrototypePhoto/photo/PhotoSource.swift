import SwiftUI
import UIKit
import SwiftData

public protocol PhotoSource: AnyObject {
	var placeholderPhoto: ImageName { get }
	var thumbnailSize: CGSize { get }
	var photo: Data? { get set }
	var thumbnail: Data? { get set }
	func photoChanged()
}

public extension PhotoSource {
	var placeholderPhoto: ImageName { .none }
	var thumbnailSize: CGSize { .init(width: 200, height: 200) }

	var hasImage: Bool {
		photo != nil
	}

	func photoChanged() {}

	var photoImage: UIImage? {
		get {
			UIImage(data: photo)
		}
		set {
			if let newValue {
				self.photo = newValue.jpegData(compressionQuality: 0.8)
			} else {
				self.photo = nil
			}
			generateThumbnail()
			photoChanged()
		}
	}

	var thumbnailImage: UIImage? {
		get {
			UIImage(data: thumbnail)
		}
	}

	private func generateThumbnail() {
		if let image = photoImage {
			let thumbnail = image.shrinkTo(thumbnailSize)
			self.thumbnail = thumbnail.jpegData(compressionQuality: 0.8)
		} else {
			self.thumbnail = nil
		}
	}
}

public extension PhotoSource where Self: PersistentModel {
	func photoChanged() {
		saveNow()
	}
}

public extension PhotoSource {
	@ViewBuilder
	func thumbnailView(size: CGSize = .init(width: 32, height: 32)) -> some View {
		if let image = thumbnailImage {
			Image(uiImage: image)
				.resizable()
				.scaledToFit()
				.frame(width: size.width, height: size.height)
				.clipShape(RoundedRectangle(cornerRadius: 8))
		}
		else if case .none = placeholderPhoto {
			EmptyView()
		}
		else {
			Image(placeholderPhoto)
				.resizable()
				.scaledToFit()
				.frame(width: size.width, height: size.height)
				.clipShape(RoundedRectangle(cornerRadius: 8))
		}
	}

	@ViewBuilder
	var displayView: some View {
		if let image = photoImage {
			Image(uiImage: image)
				.resizable()
				.aspectRatio(1.0, contentMode: .fill)
				.frame(alignment: .center)
				.clipShape(RoundedRectangle(cornerRadius: 12))
		} else {
			ZStack {
				RoundedRectangle(cornerRadius: 12)
					.fill(.secondary.opacity(0.1))
				Image(placeholderPhoto)
					.resizable()
					.aspectRatio(1.0, contentMode: .fit)
					.font(.system(size: 48, weight: .regular))
					.foregroundStyle(.secondary)
					.padding()
			}
			.frame(alignment: .center)
		}
	}
}
