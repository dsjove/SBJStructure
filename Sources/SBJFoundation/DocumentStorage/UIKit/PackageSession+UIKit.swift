#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import Foundation
import UIKit

/// Active lifecycle for one package-backed file on UIKit platforms.
///
/// `UIDocument` owns coordinated access, autosaving, file presentation and
/// version-conflict tracking. Clients interact only with this platform-neutral
/// API and do not need to know that UIKit is the backend.
public final class PackageSession<Document: PackageDocument>: UIDocument, @unchecked Sendable {
	public typealias Snapshot = Document.Snapshot
	private let stateLock = NSLock()
	private var storedState: Snapshot
		private let onEvent: @MainActor @Sendable (PackageSessionEvent<Snapshot>) async -> Void

	public var state: Snapshot {
		stateLock.withLock { storedState }
	}

	public init(
		fileURL: URL,
		state: Snapshot,
		onEvent: @escaping @MainActor @Sendable (PackageSessionEvent<Snapshot>) async -> Void
	) {
		self.storedState = state
		self.onEvent = onEvent
		super.init(fileURL: fileURL)

		NotificationCenter.default.addObserver(
			self,
			selector: #selector(documentStateDidChange(_:)),
			name: UIDocument.stateChangedNotification,
			object: self
		)
	}

	@objc private func documentStateDidChange(_ notification: Notification) {
		guard documentState.contains(.inConflict) else { return }
		emit(.conflict)
	}

	public override func contents(forType typeName: String) throws -> Any {
		try Document.fileWrapper(for: state)
	}

	public override func load(fromContents contents: Any, ofType typeName: String?) throws {
		guard let wrapper = contents as? FileWrapper else { throw CocoaError(.fileReadCorruptFile) }
		let loaded = try Document.snapshot(from: wrapper)
		stateLock.withLock { storedState = loaded }
		emit(.loaded(loaded))
	}

	public override func presentedItemDidMove(to newURL: URL) {
		super.presentedItemDidMove(to: newURL)
		emit(.moved(newURL))
	}

	public override func accommodatePresentedItemDeletion(
		completionHandler: @escaping @Sendable (Error?) -> Void
	) {
		emit(.deleted)
		super.accommodatePresentedItemDeletion(completionHandler: completionHandler)
	}

	public override func handleError(_ error: any Error, userInteractionPermitted: Bool) {
		emit(.error(error))
		super.handleError(error, userInteractionPermitted: userInteractionPermitted)
	}

	private func emit(_ event: PackageSessionEvent<Snapshot>) {
		Task { @MainActor [onEvent] in await onEvent(event) }
	}

	@MainActor
	public func replaceState(_ state: Snapshot) {
		stateLock.withLock { storedState = state }
		updateChangeCount(.done)
	}

	@MainActor
	public func discardUnsavedChanges() {
		updateChangeCount(.cleared)
	}

	@MainActor
	public func openSession() async throws {
		try await withCheckedThrowingContinuation { continuation in
			open { success in
				if success { continuation.resume() }
				else { continuation.resume(throwing: CocoaError(.fileReadUnknown)) }
			}
		}
	}

	@MainActor
	public func createSession() async throws {
		try await withCheckedThrowingContinuation { continuation in
			save(to: fileURL, for: .forCreating) { success in
				if success { continuation.resume() }
				else { continuation.resume(throwing: CocoaError(.fileWriteUnknown)) }
			}
		}
	}

	@MainActor
	public func saveNow() async throws {
		try await withCheckedThrowingContinuation { continuation in
			autosave { success in
				if success { continuation.resume() }
				else { continuation.resume(throwing: CocoaError(.fileWriteUnknown)) }
			}
		}
	}

	@MainActor
	public func revertToDisk() async throws {
		try await withCheckedThrowingContinuation { continuation in
			revert(toContentsOf: fileURL) { success in
				if success { continuation.resume() }
				else { continuation.resume(throwing: CocoaError(.fileReadUnknown)) }
			}
		}
	}

	@MainActor
	public func resolveContentConflict(keepingCurrent: Bool) async throws {
		if keepingCurrent {
			try await saveNow()
			try resolvePackageFileVersions(at: fileURL, keepingCurrent: true)
		} else {
			discardUnsavedChanges()
			try resolvePackageFileVersions(at: fileURL, keepingCurrent: false)
			try await revertToDisk()
		}
	}

	@MainActor
	public func closeSession() async {
		NotificationCenter.default.removeObserver(
			self,
			name: UIDocument.stateChangedNotification,
			object: self
		)
		await withCheckedContinuation { continuation in
			close { _ in continuation.resume() }
		}
	}
}
#endif
