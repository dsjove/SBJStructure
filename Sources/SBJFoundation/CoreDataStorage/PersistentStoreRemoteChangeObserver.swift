import Combine
import CoreData
import Foundation

/// Keeps the Core Data remote-store notification plumbing out of individual
/// apps while leaving the actual reconciliation policy with the app.
///
/// TODO(CoreDataStorage strategy): If the remaining CloudKit apps show the same
/// cache/root/repair refresh sequence, promote that sequence into a reusable
/// coordinator instead of having each app register parallel callbacks.
@MainActor
public final class PersistentStoreRemoteChangeObserver {
    private var cancellable: AnyCancellable?

    public init(action: @escaping @MainActor () -> Void) {
        cancellable = NotificationCenter.default
            .publisher(for: .NSPersistentStoreRemoteChange)
            .sink { _ in
                Task { @MainActor in
                    action()
                }
            }
    }

    deinit {
        cancellable?.cancel()
    }
}
