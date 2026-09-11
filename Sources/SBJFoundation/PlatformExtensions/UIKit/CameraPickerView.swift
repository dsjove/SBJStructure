#if !os(watchOS) && canImport(UIKit)
import SwiftUI
import UIKit
import UniformTypeIdentifiers
#if targetEnvironment(macCatalyst)
import AVFoundation
#endif

/// A SwiftUI still-camera capture view.
///
/// iOS/iPadOS use `UIImagePickerController`, which remains the lightweight
/// system camera UI. Mac Catalyst uses AVFoundation directly because the UIKit
/// camera picker can present its chrome without establishing a usable Mac camera
/// capture session. Native visionOS does not expose ordinary still-camera capture
/// through `UIImagePickerController`, so camera capture is unavailable there.
///
/// App configuration (manual Xcode steps):
/// - On the app target, open Signing & Capabilities and add the **Camera**
///   capability. Supply the user-facing camera purpose there; the built app must
///   contain a non-empty `NSCameraUsageDescription`.
/// - For Mac Catalyst, also add/expand the **App Sandbox** capability and enable
///   **Hardware → Camera**. This writes the required sandbox entitlement
///   `com.apple.security.device.camera = true` to the app's entitlements file.
///   The top-level Camera capability/usage description does not replace this
///   Catalyst sandbox entitlement; Catalyst requires both.
/// - If camera permission becomes stale while developing, quit the app and use
///   `tccutil reset Camera`, then relaunch so macOS can request permission again.
///   This is a development/debugging step, not an app-runtime requirement.
/// - A photo-library usage description is not required merely to select photos
///   with SwiftUI `PhotosPicker` elsewhere in the app.
@MainActor
public struct CameraPickerView: View {
    public typealias Completion = @MainActor (UIImage?) -> Void

    public static var isAvailable: Bool {
        #if targetEnvironment(macCatalyst)
        // Availability here means that AVFoundation can discover a video device.
        // Permission is intentionally handled later by CatalystCameraModel.
        return AVCaptureDevice.default(for: .video) != nil
        #elseif os(visionOS)
        // visionOS does not provide ordinary app access to the device cameras
        // through UIImagePickerController. Specialized enterprise main-camera
        // access, if ever needed, belongs behind a separate capture provider.
        return false
        #elseif os(iOS)
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return false }
        return UIImagePickerController.isCameraDeviceAvailable(.front)
            || UIImagePickerController.isCameraDeviceAvailable(.rear)
        #else
        return false
        #endif
    }

    private let allowsEditing: Bool
    private let remembersCameraDevice: Bool
    private let completion: Completion

    @Environment(\.dismiss) private var dismiss

    public init(
        image: Binding<UIImage?>,
        allowsEditing: Bool = false,
        remembersCameraDevice: Bool = true
    ) {
        self.allowsEditing = allowsEditing
        self.remembersCameraDevice = remembersCameraDevice
        self.completion = { capturedImage in
            guard let capturedImage else { return }
            image.wrappedValue = capturedImage
        }
    }

    public init(
        allowsEditing: Bool = false,
        remembersCameraDevice: Bool = true,
        completion: @escaping Completion
    ) {
        self.allowsEditing = allowsEditing
        self.remembersCameraDevice = remembersCameraDevice
        self.completion = completion
    }

    public var body: some View {
        Group {
            #if targetEnvironment(macCatalyst)
            CatalystCameraView { image in
                completion(image)
                dismiss()
            }
            .ignoresSafeArea()
            #elseif os(visionOS) || os(tvOS)
            ContentUnavailableView(
                "Camera Unavailable",
                systemImage: "camera.slash",
                description: Text("Camera capture is not available on this platform.")
            )
            #else
            if Self.isAvailable {
                CameraPickerController(
                    allowsEditing: allowsEditing,
                    remembersCameraDevice: remembersCameraDevice
                ) { image in
                    completion(image)
                    dismiss()
                }
                .ignoresSafeArea()
            } else {
                ContentUnavailableView(
                    "Camera Unavailable",
                    systemImage: "camera.slash",
                    description: Text("No camera source is currently available on this device.")
                )
            }
            #endif
        }
    }
}

