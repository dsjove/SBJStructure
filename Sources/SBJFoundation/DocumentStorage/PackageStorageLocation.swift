import Foundation

/// Resolves an app-controlled package directory and maps stable document IDs to
/// collision-free package names.
///
/// The location prefers the app's ubiquitous Documents container when iCloud is
/// available, otherwise it falls back to the local Documents directory.
public struct PackageStorageLocation<ID: Sendable>: @unchecked Sendable {
	public let directoryName: String
	public let packageExtension: String
	public let ubiquityContainerIdentifier: String?
	public let fileManager: FileManager
	private let storageComponent: @Sendable (ID) -> String

	public init(
		directoryName: String,
		packageExtension: String,
		ubiquityContainerIdentifier: String? = nil,
		fileManager: FileManager = .default,
		storageComponent: @escaping @Sendable (ID) -> String
	) {
		self.directoryName = directoryName
		self.packageExtension = packageExtension
		self.ubiquityContainerIdentifier = ubiquityContainerIdentifier
		self.fileManager = fileManager
		self.storageComponent = storageComponent
	}

	public var localDirectory: URL {
		fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
			.appendingPathComponent(directoryName, isDirectory: true)
	}

	public var ubiquitousDirectory: URL? {
		fileManager.url(forUbiquityContainerIdentifier: ubiquityContainerIdentifier)?
			.appendingPathComponent("Documents", isDirectory: true)
			.appendingPathComponent(directoryName, isDirectory: true)
	}

	public var directory: URL {
		ubiquitousDirectory ?? localDirectory
	}

	public func storageIDComponent(for id: ID) -> String {
		storageComponent(id)
	}

	public func packageName(for id: ID) -> String {
		storageIDComponent(for: id) + "." + packageExtension
	}

	public func packageURL(for id: ID, root: URL? = nil) -> URL {
		(root ?? directory).appendingPathComponent(packageName(for: id), isDirectory: true)
	}
}

public extension PackageStorageLocation where ID == String {
	/// Creates a package location for string document IDs using a URL-safe Base64
	/// filesystem representation. User-facing names should remain separate from
	/// this stable storage identity.
	init(
		directoryName: String,
		packageExtension: String,
		ubiquityContainerIdentifier: String? = nil,
		fileManager: FileManager = .default
	) {
		self.init(
			directoryName: directoryName,
			packageExtension: packageExtension,
			ubiquityContainerIdentifier: ubiquityContainerIdentifier,
			fileManager: fileManager,
			storageComponent: Self.urlSafeStorageComponent
		)
	}

	private static func urlSafeStorageComponent(_ id: String) -> String {
		let encoded = Data(id.utf8).base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
		return "id-\(encoded.isEmpty ? "empty" : encoded)"
	}
}
