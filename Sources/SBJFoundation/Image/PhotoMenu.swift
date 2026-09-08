#if !os(watchOS) && canImport(UIKit)
import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

public struct _DefaultPhotoMenuLabel: View {
	let isFilled: Bool
	public var body: some View {
		Image(.system(isFilled ? "photo.fill" : "photo"))
			.controlSize(.regular)
			.buttonStyle(.borderedProminent)
			.accessibilityAddTraits(.isButton)
	}
}

@MainActor
private final class PhotoMenuState: ObservableObject {
    @Published var isPhotoPickerPresented = false
    @Published var photoPickerSelection: PhotosPickerItem?
    @Published var isCameraPresented = false
    @Published var isFileImporterPresented = false
    @Published var isPhotoClearPresented = false
    @Published var canPasteImage = false
    
//    @Published var viewingImage: IdentifiableImage?
//    @Published var editingImage: IdentifiableImage?
}

/// Imports and manages image resource content without making `UIImage` the
/// persisted/editable value.
///
/// Files, Photos and Paste preserve encoded bytes and their UTType whenever
/// possible. Camera images are encoded away from the main actor before being
/// returned through the binding.
public struct PhotoMenu<Content: View>: View {
    @Binding private var resource: SBJResourceContent?
    @Environment(\.presentationChromeSuppression) private var presentationChromeSuppression
    @StateObject private var state = PhotoMenuState()
    @State private var isSuppressingPresentationChrome = false

    private let options: PhotoMenuOptions
    private let label: () -> Content

    public init(
        resource: Binding<SBJResourceContent?>,
        options: PhotoMenuOptions = .all
    ) where Content == _DefaultPhotoMenuLabel {
        self._resource = resource
        self.options = options
        self.label = {
            _DefaultPhotoMenuLabel(isFilled: resource.wrappedValue != nil)
        }
    }

    public init(
        resource: Binding<SBJResourceContent?>,
        options: PhotoMenuOptions = .modify,
        @ViewBuilder label: @escaping () -> Content
    ) {
        self._resource = resource
        self.options = options
        self.label = label
    }

    @MainActor
    private var image: UIImage? {
        resource?.uiImage
    }

    @ViewBuilder
    private func menuItems(_ labelIsHidden: Bool, sharePresenter: SBJSharePresenter) -> some View {
//        if options.contains(.view), let image {
//            menuButton("View", labeled: !labelIsHidden, systemImage: "eye") {
//                state.viewingImage = IdentifiableImage(image)
//            }
//        }

        if options.contains(.share), let image {
            SBJShareButton(
                presenter: sharePresenter,
                prepare: { SBJSharePayload(image) }
            ) {
                if !labelIsHidden {
                    Label("Share", image: SBJSemanticImageReference.share)
                } else {
                    Image(SBJSemanticImageReference.share)
                        .accessibilityLabel("Share")
                }
            }
        }

        if options.contains(.photos) {
            menuButton("Photos", labeled: !labelIsHidden, systemImage: "photo.on.rectangle") {
                state.isPhotoPickerPresented = true
            }
        }

        if options.contains(.camera), PhotoMenuOptions.canShowCamera, CameraPickerView.isAvailable {
            menuButton("Camera", labeled: !labelIsHidden, systemImage: "camera") {
                state.isCameraPresented = true
            }
        }

        if options.contains(.files) {
            menuButton("Files", labeled: !labelIsHidden, systemImage: "folder") {
                state.isFileImporterPresented = true
            }
        }

        if options.contains(.paste) {
            menuButton("Paste", labeled: !labelIsHidden, systemImage: "doc.on.clipboard") {
                importFromPasteboard()
            }
            .disabled(!state.canPasteImage)
        }

//		if options.contains(.edit) && resource != nil {
//			menuButton("Edit", labeled: !labelIsHidden, systemImage: "pencil") {
//				if let currentImage = image {
//					DispatchQueue.main.async {
//						state.importedImage = currentImage
//					}
//				}
//			}
//		}

        if options.contains(.clear), resource != nil {
            Button(role: .destructive) {
                state.isPhotoClearPresented = true
            } label: {
                Label("Clear", image: .system("trash"))
            }
        }
    }

    @ViewBuilder
    private func menuButton(
        _ title: LocalizedStringKey,
        labeled: Bool,
        systemImage: String,
        action: @escaping @MainActor () -> Void
    ) -> some View {
        Button(action: action) {
            if labeled {
                Label(title, systemImage: systemImage)
            } else {
                Image(systemName: systemImage)
                    .accessibilityLabel(title)
            }
        }
    }

