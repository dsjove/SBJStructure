import Foundation

/// Owns access to a security-scoped URL for exactly this object's lifetime.
final class SecurityScopedResourceAccess {
	private let url: URL
	private let isAccessing: Bool

	init(_ url: URL) {
		self.url = url
		self.isAccessing = url.startAccessingSecurityScopedResource()
	}

	deinit {
		if isAccessing {
			url.stopAccessingSecurityScopedResource()
		}
	}
}

/// Reusable wrapper around coordinated file operations for documents that can
/// be changed by file providers, iCloud, or another process.
struct CoordinatedFileAccess: @unchecked Sendable {
	let fileManager: FileManager

	init(fileManager: FileManager = .default) {
		self.fileManager = fileManager
	}

	func read<T>(at url: URL, options: NSFileCoordinator.ReadingOptions = [], _ accessor: (URL) throws -> T) throws -> T {
		var coordinationError: NSError?
		var result: Result<T, Error>?
		NSFileCoordinator().coordinate(readingItemAt: url, options: options, error: &coordinationError) { coordinatedURL in
			result = Result { try accessor(coordinatedURL) }
		}
		if let coordinationError { throw coordinationError }
		guard let result else { throw CocoaError(.fileReadUnknown) }
		return try result.get()
	}

	/// Performs a coordinated read while holding security-scoped access to the
	/// supplied URL for the entire operation. This is appropriate for URLs
	/// returned by document pickers and other file-provider APIs.
	func readSecurityScoped<T>(
		at url: URL,
		options: NSFileCoordinator.ReadingOptions = [],
		_ accessor: (URL) throws -> T
	) throws -> T {
		let access = SecurityScopedResourceAccess(url)
		return try withExtendedLifetime(access) {
			try read(at: url, options: options, accessor)
		}
	}

	func removeItem(at url: URL) throws {
		guard fileManager.fileExists(atPath: url.path) else { return }
		var coordinationError: NSError?
		var operationError: Error?
		NSFileCoordinator().coordinate(writingItemAt: url, options: .forDeleting, error: &coordinationError) { coordinatedURL in
			do {
				if fileManager.fileExists(atPath: coordinatedURL.path) {
					try fileManager.removeItem(at: coordinatedURL)
				}
			} catch {
				operationError = error
			}
		}
		if let coordinationError { throw coordinationError }
		if let operationError { throw operationError }
	}
}