#if targetEnvironment(macCatalyst)

@MainActor
private struct CatalystCameraView: View {
    let completion: CameraPickerView.Completion
    @StateObject private var camera = CatalystCameraModel()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.permissionState == .authorized {
                CatalystCameraPreview(session: camera.session)
                    .ignoresSafeArea()
            }

            controls

            if let errorMessage = camera.errorMessage {
                ContentUnavailableView(
                    "Camera Unavailable",
                    systemImage: "camera.slash",
                    description: Text(errorMessage)
                )
                .padding(30)
                .background(.regularMaterial)
            } else if camera.permissionState == .requesting {
                ProgressView("Requesting camera access…")
                    .padding(24)
                    .background(.regularMaterial)
            } else if camera.permissionState == .denied || camera.permissionState == .restricted {
                ContentUnavailableView(
                    "Camera Access Required",
                    systemImage: "camera.slash",
                    description: Text("Allow camera access for this app in System Settings → Privacy & Security → Camera, then reopen the camera.")
                )
                .padding(30)
                .background(.regularMaterial)
            }

            // Diagnostic overlay retained for future camera-permission debugging.
            // Uncomment when needed.
//            #if DEBUG
//            VStack {
//                Spacer()
//                diagnostics
//            }
//            .allowsHitTesting(false)
//            #endif
        }
        .task {
            await camera.start()
        }
        .onDisappear {
            Task { await camera.stop() }
        }
        .onChange(of: camera.capturedImage) { _, image in
            guard let image else { return }
            completion(image)
        }
    }

    @ViewBuilder
    private var controls: some View {
        VStack {
            HStack {
                Spacer()
                Button { completion(nil) } label: {
                    Image(.system("xmark.circle.fill"))
                        .font(.system(size: 30))
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .accessibilityLabel("Cancel")
            }
            .padding()

            Spacer()

            if camera.permissionState == .authorized && camera.errorMessage == nil {
                Button {
                    camera.capture()
                } label: {
                    ZStack {
                        Circle()
                            .stroke(.white, lineWidth: 4)
                            .frame(width: 74, height: 74)
                        Circle()
                            .fill(.white)
                            .frame(width: 62, height: 62)
                    }
                }
                .buttonStyle(.plain)
                .disabled(!camera.isReady)
                .opacity(camera.isReady ? 1 : 0.45)
                .accessibilityLabel("Take Photo")
                .padding(.bottom, 28)
            }
        }
    }

    // Diagnostic overlay retained for future debugging.
//    #if DEBUG
//    private var diagnostics: some View {
//        VStack(alignment: .leading, spacing: 3) {
//            Text("Camera diagnostics")
//                .fontWeight(.semibold)
//            Text("permission: \(camera.permissionState.rawValue)")
//            Text("usage description: \(camera.hasUsageDescription ? "present" : "MISSING")")
//            Text("device: \(camera.deviceDescription)")
//            Text("session configured: \(camera.isConfigured ? "yes" : "no")")
//            Text("session running: \(camera.isSessionRunning ? "yes" : "no")")
//            Text("ready: \(camera.isReady ? "yes" : "no")")
//        }
//        .font(.system(.caption, design: .monospaced))
//        .foregroundStyle(.white)
//        .padding(10)
//        .background(.black.opacity(0.65))
//        .clipShape(RoundedRectangle(cornerRadius: 8))
//        .padding()
//        .frame(maxWidth: .infinity, alignment: .leading)
//    }
//    #endif
}

/// AVFoundation's capture classes are Objective-C reference types that have not
/// adopted Swift `Sendable`. All mutation of the session graph and all
/// start/stop work is serialized on `queue`; the unchecked conformance is the
/// explicit bridge between that AVFoundation model and Swift 6 concurrency.
///
/// Keep this type private: callers should consume only the Sendable snapshots
/// returned by its async methods. The `session` reference is exposed solely so
/// a main-actor preview layer can display it; it is never mutated there.
private final class CatalystCaptureSession: @unchecked Sendable {
    enum ConfigurationResult: Sendable {
        case success(deviceDescription: String)
        case noDevice
        case cannotAddInput
        case cannotAddOutput
        case inputFailure(String)
    }

