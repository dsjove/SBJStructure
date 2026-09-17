#if !os(watchOS) && !os(tvOS) && canImport(UIKit)
import CoreGraphics
import Foundation

@SBJStructure
struct NormalizedPhotoOffset: Sendable, Equatable, Codable {
    @SBJNumber(range: -1...1)
    var x: Double = 0
    @SBJNumber(range: -1...1)
    var y: Double = 0

    static let zero = Self()

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        switch keyPath as AnyKeyPath {
        case \Self.x:
            return SBJPropertyInfo(
                title: "Horizontal Placement",
                summary: "Horizontal image placement normalized to the rendered image width.",
                details: "A value of 0 is centered; positive values move right and negative values move left.",
                accessibilityLabel: "Horizontal Image Placement",
                accessibilityHint: "Drag the image left or right within the crop."
            )
        case \Self.y:
            return SBJPropertyInfo(
                title: "Vertical Placement",
                summary: "Vertical image placement normalized to the rendered image height.",
                details: "A value of 0 is centered; positive values move down and negative values move up.",
                accessibilityLabel: "Vertical Image Placement",
                accessibilityHint: "Drag the image up or down within the crop."
            )
        default:
            return nil
        }
    }
}

@SBJStructure
struct PhotoRotation: Sendable, Equatable, Codable {
    @SBJInteger(range: 0...3)
    var quarterTurns: Int = 0
    @SBJNumber(range: -15...15)
    var fineDegrees: Double = 0

    var degrees: Double {
        Double(((quarterTurns % 4) + 4) % 4) * 90 + fineDegrees
    }

    mutating func rotate(clockwise: Bool) {
        quarterTurns += clockwise ? 1 : -1
        quarterTurns = ((quarterTurns % 4) + 4) % 4
    }

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        switch keyPath as AnyKeyPath {
        case \Self.quarterTurns:
            return SBJPropertyInfo(
                title: "Quarter Turns",
                summary: "Number of 90-degree clockwise rotations, normalized to zero through three.",
                details: "Quarter-turn controls may rotate in either direction; the stored representation remains normalized modulo four.",
                accessibilityLabel: "Quarter Turn Rotation",
                accessibilityHint: "Rotates the image by 90 degrees."
            )
        case \Self.fineDegrees:
            return SBJPropertyInfo(
                title: "Straighten",
                summary: "Fine rotation used by the straighten control.",
                details: "The editor constrains interactive straightening to -15 through 15 degrees.",
                accessibilityLabel: "Straighten",
                accessibilityHint: "Adjust the image rotation in small increments."
            )
        default:
            return nil
        }
    }
}

@SBJStructure
struct PhotoMirrorState: Sendable, Equatable, Codable {
    var horizontal = false
    var vertical = false

    mutating func toggle(_ axis: PhotoMirrorAxis) {
        switch axis {
        case .horizontal: horizontal.toggle()
        case .vertical: vertical.toggle()
        }
    }

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        switch keyPath as AnyKeyPath {
        case \Self.horizontal:
            return SBJPropertyInfo(
                summary: "Whether the image is mirrored left-to-right.",
                details: "False preserves the source orientation; true reflects the image across its vertical axis.",
                accessibilityLabel: "Mirror Horizontally",
                accessibilityHint: "Reflects the image from left to right."
            )
        case \Self.vertical:
            return SBJPropertyInfo(
                summary: "Whether the image is mirrored top-to-bottom.",
                details: "False preserves the source orientation; true reflects the image across its horizontal axis.",
                accessibilityLabel: "Mirror Vertically",
                accessibilityHint: "Reflects the image from top to bottom."
            )
        default:
            return nil
        }
    }
}

@SBJStructure
struct PhotoCropState: Sendable, Equatable, Codable {
    var option: PhotoCropOption
    @SBJNumber(range: 0.25...4)
    var freeAspectRatio: Double
    var swapsDimensions: Bool

