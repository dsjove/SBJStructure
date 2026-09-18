import Foundation
import Observation

public enum CameraError: LocalizedError, Sendable {
    case authorizationDenied
    case authorizationRestricted
    case noCameraAvailable
    case cannotAddCameraInput
    case cannotAddPhotoOutput
    case sessionStartFailed
    case captureAlreadyInProgress
    case jpegDataCreationFailed
    case torchUnavailable
    case torchConfigurationFailed
    case unsupportedPlatform

    public var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            "Camera access was denied."
        case .authorizationRestricted:
            "Camera access is restricted."
        case .noCameraAvailable:
            "No camera is available."
        case .cannotAddCameraInput:
            "Cannot add the camera input."
        case .cannotAddPhotoOutput:
            "Cannot add the photo output."
        case .sessionStartFailed:
            "Failed to start the camera session."
        case .captureAlreadyInProgress:
            "A photo capture is already in progress."
        case .jpegDataCreationFailed:
            "Failed to create JPEG data."
        case .torchUnavailable:
            "The torch is unavailable for the current camera."
        case .torchConfigurationFailed:
            "Failed to configure the torch."
        case .unsupportedPlatform:
            "Camera capture is not available on this platform."
        }
    }
}

/// The camera capability used by clients of SBJFoundation Camera.
///
/// The AVFoundation implementation remains private so the public API compiles
/// on every Apple platform, including platforms where ordinary still-camera
/// capture is unavailable to third-party apps.
public protocol Camera: AnyObject, Observable {
    var isAuthorized: Bool { get }
    var hasCamera: Bool { get }
    var hasCameraOptions: Bool { get }
    var hasFlash: Bool { get }
    var cameraPosition: CameraPosition { get }
    var flashMode: CameraFlashMode { get }

    func start(
        initialFlashMode: CameraFlashMode,
        initialCameraPosition: CameraPosition
    ) async throws

    func stop()
    func poll()
    func capture(completion: @escaping @MainActor @Sendable (Result<CapturedAttachment, Error>) -> Void)
    func nextCameraPosition(requesting: CameraPosition?) async throws -> CameraPosition
    func nextFlashMode(requesting: CameraFlashMode?) async throws -> CameraFlashMode
}

public extension Camera {
    func nextCameraPosition() async throws -> CameraPosition {
        try await nextCameraPosition(requesting: nil)
    }

    func nextFlashMode() async throws -> CameraFlashMode {
        try await nextFlashMode(requesting: nil)
    }
}

/// Creates the standard Apple-framework-backed camera implementation.
public enum CameraFactory {
    public static func make() -> any Camera {
        #if os(iOS) || os(macOS)
        CameraModel()
        #else
        UnavailableCamera()
        #endif
    }
}

@Observable
private final class UnavailableCamera: Camera {
    var isAuthorized: Bool { false }
    var hasCamera: Bool { false }
    var hasCameraOptions: Bool { false }
    var hasFlash: Bool { false }
    var cameraPosition: CameraPosition { .unspecified }
    var flashMode: CameraFlashMode { .off }

    func start(
        initialFlashMode: CameraFlashMode,
        initialCameraPosition: CameraPosition
    ) async throws {
        throw CameraError.unsupportedPlatform
    }

    func stop() { }
    func poll() { }

    func capture(completion: @escaping @MainActor @Sendable (Result<CapturedAttachment, Error>) -> Void) {
        Task { @MainActor in
            completion(.failure(CameraError.unsupportedPlatform))
        }
    }

    func nextCameraPosition(requesting: CameraPosition?) async throws -> CameraPosition {
        throw CameraError.unsupportedPlatform
    }

    func nextFlashMode(requesting: CameraFlashMode?) async throws -> CameraFlashMode {
        throw CameraError.unsupportedPlatform
    }
}