    let session = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "CameraPickerView.captureSession")
    private var configured = false

    func configure() async -> ConfigurationResult {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                if configured {
                    let description = session.inputs
                        .compactMap { ($0 as? AVCaptureDeviceInput)?.device }
                        .first
                        .map { "\($0.localizedName) [\($0.uniqueID)]" }
                        ?? "configured device"
                    continuation.resume(returning: .success(deviceDescription: description))
                    return
                }

                guard let device = AVCaptureDevice.default(for: .video) else {
                    continuation.resume(returning: .noDevice)
                    return
                }

                let deviceDescription = "\(device.localizedName) [\(device.uniqueID)]"

                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    session.beginConfiguration()
                    defer { session.commitConfiguration() }
                    session.sessionPreset = .photo

                    guard session.canAddInput(input) else {
                        continuation.resume(returning: .cannotAddInput)
                        return
                    }
                    session.addInput(input)

                    guard session.canAddOutput(photoOutput) else {
                        session.removeInput(input)
                        continuation.resume(returning: .cannotAddOutput)
                        return
                    }
                    session.addOutput(photoOutput)
                    configured = true
                    continuation.resume(returning: .success(deviceDescription: deviceDescription))
                } catch {
                    continuation.resume(returning: .inputFailure(error.localizedDescription))
                }
            }
        }
    }

    func startRunning() async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                if !session.isRunning {
                    session.startRunning()
                }
                continuation.resume(returning: session.isRunning)
            }
        }
    }

    func stopRunning() async -> Bool {
        await withCheckedContinuation { continuation in
            queue.async { [self] in
                if session.isRunning {
                    session.stopRunning()
                }
                continuation.resume(returning: session.isRunning)
            }
        }
    }

    /// `capturePhoto` is invoked only after configuration/start has completed
    /// and from the main actor. AVFoundation delivers delegate callbacks on an
    /// internal queue; the model's delegate method hops results back to MainActor.
    ///
    /// Keep the photo-output connection itself unmirrored. CatalystCameraPreview
    /// deliberately presents a mirrored, webcam-style preview and the delegate
    /// physically mirrors the decoded capture once so the saved image matches
    /// what the user framed. Doing the final mirror in pixels, rather than relying
    /// on EXIF/UIImage orientation flags, avoids camera/driver-specific mirroring
    /// behavior on Mac Catalyst.
    func capturePhoto(delegate: AVCapturePhotoCaptureDelegate) {
        if let connection = photoOutput.connection(with: .video),
           connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = false
        }

        photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: delegate)
    }
}

