#if !os(watchOS)
import Foundation
import Observation

public enum PackageExternalConflictKind: Equatable, Sendable {
	case modified
	case moved
	case deleted
}

public struct PackageExternalConflict<ID: Hashable & Sendable>: Equatable, Sendable where ID: Equatable {
	let id: ID
	public let documentName: String
	public let kind: PackageExternalConflictKind

	init(id: ID, documentName: String, kind: PackageExternalConflictKind) {
		self.id = id
		self.documentName = documentName
		self.kind = kind
	}
}

public enum PackageExternalConflictResolution: Sendable {
	case keepMyChanges
	case useExternalVersion
}

public enum PackageImportConflictResolution: Equatable, Sendable {
	case replaceExisting
	case importAsCopy
}

enum PackageDocumentLibraryError: LocalizedError, Sendable {
	case documentNotFound(String)

	var errorDescription: String? {
		switch self {
		case .documentNotFound(let id): return "Document not found: \(id)"
		}
	}
}

public struct PackageImportConflict<ID: Hashable & Sendable>: Equatable, Sendable where ID: Equatable {
	let id: ID
	public let existingName: String
	public let existingModifiedAt: Date
	public let incomingName: String
	public let incomingModifiedAt: Date

	init(
		id: ID,
		existingName: String,
		existingModifiedAt: Date,
		incomingName: String,
		incomingModifiedAt: Date
	) {
		self.id = id
		self.existingName = existingName
		self.existingModifiedAt = existingModifiedAt
		self.incomingName = incomingName
		self.incomingModifiedAt = incomingModifiedAt
	}
}

/// Reusable catalog + active-package lifecycle for app-controlled package documents.
///
/// Platform differences are entirely below this type: `PackageSession` uses
/// `UIDocument` where available and the tvOS presenter backend on Apple TV.
@Observable
@MainActor
public final class PackageDocumentLibrary<Document: PackageDocument> {
	typealias Snapshot = Document.Snapshot
	typealias ID = Snapshot.ID
	typealias Session = PackageSession<Document>

	public private(set) var availableDocuments: [Document]
	public private(set) var contentRevision = 0
	private(set) var externalConflicts: [ID: PackageExternalConflict<ID>] = [:]
	public private(set) var importConflict: PackageImportConflict<Document.Snapshot.ID>?

	private let location: PackageStorageLocation<ID>
	private let rootDirectory: URL
	private let catalog: PackageLibraryStore<ID, Snapshot>
	private var liveDocuments: [ID: Document] = [:]
	private var sessions: [ID: Session] = [:]
	private var saveErrorHandlers: [ID: @MainActor @Sendable (Error) -> Void] = [:]
	private var libraryMonitor: UbiquitousDirectoryMonitor?
	private var pendingImport: Snapshot?

	public convenience init(
		builtInDocuments: [Document] = [],
		fileManager: FileManager = .default
	) {
		self.init(builtInDocuments: builtInDocuments, fileManager: fileManager, rootDirectory: nil)
	}

	init(
		builtInDocuments: [Document] = [],
		fileManager: FileManager = .default,
		rootDirectory: URL?
	) {
		let location = Document.storageLocation(fileManager: fileManager)
		let resolvedRoot = rootDirectory ?? location.directory
		self.location = location
		self.rootDirectory = resolvedRoot
		self.catalog = PackageLibraryStore(
			directory: resolvedRoot,
			packageURL: { id in location.packageURL(for: id, root: resolvedRoot) },
			identifier: { $0.id },
			loadPackage: { url in
				let wrapper = try FileWrapper(url: url, options: .immediate)
				return try Document.snapshot(from: wrapper)
			},
			fileManager: location.fileManager
		)
		self.availableDocuments = builtInDocuments.sorted { lhs, rhs in
			lhs < rhs
		}
		for document in builtInDocuments { liveDocuments[document.id] = document }
	}

	public func load() async throws {
		let catalog = self.catalog
		let openIDs = Set(sessions.keys)
		let snapshots = try await Task.detached(priority: .utility) {
			try catalog.loadAll(excludingIDs: openIDs)
		}.value
		for snapshot in snapshots {
			let id = snapshot.id
			guard sessions[id] == nil else { continue }
			do { try await openPersistedPackage(snapshot) }
			catch { /* keep the rest of the catalog if one provider item is transiently unavailable */ }
		}
		rebuildAvailableDocuments()
		startLibraryMonitorIfNeeded()
	}

	/// Loads a package supplied by a document picker or other external provider.
	func loadExternalSnapshot(from url: URL) async throws -> Snapshot {
		let catalog = self.catalog
		return try await Task.detached(priority: .userInitiated) {
			try catalog.loadExternalPackage(from: url)
		}.value
	}

