#if !os(watchOS) && !os(tvOS) && canImport(UIKit)
import Foundation
import UniformTypeIdentifiers
import UIKit
#if canImport(PencilKit)
import PencilKit
#endif

public extension UTType {
    /// Generic package type used by SBJImageDocument internally.
    /// Host applications own and declare any concrete exported UTI.
    static let sbjImageDocument: UTType = .package
}

public struct PhotoMarkupCanvasSize: Sendable, Equatable, Codable {
    public var width: Double
    public var height: Double

    public init(width: Double, height: Double) {
        self.width = width
        self.height = height
    }

    public init(_ size: CGSize) {
        self.init(width: size.width, height: size.height)
    }

    public var cgSize: CGSize { .init(width: width, height: height) }
}

public enum PhotoMarkupCoordinateSpace: String, Sendable, Codable {
    /// Markup coordinates describe the visible composition/crop frame, not source pixels.
    case composition
}

/// Format-neutral serialized markup. PencilKit is one supported encoding, not part of the container contract.
public struct PhotoMarkup: Sendable, Equatable, Codable {
    public var data: Data
    public var contentTypeIdentifier: String
    public var canvasSize: PhotoMarkupCanvasSize
    public var coordinateSpace: PhotoMarkupCoordinateSpace

    public init(
        data: Data,
        contentType: UTType,
        canvasSize: PhotoMarkupCanvasSize,
        coordinateSpace: PhotoMarkupCoordinateSpace = .composition
    ) {
        self.init(
            data: data,
            contentTypeIdentifier: contentType.identifier,
            canvasSize: canvasSize,
            coordinateSpace: coordinateSpace
        )
    }

    /// Creates markup without requiring its content type to be registered with
    /// Launch Services. Image-document packages must be able to round-trip
    /// private or otherwise unknown markup encodings by identifier alone.
    public init(
        data: Data,
        contentTypeIdentifier: String,
        canvasSize: PhotoMarkupCanvasSize,
        coordinateSpace: PhotoMarkupCoordinateSpace = .composition
    ) {
        self.data = data
        self.contentTypeIdentifier = contentTypeIdentifier
        self.canvasSize = canvasSize
        self.coordinateSpace = coordinateSpace
    }

    public var contentType: UTType? { UTType(contentTypeIdentifier) }
}

#if canImport(PencilKit)
public extension PhotoMarkup {
    static var pencilKitContentType: UTType {
        UTType(exportedAs: "com.softwarebyjove.pencilkit-drawing")
    }

    init(
        drawing: PKDrawing,
        canvasSize: CGSize,
        coordinateSpace: PhotoMarkupCoordinateSpace = .composition
    ) {
        self.init(
            data: drawing.dataRepresentation(),
            contentType: Self.pencilKitContentType,
            canvasSize: .init(canvasSize),
            coordinateSpace: coordinateSpace
        )
    }

    var pencilKitDrawing: PKDrawing? { try? PKDrawing(data: data) }
}
#endif

/// Current non-destructive edit state. This is deliberately not an edit history.
public struct PhotoEditResult: Sendable, Equatable, Codable {
    public var geometry: PhotoEditGeometry
    public var color: PhotoColorAdjustments
    public var markup: PhotoMarkup?

    public init(
        geometry: PhotoEditGeometry,
        color: PhotoColorAdjustments = .init(),
        markup: PhotoMarkup? = nil
    ) {
        self.geometry = geometry
        self.color = color
        self.markup = markup
    }
}

/// A self-contained non-destructive image package.
///
/// The encoded source and edit recipe are authoritative. A small flattened thumbnail is
/// persisted as a disposable cache for thumbnail providers. Full-size rendering is performed
/// on demand (for example, by Quick Look). The source image is only the fallback when the
/// requested derivative cannot be produced.
public struct SBJImageDocument: Sendable, Equatable {
    public static let packageExtension = "sbjimage"

    private static let thumbnailMaximumPixelDimension: CGFloat = 512

    public enum ThumbnailBehavior: String, Sendable, Equatable, Codable {
        /// Persist a small rendered derivative of the edited image.
        case generated

        /// Do not persist a thumbnail in the package.
        case none
    }

    private var source: SBJResourceContent
    private var edits: PhotoEditResult
    private var thumbnailBehavior: ThumbnailBehavior
    private var thumbnail: SBJResourceContent?

    /// Creates a document from an immutable encoded source image.
    ///
    /// Pass `thumbnail: .none` when the host application wants its thumbnail
    /// provider to supply application-specific fallback artwork instead.
    public init(
        source: SBJResourceContent,
        thumbnail: ThumbnailBehavior = .generated
    ) {
        self.source = source
        let size = source.uiImage?.size ?? .init(width: 1, height: 1)
        self.edits = .init(geometry: .init(crop: .init(option: .none, sourceSize: size)))
        self.thumbnailBehavior = thumbnail
        self.thumbnail = thumbnail == .generated ? makeThumbnail(options: .default) : nil
    }

