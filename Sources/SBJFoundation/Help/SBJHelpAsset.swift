#if !os(watchOS)
import Foundation
import UIKit
import UniformTypeIdentifiers

/// A named help resource.
///
/// Help may live in an asset-catalog data set or as an ordinary bundle
/// resource. The latter is particularly useful for help shipped by Swift
/// packages such as SBJFoundation itself.
public struct SBJHelpAsset: Hashable {
    public enum Storage: Hashable {
        case dataAsset(folder: String)
        case bundleResource(name: String, extension: String?, subdirectory: String?)
    }

    public let title: String
    public let bundle: Bundle
    public let storage: Storage
    public let contentTypeOverride: UTType?

    /// Creates help stored in an asset-catalog data set.
    public init(
        title: String,
        folder: String = "help",
        bundle: Bundle = .main,
        contentType: UTType? = nil
    ) {
        self.title = title
        self.bundle = bundle
        self.storage = .dataAsset(folder: folder)
        self.contentTypeOverride = contentType
    }

    public init(
        title: String,
        folder: String = "help",
        bundle: Bundle = .main,
        filenameExtension: String
    ) {
        self.init(
            title: title,
            folder: folder,
            bundle: bundle,
            contentType: UTType(filenameExtension: filenameExtension)
        )
    }

    /// Creates help stored as a normal file resource in a bundle.
    public init(
        title: String,
        resourceName: String,
        resourceExtension: String? = nil,
        subdirectory: String? = nil,
        bundle: Bundle,
        contentType: UTType? = nil
    ) {
        self.title = title
        self.bundle = bundle
        self.storage = .bundleResource(
            name: resourceName,
            extension: resourceExtension,
            subdirectory: subdirectory
        )
        self.contentTypeOverride = contentType ?? resourceExtension.flatMap { UTType(filenameExtension: $0) }
    }

    /// Stable presentation/history identity independent of the resource URL.
    public var fullName: String {
        switch storage {
        case .dataAsset(let folder):
            let assetName = title.sanitizedFilename(removeSpaces: true)
            guard !folder.isEmpty else { return assetName }
            return folder + "/" + assetName
        case .bundleResource(let name, let ext, let subdirectory):
            let file = ext.map { "\(name).\($0)" } ?? name
            guard let subdirectory, !subdirectory.isEmpty else { return file }
            return subdirectory + "/" + file
        }
    }

    private var dataAsset: NSDataAsset? {
        guard case .dataAsset = storage else { return nil }
        return NSDataAsset(name: fullName, bundle: bundle)
    }

    private var resourceURL: URL? {
        guard case let .bundleResource(name, ext, subdirectory) = storage else { return nil }
        if let url = bundle.url(forResource: name, withExtension: ext, subdirectory: subdirectory) {
            return url
        }
        // Swift Package Manager may flatten processed resources in the generated
        // resource bundle. Falling back to the bundle root keeps authored folder
        // organization independent of the runtime bundle layout.
        guard subdirectory != nil else { return nil }
        return bundle.url(forResource: name, withExtension: ext)
    }

    public func dataValue() -> Data? {
        switch storage {
        case .dataAsset:
            return dataAsset?.data
        case .bundleResource:
            guard let resourceURL else { return nil }
            return try? Data(contentsOf: resourceURL)
        }
    }

    public func stringValue() -> String? {
        guard let data = dataValue() else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// The help representation reported by the storage container, unless the
    /// caller explicitly overrides it.
    public var contentType: UTType? {
        switch storage {
        case .dataAsset:
            return Self.resolvedContentType(
                override: contentTypeOverride,
                assetTypeIdentifier: dataAsset?.typeIdentifier
            )
        case .bundleResource(_, let ext, _):
            if let contentTypeOverride { return contentTypeOverride }
            return ext.flatMap { UTType(filenameExtension: $0) }
        }
    }

    public var exists: Bool {
        switch storage {
        case .dataAsset:
            return dataAsset != nil
        case .bundleResource:
            return resourceURL != nil
        }
    }

    static func resolvedContentType(
        override: UTType?,
        assetTypeIdentifier: String?
    ) -> UTType? {
        if let override { return override }
        guard let assetTypeIdentifier, !assetTypeIdentifier.isEmpty else { return nil }
        return UTType(assetTypeIdentifier)
    }
}

public extension SBJHelpAsset {
    /// Help for SBJFoundation's generated structure editor. Applications may
    /// present this directly or embed it in their own help through
    /// `SBJHelpConfiguration.embeddedAssets`.
    static var structureEditor: SBJHelpAsset {
        SBJHelpAsset(
            title: "Structure Editor",
            resourceName: "SBJStructureEditor",
            resourceExtension: "html",
            bundle: .module,
            contentType: .html
        )
    }
}
#endif