	public func open(_ document: Document) -> Document {
		liveDocuments[document.id] ?? document
	}

	public func open(id: Document.Snapshot.ID) -> Document? {
		liveDocuments[id]
	}

	public func open(url: URL) async throws -> Document? {
		if url.isFileURL { return try await importDocument(.success(url)) }
		guard let id = Document.documentID(from: url) else { return nil }
		if let document = open(id: id) { return document }
		try await load()
		guard let document = open(id: id) else {
			throw PackageDocumentLibraryError.documentNotFound(String(describing: id))
		}
		return document
	}

	public func url(for document: Document) -> URL? {
		Document.url(forDocumentID: document.id)
	}

	public func createDocument() async throws -> Document {
		try await createPersisted(Document.makeNewDocument())
	}

	public func duplicate(_ source: Document, named name: String) async throws -> Document? {
		let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedName.isEmpty else { return nil }
		return try await createPersisted(Document.makeDuplicate(of: source, named: trimmedName))
	}

	public func importDocument(_ result: Result<URL, Error>) async throws -> Document? {
		let sourceURL = try result.get()
		try Document.validateImportURL(sourceURL)
		let loaded = try await loadExternalSnapshot(from: sourceURL)
		let prepared = Document.prepareImport(loaded)
		if let existing = availableDocuments.first(where: { $0.id == prepared.id }) {
			let incoming = Document(restoring: prepared)
			pendingImport = prepared
			importConflict = .init(
				id: prepared.id,
				existingName: existing.name,
				existingModifiedAt: existing.modifiedAt,
				incomingName: incoming.name,
				incomingModifiedAt: incoming.modifiedAt
			)
			return nil
		}
		return try await adoptPersisted(Document.finalizedImport(prepared, asCopy: false))
	}

	public func resolveImportConflict(_ resolution: PackageImportConflictResolution) async throws -> Document? {
		guard let prepared = pendingImport else { return nil }
		pendingImport = nil
		importConflict = nil
		return try await adoptPersisted(
			Document.finalizedImport(prepared, asCopy: resolution == .importAsCopy)
		)
	}

	public func cancelImportConflict() {
		pendingImport = nil
		importConflict = nil
	}

	func createPersisted(_ document: Document) async throws -> Document {
		try prepareRootDirectory()
		let id = document.id
		let session = makeSession(id: id, initial: document.snapshot)
		liveDocuments[id] = document
		sessions[id] = session
		do {
			try await session.createSession()
			upsert(document)
			return document
		} catch {
			sessions[id] = nil
			liveDocuments[id] = nil
			throw error
		}
	}

	public func delete(_ document: Document) async throws {
		guard document.role == .user else { return }
		let id = document.id
		if let session = sessions[id] {
			session.discardUnsavedChanges()
			await session.closeSession()
		}
		let catalog = self.catalog
		try await Task.detached(priority: .userInitiated) { try catalog.delete(id: id) }.value
		removeFromCatalog(id: id)
	}

	public func documentDidChange(_ document: Document, onSaveError: @escaping @MainActor @Sendable (Error) -> Void) {
		guard document.role == .user, let session = sessions[document.id] else { return }
		document.markModified()
		let id = document.id
		saveErrorHandlers[id] = onSaveError
		session.replaceState(document.snapshot)
		upsert(document)
	}

	/// Installs an already-prepared persisted snapshot. If the stable ID is open,
	/// the existing canonical live object is retained and restored in place.
	@discardableResult
	func adoptPersisted(_ snapshot: Snapshot) async throws -> Document {
		let id = snapshot.id
		if let existing = liveDocuments[id], let session = sessions[id] {
			session.replaceState(snapshot)
			try await session.saveNow()
			existing.restore(from: snapshot)
			upsert(existing)
			return existing
		}
		return try await createPersisted(Document(restoring: snapshot))
	}

	public func packageURL(for document: Document) -> URL? {
		guard document.role == .user else { return nil }
		return location.packageURL(for: document.id, root: rootDirectory)
	}

	public func exportPackage(_ document: Document) async throws -> URL {
		let snapshot = Document.snapshotForExport(document.snapshot)
		let writer = ExportArtifactWriter(directoryName: "DocumentExports", fileManager: location.fileManager)
		let packageExtension = location.packageExtension
		let preferredName = document.name.sanitizedFilename(removeSpaces: false)
		let name = preferredName.hasContent ? preferredName : "Document"
		return try await Task.detached(priority: .userInitiated) {
			let wrapper = try Document.fileWrapper(for: snapshot)
			return try writer.write(wrapper, named: name, extension: packageExtension)
		}.value
	}