    /// Opens an image-document package from disk.
    public init(fileURL: URL) throws {
        self = try fileURL.withSecurityScopedAccess {
            try Self(fileWrapper: FileWrapper(url: $0, options: []))
        }
    }

    /// Fast disk path for thumbnail providers. Returns the thumbnail component
    /// already stored in the package, or `nil` when the document has no thumbnail.
    /// No source-image fallback or rendering is performed here; the host thumbnail
    /// provider owns its fallback behavior.
    public static func thumbnailURL(in fileURL: URL) -> URL? {
        fileURL.withSecurityScopedAccess { packageURL in
            guard let manifest = try? manifest(at: packageURL),
                  let descriptor = manifest.thumbnail,
                  let url = componentURL(in: packageURL, path: descriptor.path),
                  FileManager.default.fileExists(atPath: url.path) else {
                return nil
            }
            return url
        }
    }

    /// Convenience for UI consumers that need the persisted thumbnail as an image.
    /// Like `thumbnailURL(in:)`, this does not render or fall back to the source.
    public static func thumbnailImage(at fileURL: URL) -> UIImage? {
        guard let url = thumbnailURL(in: fileURL),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: data)
    }

    /// Disk convenience for full preview/Quick Look consumers. This intentionally performs
    /// the full render rather than resolving the persisted thumbnail cache.
    public static func renderedImage(
        at fileURL: URL,
        options: PhotoEditorOptions = .default
    ) -> UIImage? {
        fileURL.withSecurityScopedAccess { packageURL in
            guard let document = try? SBJImageDocument(
                fileWrapper: FileWrapper(url: packageURL, options: [])
            ) else {
                return nil
            }
            return document.renderedImage(options: options)
        }
    }

    /// Opens a serialized image-document package.
    public init(serializedRepresentation data: Data) throws {
        guard let wrapper = FileWrapper(serializedRepresentation: data) else {
            throw Error.invalidPackage
        }
        try self.init(fileWrapper: wrapper)
    }

    public enum Error: Swift.Error {
        case invalidPackage
        case missingSource
        case invalidComponent
    }

    private struct Manifest: Codable {
        struct Component: Codable {
            var path: String
            var contentType: String
        }

        struct Markup: Codable {
            var path: String
            var contentType: String
            var canvasSize: PhotoMarkupCanvasSize
            var coordinateSpace: PhotoMarkupCoordinateSpace
        }

        var format: String
        var source: Component
        var geometry: Component
        var color: Component
        var markup: Markup?

        var thumbnailBehavior: ThumbnailBehavior
        var thumbnail: Component?
    }

    private init(
        source: SBJResourceContent,
        edits: PhotoEditResult,
        thumbnailBehavior: ThumbnailBehavior,
        thumbnail: SBJResourceContent?
    ) {
        self.source = source
        self.edits = edits
        self.thumbnailBehavior = thumbnailBehavior
        self.thumbnail = thumbnail
    }


    private static func manifest(at packageURL: URL) throws -> Manifest {
        let data = try Data(contentsOf: packageURL.appendingPathComponent("manifest.json"))
        let manifest = try JSONDecoder().decode(Manifest.self, from: data)
        guard manifest.format == UTType.sbjImageDocument.identifier else {
            throw Error.invalidPackage
        }
        return manifest
    }

    private static func componentURL(in packageURL: URL, path: String) -> URL? {
        let components = path.split(separator: "/", omittingEmptySubsequences: true)
        guard !components.isEmpty,
              !path.hasPrefix("/"),
              components.allSatisfy({ $0 != "." && $0 != ".." }) else {
            return nil
        }
        return components.reduce(packageURL) { url, component in
            url.appendingPathComponent(String(component), isDirectory: false)
        }
    }

    private init(fileWrapper: FileWrapper) throws {
        guard fileWrapper.isDirectory,
              let root = fileWrapper.fileWrappers,
              let manifestData = root["manifest.json"]?.regularFileContents else {
            throw Error.invalidPackage
        }

        let manifest = try JSONDecoder().decode(Manifest.self, from: manifestData)
        guard manifest.format == UTType.sbjImageDocument.identifier else {
            throw Error.invalidPackage
        }

        func data(at path: String) -> Data? {
            var current = fileWrapper
            for part in path.split(separator: "/") {
                guard current.isDirectory,
                      let next = current.fileWrappers?[String(part)] else {
                    return nil
                }
                current = next
            }
            return current.regularFileContents
        }

        guard let sourceData = data(at: manifest.source.path),
              let sourceType = UTType(manifest.source.contentType) else {
            throw Error.missingSource
        }
        guard let geometryData = data(at: manifest.geometry.path),
              let colorData = data(at: manifest.color.path) else {
            throw Error.invalidComponent
        }

        let source = SBJResourceContent(data: sourceData, contentType: sourceType)
        let geometry = try JSONDecoder().decode(PhotoEditGeometry.self, from: geometryData)
        let color = try JSONDecoder().decode(PhotoColorAdjustments.self, from: colorData)

        let markup: PhotoMarkup?
        if let descriptor = manifest.markup,
           let markupData = data(at: descriptor.path) {
            markup = .init(
                data: markupData,
                contentTypeIdentifier: descriptor.contentType,
                canvasSize: descriptor.canvasSize,
                coordinateSpace: descriptor.coordinateSpace
            )
        } else {
            markup = nil
        }

        let thumbnail: SBJResourceContent?
        if let descriptor = manifest.thumbnail,
           let thumbnailData = data(at: descriptor.path),
           let thumbnailType = UTType(descriptor.contentType) {
            thumbnail = .init(data: thumbnailData, contentType: thumbnailType)
        } else {
            thumbnail = nil
        }

        self.init(
            source: source,
            edits: .init(geometry: geometry, color: color, markup: markup),
            thumbnailBehavior: manifest.thumbnailBehavior,
            thumbnail: thumbnail
        )
    }

    /// Small persisted representation intended for document browsers and thumbnail providers.
    /// This is only the stored thumbnail component; it does not fall back to the source.
    public var thumbnailImage: UIImage? {
        thumbnail?.uiImage
    }

    /// Performs a full render of the current edit recipe for Quick Look/export-style consumers.
    /// The immutable source is used only when rendering fails.
    public func renderedImage(options: PhotoEditorOptions = .default) -> UIImage? {
        renderedContent(options: options)?.uiImage ?? source.uiImage
    }

    /// Serializes the complete package, including the persisted thumbnail cache.
    public var serializedRepresentation: Data {
        get throws {
            guard let data = try makeFileWrapper().serializedRepresentation else {
                throw Error.invalidPackage
            }
            return data
        }
    }

    /// Writes the complete package atomically.
    public func write(to url: URL) throws {
        try makeFileWrapper().write(to: url, options: .atomic, originalContentsURL: nil)
    }

    /// Encodes this document as an SBJ resource for embedding in another package.
    public var resourceContent: SBJResourceContent? {
        guard let data = try? serializedRepresentation else { return nil }
        return .init(data: data, contentType: .sbjImageDocument)
    }

    // MARK: - Editor integration

    /// Internal editor input. Keeping the stored state private prevents clients from
    /// coordinating source/edit/thumbnail mutations themselves.
    var editorInput: (source: SBJResourceContent, edits: PhotoEditResult) {
        (source, edits)
    }

    /// Applies an edit result atomically and rebuilds the persisted thumbnail in the same call.
    func applying(
        _ edits: PhotoEditResult,
        options: PhotoEditorOptions = .default
    ) -> Self {
        var copy = self
        copy.edits = edits
        if copy.thumbnailBehavior == .generated {
            copy.thumbnail = copy.makeThumbnail(options: options)
        }
        return copy
    }

    // MARK: - Rendering

    /// Renders the supported current state. Reserved perspective/skew state is not yet applied.
    private func renderedContent(options: PhotoEditorOptions) -> SBJResourceContent? {
#if canImport(PencilKit)
        let drawing: Any? = edits.markup?.pencilKitDrawing
#else
        let drawing: Any? = nil
#endif
        return PhotoEditRenderer.render(
            resource: source,
            geometry: edits.geometry,
            options: options,
            markup: drawing,
            markupCanvasSize: edits.markup?.canvasSize.cgSize ?? .zero
        )
    }

    private func makeThumbnail(options: PhotoEditorOptions) -> SBJResourceContent? {
#if canImport(PencilKit)
        let drawing: Any? = edits.markup?.pencilKitDrawing
#else
        let drawing: Any? = nil
#endif
        return PhotoEditRenderer.render(
            resource: source,
            geometry: edits.geometry,
            options: options,
            markup: drawing,
            markupCanvasSize: edits.markup?.canvasSize.cgSize ?? .zero,
            maximumPixelDimension: Self.thumbnailMaximumPixelDimension,
            encoding: .thumbnail
        )
    }

    // MARK: - Package persistence

    private func thumbnailForPersistence() -> SBJResourceContent? {
        guard thumbnailBehavior == .generated else { return nil }

        if let thumbnail,
           let image = thumbnail.uiImage,
           max(image.size.width, image.size.height) <= Self.thumbnailMaximumPixelDimension {
            return thumbnail
        }
        return makeThumbnail(options: .default)
    }

    private func makeFileWrapper() throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

        let sourceExtension = source.contentType.preferredFilenameExtension ?? "data"
        let sourcePath = "source/original.\(sourceExtension)"
        let geometryPath = "edits/geometry.json"
        let colorPath = "edits/color.json"
        let markupPath = edits.markup.map { _ in "edits/markup.data" }
        let persistedThumbnail = thumbnailForPersistence()
        let thumbnailPath = persistedThumbnail.map {
            "thumbnail/image.\($0.contentType.preferredFilenameExtension ?? "data")"
        }

        let manifest = Manifest(
            format: UTType.sbjImageDocument.identifier,
            source: .init(
                path: sourcePath,
                contentType: source.contentType.identifier
            ),
            geometry: .init(
                path: geometryPath,
                contentType: UTType.json.identifier
            ),
            color: .init(
                path: colorPath,
                contentType: UTType.json.identifier
            ),
            markup: edits.markup.map {
                .init(
                    path: markupPath!,
                    contentType: $0.contentTypeIdentifier,
                    canvasSize: $0.canvasSize,
                    coordinateSpace: $0.coordinateSpace
                )
            },
            thumbnailBehavior: thumbnailBehavior,
            thumbnail: persistedThumbnail.map {
                .init(
                    path: thumbnailPath!,
                    contentType: $0.contentType.identifier
                )
            }
        )

        var editChildren: [String: FileWrapper] = [
            "geometry.json": .init(regularFileWithContents: try encoder.encode(edits.geometry)),
            "color.json": .init(regularFileWithContents: try encoder.encode(edits.color))
        ]
        if let markup = edits.markup {
            editChildren["markup.data"] = .init(regularFileWithContents: markup.data)
        }

        var root: [String: FileWrapper] = [
            "manifest.json": .init(regularFileWithContents: try encoder.encode(manifest)),
            "source": .init(directoryWithFileWrappers: [
                "original.\(sourceExtension)": .init(regularFileWithContents: source.data)
            ]),
            "edits": .init(directoryWithFileWrappers: editChildren)
        ]

        if let persistedThumbnail, let thumbnailPath {
            root["thumbnail"] = .init(directoryWithFileWrappers: [
                URL(fileURLWithPath: thumbnailPath).lastPathComponent:
                    .init(regularFileWithContents: persistedThumbnail.data)
            ])
        }

        return .init(directoryWithFileWrappers: root)
    }
}

