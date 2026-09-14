import Foundation
import UniformTypeIdentifiers

/// A concrete attachment presentation independent of attachment storage.
///
/// URL-backed attachments keep their existing URL. Embedded attachments
/// are materialized to a temporary file because Quick Look, sharing, and
/// OS opening operate on file URLs.
public struct URLAttachment: Identifiable, Sendable {
	public let id: UUID
	public let url: URL
	public let displayName: String

	public init(
		id: UUID = UUID(),
		url: URL,
		displayName: String? = nil
	) {
		self.id = id
		self.url = url
		self.displayName = displayName ?? url.lastPathComponent
	}

	public init(
		id: UUID = UUID(),
		content: SBJResourceContent,
		filename: String,
		displayName: String? = nil
	) throws {
		self.id = id
		self.url = try Self.materialize(content: content, filename: filename)
		self.displayName = displayName ?? filename
	}

	private static func materialize(content: SBJResourceContent, filename: String) throws -> URL {
		let directory = FileManager.default.temporaryDirectory
			.appendingPathComponent("URLAttachment", isDirectory: true)
			.appendingPathComponent(UUID().uuidString, isDirectory: true)
		try FileManager.default.createDirectory(
			at: directory,
			withIntermediateDirectories: true
		)

		let sanitized = filename.sanitizedFilename()
		var safeFilename = sanitized.isEmpty ? "Attachment" : sanitized
		if URL(fileURLWithPath: safeFilename).pathExtension.isEmpty,
		   let ext = content.contentType.preferredFilenameExtension {
			safeFilename += ".\(ext)"
		}
		let url = directory.appendingPathComponent(safeFilename)
		if content.contentType.conforms(to: .package),
		   let wrapper = FileWrapper(serializedRepresentation: content.data) {
			try wrapper.write(to: url, options: .atomic, originalContentsURL: nil)
		} else {
			try content.data.write(to: url, options: .atomic)
		}
		return url
	}
}