	public func externalConflict(for id: Document.Snapshot.ID) -> PackageExternalConflict<Document.Snapshot.ID>? {
		externalConflicts[id]
	}

	@discardableResult
	public func resolveExternalConflict(
		id: Document.Snapshot.ID,
		resolution: PackageExternalConflictResolution
	) async throws -> Bool {
		guard let conflict = externalConflicts[id],
			let document = liveDocuments[id],
			let session = sessions[id]
		else { return liveDocuments[id] != nil }

		switch (conflict.kind, resolution) {
		case (.modified, .keepMyChanges):
			session.replaceState(document.snapshot)
			try await session.resolveContentConflict(keepingCurrent: true)
		case (.modified, .useExternalVersion):
			try await session.resolveContentConflict(keepingCurrent: false)
		case (.moved, .keepMyChanges), (.deleted, .keepMyChanges):
			session.discardUnsavedChanges()
			await session.closeSession()
			sessions[id] = nil
			try await recreateCanonicalPackage(for: document)
		case (.moved, .useExternalVersion), (.deleted, .useExternalVersion):
			session.discardUnsavedChanges()
			await session.closeSession()
			removeFromCatalog(id: id)
			return false
		}
		externalConflicts[id] = nil
		didChange()
		return true
	}

	private func openPersistedPackage(_ snapshot: Snapshot) async throws {
		let id = snapshot.id
		let document = Document(restoring: snapshot)
		let session = makeSession(id: id, initial: snapshot)
		liveDocuments[id] = document
		sessions[id] = session
		do {
			try await session.openSession()
			document.restore(from: session.state)
			upsert(document)
		} catch {
			sessions[id] = nil
			liveDocuments[id] = nil
			throw error
		}
	}

	private func makeSession(id: ID, initial: Snapshot) -> Session {
		Session(
			fileURL: location.packageURL(for: id, root: rootDirectory),
			state: initial
		) { [weak self] event in
			await self?.handleSessionEvent(id: id, event: event)
		}
	}

	private func handleSessionEvent(id: ID, event: PackageSessionEvent<Snapshot>) async {
		switch event {
		case .loaded(let snapshot):
			guard snapshot.id == id, let document = liveDocuments[id] else { return }
			document.restore(from: snapshot)
			upsert(document)
		case .conflict:
			guard let document = liveDocuments[id] else { return }
			externalConflicts[id] = .init(
				id: id,
				documentName: document.name,
				kind: .modified
			)
			didChange()
		case .moved:
			await handleExternalRemoval(id: id, kind: .moved)
		case .deleted:
			await handleExternalRemoval(id: id, kind: .deleted)
		case .error(let error):
			saveErrorHandlers[id]?(error)
		}
	}

	private func handleExternalRemoval(id: ID, kind: PackageExternalConflictKind) async {
		guard let session = sessions[id], let document = liveDocuments[id] else { return }
		if session.hasUnsavedChanges {
			externalConflicts[id] = .init(
				id: id,
				documentName: document.name,
				kind: kind
			)
			didChange()
			return
		}

		await session.closeSession()
		removeFromCatalog(id: id)
	}

	private func recreateCanonicalPackage(for document: Document) async throws {
		try prepareRootDirectory()
		let id = document.id
		let session = makeSession(id: id, initial: document.snapshot)
		sessions[id] = session
		try await session.createSession()
		upsert(document)
	}

	private func prepareRootDirectory() throws {
		try location.fileManager.createDirectory(
			at: rootDirectory,
			withIntermediateDirectories: true
		)
	}

	private func startLibraryMonitorIfNeeded() {
		guard libraryMonitor == nil else { return }
		libraryMonitor = UbiquitousDirectoryMonitor(directoryURL: { [rootDirectory] in rootDirectory }) { [weak self] in
			guard let self else { return }
			Task { @MainActor in try? await self.load() }
		}
	}

	private func rebuildAvailableDocuments() {
		availableDocuments = Array(liveDocuments.values).sorted { lhs, rhs in
			lhs < rhs
		}
		didChange()
	}

	private func upsert(_ document: Document) {
		let id = document.id
		liveDocuments[id] = document
		availableDocuments.removeAll { $0.id == id }
		availableDocuments.append(document)
		availableDocuments.sort { lhs, rhs in
			lhs < rhs
		}
		didChange()
	}

	private func removeFromCatalog(id: ID) {
		sessions[id] = nil
		liveDocuments[id] = nil
		saveErrorHandlers[id] = nil
		externalConflicts[id] = nil
		availableDocuments.removeAll { $0.id == id }
		didChange()
	}

	private func didChange() {
		contentRevision &+= 1
	}
}

#endif
