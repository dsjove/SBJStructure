#if !os(watchOS)
import Foundation

public enum DocumentRole: Int, Comparable, Sendable, Codable {
	case user
	case builtIn
	case debug

	public static func < (lhs: Self, rhs: Self) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// URL identity contract for documents that support app/deep-link URLs.
public protocol DocumentURLRouting {
	associatedtype DocumentID: Hashable & Comparable & Sendable

	static func documentID(from url: URL) -> DocumentID?
	static func url(forDocumentID id: DocumentID) -> URL?
}

public extension DocumentURLRouting {
	static func documentID(from url: URL) -> DocumentID? { nil }
	static func url(forDocumentID id: DocumentID) -> URL? { nil }
}

/// Immutable package state used by a `PackageDocument`.
public protocol PackageDocumentSnapshot: Sendable {
	associatedtype ID: Hashable & Comparable & Sendable
	var id: ID { get }
}

/// Domain contract for a live document managed by `PackageDocumentLibrary`.
///
/// The conforming document owns model semantics and package-format policy.
/// The library owns discovery, canonical identity, sessions, saving, imports,
/// external-change handling, URL opening, package export, and platform differences.
public protocol PackageDocument: AnyObject, Comparable, SendableMetatype, DocumentURLRouting
where DocumentID == Snapshot.ID {
	associatedtype Snapshot: PackageDocumentSnapshot

	var id: Snapshot.ID { get }
	var name: String { get }
	var role: DocumentRole { get }
	var snapshot: Snapshot { get }
	var modifiedAt: Date { get }

	init(restoring snapshot: Snapshot)
	func restore(from snapshot: Snapshot)
	func markModified(at date: Date)

	static func makeNewDocument() -> Self
	static func makeDuplicate(of source: Self, named name: String) -> Self

	static func storageLocation(fileManager: FileManager) -> PackageStorageLocation<Snapshot.ID>
	static func validateImportURL(_ url: URL) throws
	static func prepareImport(_ snapshot: Snapshot) -> Snapshot
	static func finalizedImport(_ snapshot: Snapshot, asCopy: Bool) -> Snapshot
	static func snapshotForExport(_ snapshot: Snapshot) -> Snapshot

	static func fileWrapper(for snapshot: Snapshot) throws -> FileWrapper
	static func snapshot(from wrapper: FileWrapper) throws -> Snapshot
}

public extension PackageDocument {
	var role: DocumentRole { .user }

	func markModified() { markModified(at: .now) }

	static func snapshotForExport(_ snapshot: Snapshot) -> Snapshot { snapshot }
}
#endif