@MainActor
private final class CatalystCameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    enum PermissionState: String {
        case unknown
        case notDetermined
        case requesting
        case authorized
        case denied
        case restricted
    }

    private let captureSession = CatalystCaptureSession()
    var session: AVCaptureSession { captureSession.session }

    @Published private(set) var permissionState: PermissionState = .unknown
    @Published private(set) var isConfigured = false
    @Published private(set) var isSessionRunning = false
    @Published private(set) var isReady = false
    @Published private(set) var capturedImage: UIImage?
    @Published private(set) var errorMessage: String?
    @Published private(set) var deviceDescription = "not discovered"

    let hasUsageDescription: Bool = {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String else {
            return false
        }
        return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }()

    func start() async {
        log("start()")
        errorMessage = nil
        capturedImage = nil
        isReady = false
        isSessionRunning = false

        log("bundle id: \(Bundle.main.bundleIdentifier ?? "<nil>")")
        log("NSCameraUsageDescription present: \(hasUsageDescription)")

        guard hasUsageDescription else {
            permissionState = .unknown
            errorMessage = "NSCameraUsageDescription is missing from the built app's Info.plist."
            log("ERROR: NSCameraUsageDescription missing")
            return
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)
        log("initial authorization status: \(describe(status))")

        switch status {
        case .authorized:
            permissionState = .authorized

        case .notDetermined:
            permissionState = .notDetermined
            log("authorization not determined; explicitly calling requestAccess(for: .video)")
            permissionState = .requesting

            let granted = await AVCaptureDevice.requestAccess(for: .video)
            log("requestAccess returned: \(granted)")

            let newStatus = AVCaptureDevice.authorizationStatus(for: .video)
            log("authorization status after request: \(describe(newStatus))")
            setPermissionState(from: newStatus)

            guard granted, newStatus == .authorized else {
                if newStatus == .notDetermined {
                    errorMessage = "macOS did not resolve the camera permission request. Check the app's signing, Camera sandbox entitlement, and launch the built app again."
                }
                return
            }

        case .denied:
            permissionState = .denied
            log("camera permission denied")
            return

        case .restricted:
            permissionState = .restricted
            log("camera permission restricted")
            return

        @unknown default:
            permissionState = .unknown
            errorMessage = "Unknown camera authorization state."
            log("ERROR: unknown authorization status rawValue=\(status.rawValue)")
            return
        }

        guard permissionState == .authorized else {
            log("not configuring session because permission is \(permissionState.rawValue)")
            return
        }

        await configureAndStartSession()
    }

    func stop() async {
        isReady = false
        log("stop(): scheduling session.stopRunning()")
        let stillRunning = await captureSession.stopRunning()
        isSessionRunning = stillRunning
        log("session stopped; isRunning=\(stillRunning)")
    }

    func capture() {
        guard permissionState == .authorized else {
            log("capture ignored: permission=\(permissionState.rawValue)")
            return
        }
        guard isReady, isSessionRunning else {
            log("capture ignored: isReady=\(isReady), isRunning=\(isSessionRunning)")
            return
        }

        log("capturePhoto()")
        captureSession.capturePhoto(delegate: self)
    }

    private func configureAndStartSession() async {
        if !isConfigured {
            log("configuring capture session")
            switch await captureSession.configure() {
            case .success(let description):
                deviceDescription = description
                isConfigured = true
                log("selected device: \(description)")
                log("camera input added")
                log("photo output added")
                log("session configuration complete")

            case .noDevice:
                deviceDescription = "none"
                errorMessage = "AVFoundation cannot discover a video camera on this Mac."
                log("ERROR: AVCaptureDevice.default(for: .video) returned nil")
                return

            case .cannotAddInput:
                errorMessage = "The camera input cannot be added to the capture session."
                log("ERROR: session.canAddInput == false")
                return

            case .cannotAddOutput:
                errorMessage = "Photo output cannot be added to the capture session."
                log("ERROR: session.canAddOutput == false")
                return

            case .inputFailure(let description):
                errorMessage = "Could not create the camera input: \(description)"
                log("ERROR creating AVCaptureDeviceInput: \(description)")
                return
            }
        } else {
            log("session already configured")
        }

        log("scheduling session.startRunning()")
        let running = await captureSession.startRunning()
        isSessionRunning = running
        isReady = running
        log("session.startRunning returned; isRunning=\(running)")

        if !running {
            errorMessage = "The camera session was configured but did not start running."
        }
    }

    private func setPermissionState(from status: AVAuthorizationStatus) {
        switch status {
        case .authorized:
            permissionState = .authorized
        case .notDetermined:
            permissionState = .notDetermined
        case .denied:
            permissionState = .denied
        case .restricted:
            permissionState = .restricted
        @unknown default:
            permissionState = .unknown
        }
    }

    private func describe(_ status: AVAuthorizationStatus) -> String {
        switch status {
        case .authorized: return "authorized"
        case .notDetermined: return "notDetermined"
        case .denied: return "denied"
        case .restricted: return "restricted"
        @unknown default: return "unknown(\(status.rawValue))"
        }
    }

    private func log(_ message: String) {
        // Diagnostic console logging retained for future camera-permission debugging.
        // print("[CameraPickerView] \(message)")
    }

    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            let description = error.localizedDescription
            Task { @MainActor in
                self.log("ERROR processing captured photo: \(description)")
                self.errorMessage = "Photo capture failed: \(description)"
            }
            return
        }

        guard let data = photo.fileDataRepresentation(),
              let decodedImage = UIImage(data: data) else {
            Task { @MainActor in
                self.log("ERROR: captured photo produced no decodable image data")
                self.errorMessage = "The captured photo could not be decoded."
            }
            return
        }

        // Normalize any mirrored orientation metadata first, then physically
        // mirror the pixels exactly once. The Catalyst preview is intentionally
        // mirrored, so this makes the persisted photo match what the user saw
        // while framing it. A pixel transform is used instead of another
        // orientation flag because some Catalyst camera drivers ignore or rewrite
        // mirroring metadata when the image is subsequently encoded/displayed.
        let normalizedImage = Self.removingMirroredOrientation(from: decodedImage)
        let image = Self.horizontallyMirroredPixels(of: normalizedImage)
        let byteCount = data.count
        Task { @MainActor in
            self.log("photo captured successfully; bytes=\(byteCount)")
            self.capturedImage = image
        }
    }


    nonisolated private static func horizontallyMirroredPixels(of image: UIImage) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }

        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false

        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            let cgContext = context.cgContext
            cgContext.translateBy(x: size.width, y: 0)
            cgContext.scaleBy(x: -1, y: 1)
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    nonisolated private static func removingMirroredOrientation(from image: UIImage) -> UIImage {
        guard let cgImage = image.cgImage else { return image }

        let orientation: UIImage.Orientation
        switch image.imageOrientation {
        case .upMirrored:
            orientation = .up
        case .downMirrored:
            orientation = .down
        case .leftMirrored:
            orientation = .left
        case .rightMirrored:
            orientation = .right
        default:
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: orientation)
    }
}

