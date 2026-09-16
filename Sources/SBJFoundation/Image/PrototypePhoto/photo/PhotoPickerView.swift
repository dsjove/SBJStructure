#if !os(watchOS)
import SwiftUI
import PhotosUI
import UIKit

public struct PhotoPickerView: UIViewControllerRepresentable {
	@Binding private var image: UIImage?

	public init(image: Binding<UIImage?>) {
		self._image = image
	}

	public func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	public func makeUIViewController(context: Context) -> PHPickerViewController {
		var config = PHPickerConfiguration(photoLibrary: .shared())
		config.filter = .images
		config.selectionLimit = 1

		let picker = PHPickerViewController(configuration: config)
		picker.delegate = context.coordinator
		return picker
	}

	public func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

	public class Coordinator: NSObject, PHPickerViewControllerDelegate {
		let parent: PhotoPickerView

		public init(_ parent: PhotoPickerView) {
			self.parent = parent
		}

		public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
			picker.dismiss(animated: true)
			guard let provider = results.first?.itemProvider, provider.canLoadObject(ofClass: UIImage.self) else {
				return
			}
			provider.loadObject(ofClass: UIImage.self) { image, error in
				let t = image as? UIImage
				DispatchQueue.main.async {
					self.parent.image = t
				}
			}
		}
	}
}
#endif
