#if !os(watchOS) && canImport(UIKit)
import UIKit

/// A fully prepared payload for one UIKit share presentation.
///
/// Prepare expensive representations before constructing this value. The share
/// presenter retains the exact payload for the lifetime of the activity sheet,
/// so SwiftUI recomputation never asks the caller to regenerate it.
@MainActor
public struct SBJSharePayload {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]?

    public init(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
    }

    public init(
        _ activityItem: Any,
        applicationActivities: [UIActivity]? = nil
    ) {
        self.init(
            activityItems: [activityItem],
            applicationActivities: applicationActivities
        )
    }
}
#endif
