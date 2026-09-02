import Foundation

/// Accessibility semantics that can be attached to a model, descriptor, or UI item.
///
/// This is intentionally presentation-independent. SwiftUI support is supplied by
/// the `View.accessibility(_:)` adapter in `swiftUIComponents`.
public protocol Accessible {
    /// What the thing is. A text field's placeholder commonly becomes this.
    var accessibilityLabel: String? { get }

    /// Consequences or additional explanation of an action.
    var accessibilityHint: String? { get }

    /// The current value represented by the accessible item.
    var accessibilityValue: String? { get }
}

public extension Accessible {
    var accessibilityLabel: String? { nil }
    var accessibilityHint: String? { nil }
    var accessibilityValue: String? { nil }
}

/// Concrete accessibility metadata retaining the framework's original API.
public struct AccessibleItem: Accessible, Sendable, Equatable, Hashable {
    public let accessibilityLabel: String?
    public let accessibilityHint: String?
    public let accessibilityValue: String?

    public init(
        label: String? = nil,
        hint: String? = nil,
        value: String? = nil
    ) {
        self.accessibilityLabel = label
        self.accessibilityHint = hint
        self.accessibilityValue = value
    }

    public var isEmpty: Bool {
        accessibilityLabel == nil && accessibilityHint == nil && accessibilityValue == nil
    }
}
