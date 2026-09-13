#if !os(watchOS)
import Foundation

/// Platform-neutral events emitted by an active package session.
enum PackageSessionEvent<Snapshot: PackageDocumentSnapshot>: @unchecked Sendable {
	case loaded(Snapshot)
	case moved(URL)
	case deleted
	case conflict
	case error(any Error)
}

func resolvePackageFileVersions(at url: URL, keepingCurrent: Bool) throws {
	var coordinationError: NSError?
	var operationError: Error?
	NSFileCoordinator().coordinate(
		writingItemAt: url,
		options: [],
		error: &coordinationError
	) { coordinatedURL in
		do {
			let versions = NSFileVersion.unresolvedConflictVersionsOfItem(at: coordinatedURL) ?? []
			if !keepingCurrent, let external = versions.max(by: {
				($0.modificationDate ?? .distantPast) < ($1.modificationDate ?? .distantPast)
			}) {
				_ = try external.replaceItem(at: coordinatedURL)
			}
			for version in versions { version.isResolved = true }
			try NSFileVersion.removeOtherVersionsOfItem(at: coordinatedURL)
		} catch {
			operationError = error
		}
	}
	if let coordinationError { throw coordinationError }
	if let operationError { throw operationError }
}

#endif
