import SwiftUI

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

private struct AccessibilityModifier: ViewModifier {
    let item: any Accessible

    func body(content: Content) -> some View {
        content
            .applyIf(item.accessibilityLabel) { view, label in
                view.accessibilityLabel(label)
            }
            .applyIf(item.accessibilityHint) { view, hint in
                view.accessibilityHint(hint)
            }
            .applyIf(item.accessibilityValue) { view, value in
                view.accessibilityValue(value)
            }
    }
}

public extension View {
    func accessibility(_ item: any Accessible) -> some View {
        modifier(AccessibilityModifier(item: item))
    }

    func accessibility(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        accessibility(AccessibleItem(
            label: label,
            hint: hint,
            value: value
        ))
    }
}