public extension SBJResourceContent {
    /// Returns this resource as a complete non-destructive image document.
    /// Existing SBJ image documents are returned unchanged. Ordinary encoded images are
    /// wrapped as the immutable source of a new document. Non-image resources return `nil`.
    var preservingImageEdits: SBJResourceContent? {
        if contentType == .sbjImageDocument { return self }
        guard contentType.conforms(to: .image) else { return nil }
        return SBJImageDocument(source: self).resourceContent
    }

    /// Filename extension used when persisting this resource as a file or package.
    var storageFilenameExtension: String {
        if contentType == .sbjImageDocument { return SBJImageDocument.packageExtension }
        return contentType.preferredFilenameExtension ?? "data"
    }

    /// Creates the appropriate file wrapper for this encoded resource. Package resources
    /// preserve their directory representation; ordinary resources are regular files.
    func storageFileWrapper() -> FileWrapper {
        if contentType.conforms(to: .package),
           let wrapper = FileWrapper(serializedRepresentation: data) {
            return wrapper
        }
        return FileWrapper(regularFileWithContents: data)
    }

    /// Resolves a stored resource's content type, including SBJ package types that need
    /// not be registered with Launch Services by the host application.
    static func storageContentType(forFilename filename: String, fallback: UTType? = nil) -> UTType {
        let ext = URL(fileURLWithPath: filename).pathExtension.lowercased()
        if ext == SBJImageDocument.packageExtension { return .sbjImageDocument }
        return fallback ?? UTType(filenameExtension: ext) ?? .data
    }

    /// Reconstitutes resource content from a regular-file or package wrapper.
    init?(
        storageFileWrapper wrapper: FileWrapper,
        filename: String,
        fallbackContentType: UTType? = nil
    ) {
        let type = Self.storageContentType(forFilename: filename, fallback: fallbackContentType)
        let storedData: Data?
        if wrapper.isDirectory, type.conforms(to: .package) {
            storedData = wrapper.serializedRepresentation
        } else {
            storedData = wrapper.regularFileContents
        }
        guard let storedData else { return nil }
        self.init(data: storedData, contentType: type)
    }
}

#endif
