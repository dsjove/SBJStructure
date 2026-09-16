#if !os(watchOS)
import SwiftUI
import UIKit

public struct CameraPickerView: UIViewControllerRepresentable {
	@Environment(\.presentationMode) private var presentationMode
	@Binding private var image: UIImage?

	private static let lastCameraDeviceKey = "CameraPickerView.lastCameraDevice"

	private static func loadPreferredCameraDevice() -> UIImagePickerController.CameraDevice? {
		let value = UserDefaults.standard.string(forKey: lastCameraDeviceKey)
		switch value {
		case "front":
			return .front
		case "rear":
			return .rear
		default:
			return nil
		}
	}

	private static func savePreferredCameraDevice(_ device: UIImagePickerController.CameraDevice) {
		let value: String
		switch device {
		case .front:
			value = "front"
		case .rear:
			value = "rear"
		@unknown default:
			value = "rear"
		}
		UserDefaults.standard.setValue(value, forKey: lastCameraDeviceKey)
	}

	public init(image: Binding<UIImage?>) {
		self._image = image
	}

	public func makeUIViewController(context: Context) -> UIImagePickerController {
		let picker = UIImagePickerController()
		picker.sourceType = .camera
		picker.delegate = context.coordinator
		if UIImagePickerController.isCameraDeviceAvailable(.front) || UIImagePickerController.isCameraDeviceAvailable(.rear) {
			if let preferred = Self.loadPreferredCameraDevice(), UIImagePickerController.isCameraDeviceAvailable(preferred) {
				picker.cameraDevice = preferred
			}
		}
		return picker
	}

	public func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

	public func makeCoordinator() -> Coordinator {
		Coordinator(self)
	}

	public class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
		var parent: CameraPickerView

		public init(_ parent: CameraPickerView) {
			self.parent = parent
		}

		public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
			if let selectedImage = info[.originalImage] as? UIImage {
				DispatchQueue.main.async {
					self.parent.image = selectedImage
				}
			}
			if let device = picker.value(forKey: "cameraDevice") as? UIImagePickerController.CameraDevice {
				CameraPickerView.savePreferredCameraDevice(device)
			} else {
				// Fallback to direct property if accessible
				CameraPickerView.savePreferredCameraDevice(picker.cameraDevice)
			}
			parent.presentationMode.wrappedValue.dismiss()
		}

		public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
			if let device = picker.value(forKey: "cameraDevice") as? UIImagePickerController.CameraDevice {
				CameraPickerView.savePreferredCameraDevice(device)
			} else {
				CameraPickerView.savePreferredCameraDevice(picker.cameraDevice)
			}
			parent.presentationMode.wrappedValue.dismiss()
		}
	}
}
#endif