    @ViewBuilder
    private func actions(content: some View) -> some View {
        content
            .onAppear {
                refreshPasteAvailability()
            }
            // Intentional polling: pasteboard availability can remain stale on
            // some supported systems when queried only at presentation time.
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                refreshPasteAvailability()
            }
            .photosPicker(
                isPresented: $state.isPhotoPickerPresented,
                selection: $state.photoPickerSelection,
                matching: .images
            )
            .onChange(of: state.photoPickerSelection) { _, item in
                guard let item else { return }
                state.photoPickerSelection = nil
                Task { await importPhotoPickerItem(item) }
            }
//            .fullScreenCover(item: $state.viewingImage) { identified in
//                PhotoViewer(image: identified.value)
//            }
            .fullScreenCover(isPresented: $state.isCameraPresented) {
                CameraPickerView { importedImage in
                    state.isCameraPresented = false
                    guard let importedImage else { return }
                    Task { await importCameraImage(importedImage) }
                }
            }
            .fileImporter(
                isPresented: $state.isFileImporterPresented,
                allowedContentTypes: [.image],
                allowsMultipleSelection: false
            ) { result in
                guard case .success(let urls) = result, let url = urls.first else { return }
                Task { await importFile(url) }
            }
            .alert("Clear Photo", isPresented: $state.isPhotoClearPresented) {
                Button("Clear", role: .destructive) {
                    resource = nil
                }
                Button("Cancel", role: .cancel) { }
            }
    }

    @MainActor
    private func refreshPasteAvailability() {
        state.canPasteImage = UIPasteboard.general.hasImages
    }

    @MainActor
    private func importFromPasteboard() {
        let pasteboard = UIPasteboard.general

        for typeIdentifier in pasteboard.types {
            let type = UTType(typeIdentifier)
            guard type?.conforms(to: .image) == true,
                  let data = pasteboard.data(forPasteboardType: typeIdentifier),
                  let type else { continue }
            resource = .init(data: data, contentType: type)
            return
        }

        // Some systems expose an image but not a directly retrievable encoded
        // representation. Fall back to off-main encoding in that case.
        guard let image = pasteboard.image else { return }
        Task { await importCameraImage(image) }
    }

    @MainActor
    private func importPhotoPickerItem(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self) else { return }
        let type = item.supportedContentTypes.first(where: { $0.conforms(to: .image) }) ?? .image
        resource = .init(data: data, contentType: type)
    }

    @MainActor
    private func importFile(_ url: URL) async {
        guard let imported = await Self.readImageResource(at: url) else { return }
        resource = imported
    }

    @MainActor
    private func importCameraImage(_ image: UIImage) async {
        guard let imported = await PhotoResourceEncoding.encode(image) else { return }
        resource = imported
    }

    private nonisolated static func readImageResource(at url: URL) async -> SBJResourceContent? {
        await Task.detached(priority: .userInitiated) {
            let accessGranted = url.startAccessingSecurityScopedResource()
            defer {
                if accessGranted { url.stopAccessingSecurityScopedResource() }
            }

            var coordinatedError: NSError?
            var imported: SBJResourceContent?
            let coordinator = NSFileCoordinator()
            coordinator.coordinate(readingItemAt: url, options: [], error: &coordinatedError) { coordinatedURL in
                guard let data = try? Data(contentsOf: coordinatedURL) else { return }
                let type = (try? coordinatedURL.resourceValues(forKeys: [.contentTypeKey]).contentType)
                    ?? UTType(filenameExtension: coordinatedURL.pathExtension)
                guard let type, type.conforms(to: .image) else { return }
                imported = .init(data: data, contentType: type)
            }
            guard coordinatedError == nil else { return nil }
            return imported
        }.value
    }

    /// Parent editor actions should not remain exposed while PhotoMenu owns a
    /// modal presentation. This intentionally includes sheets, pickers and alerts,
    /// not just the camera: parent actions should never act through child UI.
    private var suppressesPresentationChrome: Bool {
        state.isPhotoPickerPresented
        || state.isCameraPresented
        || state.isFileImporterPresented
        || state.isPhotoClearPresented
//        || state.viewingImage != nil
//        || state.editingImage != nil
    }

    @MainActor
    private func updatePresentationChromeSuppression(_ shouldSuppress: Bool) {
        guard shouldSuppress != isSuppressingPresentationChrome else { return }
        isSuppressingPresentationChrome = shouldSuppress
        if shouldSuppress {
            presentationChromeSuppression.begin()
        } else {
            presentationChromeSuppression.end()
        }
    }

    public var body: some View {
        SBJSharePresentationHost { sharePresenter in
            actions(
                content: CollapsingMenu {
                    menuItems(false, sharePresenter: sharePresenter)
                } collapsedContent: {
                    menuItems(true, sharePresenter: sharePresenter)
                } label: {
                    label()
                }
                .menuStyle(.button)
            )
            .onChange(of: suppressesPresentationChrome, initial: true) { _, shouldSuppress in
                updatePresentationChromeSuppression(shouldSuppress)
            }
            .onDisappear {
                // Balance an outstanding begin() if this menu leaves the hierarchy
                // while one of its child presentations is active.
                updatePresentationChromeSuppression(false)
            }
        }
    }
}

/// Non-generic encoding boundary so detached work does not capture
/// `PhotoMenu<Content>.Type` (which triggers Swift 6 Sendable-metatype diagnostics).
private enum PhotoResourceEncoding {
    private struct SendableImageBox: @unchecked Sendable {
        let image: UIImage
    }

    @MainActor
    static func encode(_ image: UIImage) async -> SBJResourceContent? {
        let box = SendableImageBox(image: image)
        return await Task.detached(priority: .userInitiated) {
            let hasAlpha: Bool = {
                guard let alphaInfo = box.image.cgImage?.alphaInfo else { return false }
                switch alphaInfo {
                case .first, .last, .premultipliedFirst, .premultipliedLast:
                    return true
                default:
                    return false
                }
            }()

            if hasAlpha, let data = box.image.pngData() {
                return .init(data: data, contentType: .png)
            }
            if let data = box.image.jpegData(compressionQuality: 0.92) {
                return .init(data: data, contentType: .jpeg)
            }
            if let data = box.image.pngData() {
                return .init(data: data, contentType: .png)
            }
            return nil
        }.value
    }
}

//@MainActor
//private struct PhotoViewer: View {
//    let image: UIImage
//    @Environment(\.dismiss) private var dismiss
//
//    var body: some View {
//        NavigationStack {
//            GeometryReader { geometry in
//                ScrollView([.horizontal, .vertical]) {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFit()
//                        .frame(
//                            minWidth: geometry.size.width,
//                            minHeight: geometry.size.height
//                        )
//                }
//            }
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Done") { dismiss() }
//                }
//            }
//        }
//    }
//}

#endif
