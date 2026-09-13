import Foundation

/// Generic discovery and deletion for an app-controlled directory of file packages.
///
/// Active package writes belong to `PackageSession`; this type intentionally has
/// no save API so there is a single owner for the lifecycle of an open package.
public struct PackageLibraryStore<ID: Hashable & Comparable & Sendable, State: Sendable>: @unchecked Sendable {
	public let directory: URL
	public let packageURL: @Sendable (ID) -> URL
	public let identifier: @Sendable (State) -> ID
	public let loadPackage: @Sendable (URL) throws -> State
	public let fileAccess: CoordinatedFileAccess
	public let fileManager: FileManager

	public init(
		directory: URL,
		packageURL: @escaping @Sendable (ID) -> URL,
		identifier: @escaping @Sendable (State) -> ID,
		loadPackage: @escaping @Sendable (URL) throws -> State,
		fileManager: FileManager = .default
	) {
		self.directory = directory
		self.packageURL = packageURL
		self.identifier = identifier
		self.loadPackage = loadPackage
		self.fileAccess = CoordinatedFileAccess(fileManager: fileManager)
		self.fileManager = fileManager
	}

	public func loadAll(excludingIDs: Set<ID> = []) throws -> [State] {
		try prepareDirectory()
		let excludedNames = Set(excludingIDs.map { packageURL($0).lastPathComponent })
		let entries = try fileAccess.read(at: directory) { directoryURL in
			try fileManager.contentsOfDirectory(
				at: directoryURL,
				includingPropertiesForKeys: [.isDirectoryKey],
				options: [.skipsHiddenFiles]
			)
		}

		var states: [State] = []
		for candidateURL in entries {
			guard !excludedNames.contains(candidateURL.lastPathComponent) else { continue }
			guard (try? candidateURL.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }
			guard let state = try? fileAccess.read(at: candidateURL, { try loadPackage($0) }) else { continue }
			let id = identifier(state)
			guard candidateURL.lastPathComponent == packageURL(id).lastPathComponent else { continue }
			states.append(state)
		}
		return states.sorted { identifier($0) < identifier($1) }
	}

	/// Loads a package supplied by a document picker or other external provider,
	/// holding security-scoped access for the complete coordinated read.
	public func loadExternalPackage(from url: URL) throws -> State {
		try fileAccess.readSecurityScoped(at: url) { try loadPackage($0) }
	}

	public func delete(id: ID) throws {
		try prepareDirectory()
		try fileAccess.removeItem(at: packageURL(id))
	}

	private func prepareDirectory() throws {
		try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
	}
}
