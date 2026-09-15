import Foundation

/// A named encoded image resource that can be passed to image destinations
/// without losing its content type or filename.
public protocol PhotoImport: Sendable {
	var resourceContent: SBJResourceContent { get }
	var filename: String { get }
}
