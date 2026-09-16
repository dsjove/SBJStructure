import CoreGraphics
import Foundation

public enum PhotoCropOption: Hashable, Sendable, Codable, Identifiable {
    case original
    case square
    case ratio(width: Int, height: Int)
    case free

    public var id: String {
        switch self {
        case .original: return "original"
        case .square: return "square"
        case .ratio(let width, let height): return "ratio-\(width)-\(height)"
        case .free: return "free"
        }
    }

    public var title: String {
        switch self {
        case .original: return "Original"
        case .square: return "Square"
        case .ratio(let width, let height): return "\(width):\(height)"
        case .free: return "Free"
        }
    }

    public static let fourThree: Self = .ratio(width: 4, height: 3)
    public static let threeTwo: Self = .ratio(width: 3, height: 2)
    public static let sixteenNine: Self = .ratio(width: 16, height: 9)
    public static let fourFive: Self = .ratio(width: 4, height: 5)
    public static let fiveSeven: Self = .ratio(width: 5, height: 7)

    func aspectRatio(sourceSize: CGSize, freeAspectRatio: Double) -> CGFloat {
        switch self {
        case .original:
            guard sourceSize.height > 0 else { return 1 }
            return sourceSize.width / sourceSize.height
        case .square:
            return 1
        case .ratio(let width, let height):
            guard width > 0, height > 0 else { return 1 }
            return CGFloat(width) / CGFloat(height)
        case .free:
            return max(0.1, CGFloat(freeAspectRatio))
        }
    }
}

public enum PhotoFramingConstraint: Sendable, Hashable, Codable {
    /// The transformed image must cover the complete crop/output rectangle.
    case cover
    /// The transformed image may expose frame background, but may not become
    /// completely contained inside the visual frame.
    case overlap
    /// No framing constraint is imposed by the editor.
    case none
}

public enum PhotoMirrorAxis: String, Sendable, Hashable, Codable {
    case horizontal
    case vertical
}

/// Capabilities and policy for one PhotoEditor presentation.
///
/// This value deliberately describes what the caller permits. It contains no
/// user edit state; that lives in PhotoEditGeometry.
public struct PhotoEditorOptions: Sendable, Hashable {
    public var cropOptions: [PhotoCropOption]
    public var allowsNoCrop: Bool
    public var allowsQuarterTurnRotation: Bool
    public var allowsFreeRotation: Bool
    public var allowsMirror: Bool
    public var framingConstraint: PhotoFramingConstraint
    public var allowsNoneFraming: Bool
    public var maximumMagnification: Double
    public var allowsMarkup: Bool
    public var allowsShare: Bool

    public init(
        cropOptions: [PhotoCropOption] = [.original, .square, .fourThree, .threeTwo, .sixteenNine, .free],
        allowsNoCrop: Bool = true,
        allowsQuarterTurnRotation: Bool = true,
        allowsFreeRotation: Bool = true,
        allowsMirror: Bool = true,
        framingConstraint: PhotoFramingConstraint = .overlap,
        allowsNoneFraming: Bool = true,
        maximumMagnification: Double = 8,
        allowsMarkup: Bool = true,
        allowsShare: Bool = true
    ) {
        self.cropOptions = cropOptions
        self.allowsNoCrop = allowsNoCrop
        self.allowsQuarterTurnRotation = allowsQuarterTurnRotation
        self.allowsFreeRotation = allowsFreeRotation
        self.allowsMirror = allowsMirror
        self.framingConstraint = framingConstraint
        self.allowsNoneFraming = allowsNoneFraming
        self.maximumMagnification = max(1, maximumMagnification)
        self.allowsMarkup = allowsMarkup
        self.allowsShare = allowsShare
    }

    /// Character/avatar-style editing: a required square crop with the common
    /// geometry tools and markup.
    public static let portrait = PhotoEditorOptions(
        cropOptions: [.square],
        allowsNoCrop: false,
        framingConstraint: .cover
    )

    public static let `default` = PhotoEditorOptions()

    /// Quarter-turn rotation makes a vertical mirror redundant from the user's
    /// point of view (180° + horizontal mirror). When quarter-turn rotation is
    /// unavailable, expose both mirror axes.
    public var availableMirrorAxes: Set<PhotoMirrorAxis> {
        guard allowsMirror else { return [] }
        return allowsQuarterTurnRotation ? [.horizontal] : [.horizontal, .vertical]
    }
}
