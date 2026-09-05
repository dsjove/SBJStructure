import Foundation

public protocol AccessibleImage: Accessible {
    var image: ImageName { get }
    var labeled: Bool { get }
    var label: String { get }
}

public extension AccessibleImage {
    var labeled: Bool { false }
}

public struct AccessibleImageItem: AccessibleImage {
    public let image: ImageName
    public let labeled: Bool
    public let label: String
    public let accessibilityLabel: String?
    public let accessibilityHint: String?
    public let accessibilityValue: String?

    public init(
        image: ImageName,
        labeled: Bool = false,
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) {
        self.image = image
        self.labeled = labeled
        self.label = label
        self.accessibilityLabel = labeled ? label : nil
        self.accessibilityHint = hint
        self.accessibilityValue = value
    }
}
