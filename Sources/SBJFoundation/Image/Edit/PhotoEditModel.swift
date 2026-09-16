#if !os(watchOS) && !os(tvOS) && canImport(UIKit)
import CoreGraphics
import Foundation

struct NormalizedPhotoOffset: Sendable, Equatable, Codable {
    var x: Double = 0
    var y: Double = 0

    static let zero = Self()
}

struct PhotoRotation: Sendable, Equatable, Codable {
    var quarterTurns: Int = 0
    var fineDegrees: Double = 0

    var degrees: Double {
        Double(((quarterTurns % 4) + 4) % 4) * 90 + fineDegrees
    }

    mutating func rotate(clockwise: Bool) {
        quarterTurns += clockwise ? 1 : -1
        quarterTurns = ((quarterTurns % 4) + 4) % 4
    }
}

struct PhotoMirrorState: Sendable, Equatable, Codable {
    var horizontal = false
    var vertical = false

    mutating func toggle(_ axis: PhotoMirrorAxis) {
        switch axis {
        case .horizontal: horizontal.toggle()
        case .vertical: vertical.toggle()
        }
    }
}

struct PhotoCropState: Sendable, Equatable, Codable {
    var option: PhotoCropOption?
    var freeAspectRatio: Double

    init(option: PhotoCropOption?, sourceSize: CGSize) {
        self.option = option
        self.freeAspectRatio = sourceSize.height > 0
            ? Double(sourceSize.width / sourceSize.height)
            : 1
    }
}

struct PhotoEditGeometry: Sendable, Equatable, Codable {
    var crop: PhotoCropState
    /// Placement expressed as a proportion of the currently rendered image
    /// dimensions, not screen points. A value of 0.10 means ten percent of the
    /// image dimension along that screen axis.
    var placement: NormalizedPhotoOffset = .zero
    /// User magnification relative to the minimum legal scale established by
    /// the current crop, rotation and framing constraint.
    var magnification: Double = 1
    var rotation = PhotoRotation()
    var mirror = PhotoMirrorState()

    init(crop: PhotoCropState) {
        self.crop = crop
    }

    mutating func resetPreservingCrop() {
        placement = .zero
        magnification = 1
        rotation = .init()
        mirror = .init()
    }
}
#endif