    init(option: PhotoCropOption, sourceSize: CGSize, swapsDimensions: Bool = false) {
        self.option = option
        self.freeAspectRatio = sourceSize.height > 0
            ? Double(sourceSize.width / sourceSize.height)
            : 1
        self.swapsDimensions = swapsDimensions
    }

    private enum CodingKeys: String, CodingKey {
        case option
        case freeAspectRatio
        case swapsDimensions
    }

    /// Backward-compatible decoding: older edit state represented no crop as a
    /// nil optional value. A missing or null option now maps to `.none`.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        option = try container.decodeIfPresent(PhotoCropOption.self, forKey: .option) ?? .none
        freeAspectRatio = try container.decode(Double.self, forKey: .freeAspectRatio)
        swapsDimensions = try container.decodeIfPresent(Bool.self, forKey: .swapsDimensions) ?? false
    }

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        switch keyPath as AnyKeyPath {
        case \Self.option:
            return SBJPropertyInfo(
                title: "Crop",
                summary: "Active crop mode.",
                details: "None represents uncropped editing; ratio crops may transpose width and height using swapsDimensions.",
                accessibilityLabel: "Crop",
                accessibilityHint: "Choose the shape and aspect ratio of the visible image."
            )
        case \Self.freeAspectRatio:
            return SBJPropertyInfo(
                title: "Free Crop Aspect Ratio",
                summary: "Current width-to-height ratio of the resizable free crop.",
                details: "The editor constrains interactive free crop ratios to 0.25 through 4.",
                accessibilityLabel: "Resize Free Crop",
                accessibilityHint: "Drag to change the width and height of the free crop."
            )
        case \Self.swapsDimensions:
            return SBJPropertyInfo(
                title: "Swap Width and Height",
                summary: "Transposes width and height for dimensional ratio crops.",
                details: "This has no geometric effect for None, Original, Square, or Free crop modes.",
                accessibilityLabel: "Swap Width and Height",
                accessibilityHint: "Transposes the width and height of a dimensional crop."
            )
        default:
            return nil
        }
    }
}

@SBJStructure
struct PhotoEditGeometry: Sendable, Equatable, Codable {
    var crop: PhotoCropState
    /// Placement expressed as a proportion of the currently rendered image
    /// dimensions, not screen points. A value of 0.10 means ten percent of the
    /// image dimension along that screen axis.
    var placement: NormalizedPhotoOffset = .zero
    /// User magnification relative to the minimum legal scale established by
    /// the current crop, rotation and framing constraint.
    @SBJNumber(min: 1)
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

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        switch keyPath as AnyKeyPath {
        case \Self.crop:
            return SBJPropertyInfo(summary: "Crop selection and crop-specific geometry.", details: "Contains the selected crop mode, free-crop aspect ratio, and width/height transpose state.")
        case \Self.placement:
            return SBJPropertyInfo(
                summary: "Normalized pan position of the image within the edit frame.",
                details: "Placement is stored relative to rendered image dimensions so it remains independent of screen point size.",
                accessibilityLabel: "Image Position",
                accessibilityHint: "Drag to reposition the image inside the crop."
            )
        case \Self.magnification:
            return SBJPropertyInfo(
                summary: "User zoom relative to the minimum scale required by the current framing policy.",
                details: "A value of 1 is the minimum legal scale before user zoom is applied.",
                accessibilityLabel: "Image Magnification",
                accessibilityHint: "Pinch to zoom the image inside the crop."
            )
        case \Self.rotation:
            return SBJPropertyInfo(summary: "Quarter-turn and straighten rotation state.", details: "Quarter turns and fine straightening are combined when resolving the final image transform.")
        case \Self.mirror:
            return SBJPropertyInfo(summary: "Horizontal and vertical mirror state.", details: "Mirror axes are stored independently even when the editor UI exposes only the non-redundant axis.")
        default:
            return nil
        }
    }
}
#endif
