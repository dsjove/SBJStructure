#if !os(watchOS)
import SwiftUI
import PhotosUI

fileprivate class PhotoMenuState: ObservableObject {
	@Published var isPickerPresented = false
	@Published var photoPickerSelection: PhotosPickerItem?
	@Published var isCameraPresented = false
	@Published var isFileImporterPresented = false
	@Published var isPhotoClearPresented = false
	@Published var canPasteImage = false
	@Published var importedImage: UIImage? = nil

	@Published var viewingImage: IdentifiableImage?
	@Published var shareImage: IdentifiableImage?
	@Published var editingImage: IdentifiableImage?
}

public struct PhotoImportMenu<Content: View>: View {
	@Binding private var image: UIImage?
	@StateObject private var state = PhotoMenuState()
    private let label: () -> Content
	
	private let options: PhotoMenuOptions
	private let editImports: Bool

	public init(image: Binding<UIImage?>, options: PhotoMenuOptions = .all, editImports: Bool = true) where Content == _DefaultPhotoMenuLabel {
		self._image = image
		self.options = options
		self.editImports = editImports
		self.label = {
			_DefaultPhotoMenuLabel(isFilled: image.wrappedValue != nil)
		}
	}

	public init(image: Binding<UIImage?>, options: PhotoMenuOptions = .modify, editImports: Bool = false, @ViewBuilder label: @escaping () -> Content) {
		self._image = image
		self.options = options
		self.editImports = editImports
		self.label = label
	}

	@ViewBuilder
	func menuItems(_ labelIsHidden: Bool) -> some View {
		if options.contains(.view), let image {
			ActionButton("View", labeled: !labelIsHidden, image: .system("eye")) {
				state.viewingImage = IdentifiableImage(image)
			}
		}
		if options.contains(.share), let image {
			ActionButton("Share", labeled: !labelIsHidden, image: .system("square.and.arrow.up")) {
				state.shareImage = IdentifiableImage(image)
			}
		}
		if options.contains(.photos) && PhotoMenuOptions.canShowPhotos {
			ActionButton("Photos", labeled: !labelIsHidden, image: .system("photo.on.rectangle")) {
				state.isPickerPresented = true
			}
		}
		if options.contains(.camera) && PhotoMenuOptions.canShowCamera {
			ActionButton("Camera", labeled: !labelIsHidden, image: .system("camera")) {
				state.isCameraPresented = true
			}
		}
		if options.contains(.files) && PhotoMenuOptions.canShowFiles {
			ActionButton("Files", labeled: !labelIsHidden, image: .system("folder")) {
				state.isFileImporterPresented = true
			}
		}
		if options.contains(.paste) {
			ActionButton("Paste", labeled: !labelIsHidden, image: .system("doc.on.clipboard")) {
				if let pasted = UIPasteboard.general.image {
					DispatchQueue.main.async {
						state.importedImage = pasted
					}
				}
			}
			.disabled(!state.canPasteImage)
		}
		if options.contains(.edit) && image != nil {
			ActionButton("Edit", labeled: !labelIsHidden, image: .system("pencil")) {
				if let currentImage = image {
					DispatchQueue.main.async {
						state.importedImage = currentImage
					}
				}
			}
		}
		if options.contains(.clear) && image != nil {
			Button(role: .destructive) {
				state.isPhotoClearPresented = true
			} label: {
				Label("Clear", image: SBJSemanticImageReference.delete)
			}
		}
	}

	@ViewBuilder
	func actions(content: some View) -> some View {
		content
			.onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
				state.canPasteImage = UIPasteboard.general.hasImages
			}
			.fullScreenCover(item: $state.viewingImage) { identifiable in
				PhotoEditSheet(viewing: identifiable.value) {
					state.viewingImage = nil
				}
			}
			.sheet(item: $state.shareImage) { identifiable in
				ShareSheet(activityItems: [identifiable.value], applicationActivities: nil)
			}
			.photosPicker(
				isPresented: $state.isPickerPresented,
				selection: $state.photoPickerSelection,
				matching: .images
			)
			.onChange(of: state.photoPickerSelection) { _, item in
				guard let item else { return }
				state.photoPickerSelection = nil
				Task { @MainActor in
					guard let data = try? await item.loadTransferable(type: Data.self),
						  let imported = UIImage(data: data) else { return }
					state.importedImage = imported
				}
			}
			.fullScreenCover(isPresented: $state.isCameraPresented) {
				CameraPickerView(image: $state.importedImage)
			}
			.fileImporter(
				isPresented: $state.isFileImporterPresented,
				allowedContentTypes: [.image],
				allowsMultipleSelection: false
			) { result in
				switch result {
				case .success(let urls):
					if let url = urls.first {
						let accessGranted = url.startAccessingSecurityScopedResource()
						defer {
							if accessGranted {
								url.stopAccessingSecurityScopedResource()
							}
						}
						do {
							var coordinatedError: NSError?
							let coordinator = NSFileCoordinator()
							coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatedError) { coordinatedURL in
								// Load the data
								if let data = try? Data(contentsOf: coordinatedURL),
								   let uiImage = UIImage(data: data) {
									DispatchQueue.main.async {
										state.importedImage = uiImage
									}
								} else {
									// Handle unsupported/invalid image data
									print("Failed to read image data from: \(coordinatedURL)")
								}
							}
							if let coordinatedError {
								throw coordinatedError
							}
						} catch {
							print("File import error:", error)
						}
					}
				case .failure:
					break
				}
			}
			.alert("Clear Photo", isPresented: $state.isPhotoClearPresented) {
				Button("Clear", role: .destructive) {
					DispatchQueue.main.async {
						self.image = nil
					}
				}
				Button("Cancel", role: .cancel) { }
			}
			.onChange(of: state.importedImage) { _, newValue in
				state.importedImage = nil
				if let newValue {
					if editImports {
						DispatchQueue.main.async {
							state.editingImage = IdentifiableImage(newValue)
						}
					}
					else {
						image = newValue
					}
				} // else canceled
			}
			.fullScreenCover(item: $state.editingImage) { identifiable in
				PhotoEditSheet(image: identifiable.value) { result in
					if let result {
						image = result
					} // else canceled
				}
				dismiss: {
					state.editingImage = nil
				}
			}
	}

	public var body: some View {
		if options.rawValue.nonzeroBitCount == 1 {
			actions(content: menuItems(true))
		} else {
			Menu {
				menuItems(false)
					.labelStyle(.titleAndIcon)
			} label: {
				actions(content: label())
			}
			.menuStyle(.button)
		}
	}
}
#endif