private struct CatalystCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        configureMirroring(on: view.previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
        configureMirroring(on: uiView.previewLayer)
    }

    private func configureMirroring(on previewLayer: AVCaptureVideoPreviewLayer) {
        guard let connection = previewLayer.connection,
              connection.isVideoMirroringSupported else { return }
        connection.automaticallyAdjustsVideoMirroring = false
        connection.isVideoMirrored = true
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
#endif

#if os(iOS) && !targetEnvironment(macCatalyst)
@MainActor
private struct CameraPickerController: UIViewControllerRepresentable {
    let allowsEditing: Bool
    let remembersCameraDevice: Bool
    let completion: CameraPickerView.Completion

    private static let lastCameraDeviceKey = "CameraPickerView.lastCameraDevice"

    func makeCoordinator() -> Coordinator {
        Coordinator(
            remembersCameraDevice: remembersCameraDevice,
            completion: completion
        )
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = allowsEditing
        picker.mediaTypes = [UTType.image.identifier]

        if let cameraDevice = Self.cameraDevice(remembersCameraDevice: remembersCameraDevice) {
            picker.cameraDevice = cameraDevice
        }

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    private static func cameraDevice(remembersCameraDevice: Bool) -> UIImagePickerController.CameraDevice? {
        if remembersCameraDevice,
           let preferredDevice = loadPreferredCameraDevice(),
           UIImagePickerController.isCameraDeviceAvailable(preferredDevice) {
            return preferredDevice
        }

        if UIImagePickerController.isCameraDeviceAvailable(.rear) { return .rear }
        if UIImagePickerController.isCameraDeviceAvailable(.front) { return .front }
        return nil
    }

    private static func loadPreferredCameraDevice() -> UIImagePickerController.CameraDevice? {
        switch UserDefaults.standard.string(forKey: lastCameraDeviceKey) {
        case "front": return .front
        case "rear": return .rear
        default: return nil
        }
    }

    fileprivate static func savePreferredCameraDevice(_ device: UIImagePickerController.CameraDevice) {
        let value: String
        switch device {
        case .front:
            value = "front"
        case .rear:
            value = "rear"
        @unknown default:
            return
        }
        UserDefaults.standard.set(value, forKey: lastCameraDeviceKey)
    }

    @MainActor
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let remembersCameraDevice: Bool
        let completion: CameraPickerView.Completion

        init(
            remembersCameraDevice: Bool,
            completion: @escaping CameraPickerView.Completion
        ) {
            self.remembersCameraDevice = remembersCameraDevice
            self.completion = completion
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            rememberCameraDevice(from: picker)
            let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage
            completion(image)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            rememberCameraDevice(from: picker)
            completion(nil)
        }

        private func rememberCameraDevice(from picker: UIImagePickerController) {
            guard remembersCameraDevice else { return }
            CameraPickerController.savePreferredCameraDevice(picker.cameraDevice)
        }
    }
}
#endif
#endif
