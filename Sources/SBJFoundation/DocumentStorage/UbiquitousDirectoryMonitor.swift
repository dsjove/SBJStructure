import Foundation

/// RAII owner for an `NSMetadataQuery` watching one iCloud Documents subtree.
/// Creating the monitor starts observation when iCloud is available; releasing it
/// stops the query, removes observers, and cancels pending callbacks.
@MainActor
public final class UbiquitousDirectoryMonitor {
	private let query = NSMetadataQuery()
	private var observers: [NSObjectProtocol] = []
	private let directoryURL: () -> URL
	private let onChange: () -> Void
	private var queryStarted = false
	private var pendingChange: DispatchWorkItem?

	public init(directoryURL: @escaping () -> URL, onChange: @escaping () -> Void) {
		self.directoryURL = directoryURL
		self.onChange = onChange

		let center = NotificationCenter.default
		observers.append(center.addObserver(
			forName: .NSUbiquityIdentityDidChange,
			object: nil,
			queue: .main
		) { [weak self] _ in
			Task { @MainActor in
				self?.restartQuery()
				self?.scheduleChange()
			}
		})

		for name in [Notification.Name.NSMetadataQueryDidFinishGathering, .NSMetadataQueryDidUpdate] {
			observers.append(center.addObserver(forName: name, object: query, queue: .main) { [weak self] _ in
				Task { @MainActor in self?.scheduleChange() }
			})
		}
		startQueryIfAvailable()
	}

	private func startQueryIfAvailable() {
		guard !queryStarted, FileManager.default.url(forUbiquityContainerIdentifier: nil) != nil else { return }
		query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
		query.predicate = NSPredicate(format: "%K BEGINSWITH %@", NSMetadataItemPathKey, directoryURL().path)
		query.notificationBatchingInterval = 0.5
		queryStarted = query.start()
	}

	private func scheduleChange() {
		pendingChange?.cancel()
		let work = DispatchWorkItem { [weak self] in self?.onChange() }
		pendingChange = work
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: work)
	}

	private func restartQuery() {
		if queryStarted { query.stop() }
		queryStarted = false
		startQueryIfAvailable()
	}

	isolated deinit {
		pendingChange?.cancel()
		if queryStarted { query.stop() }
		observers.forEach(NotificationCenter.default.removeObserver)
	}
}
