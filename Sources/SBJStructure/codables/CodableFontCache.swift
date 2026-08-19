import Foundation
import UIKit

/// A process-wide cache for realizing ``CodableFont`` values as `UIFont` objects.
///
/// The cache is synchronous and thread-safe, so it can be used from the main actor,
/// detached tasks, or other actors without introducing an actor hop. Entries are
/// retained for the lifetime of the cache; eviction can be added later if needed.
public final class CodableFontCache: @unchecked Sendable {
	public static let shared = CodableFontCache()

	private struct Key: Hashable {
		let font: CodableFont
		let scale: CGFloat
	}

	private let lock = NSLock()
	private var fonts: [Key: UIFont] = [:]

	public init() {}

	/// Returns a cached `UIFont` for the supplied description and scale.
	/// A font is created only the first time a particular pair is requested.
	public func font(for font: CodableFont, scale: CGFloat = 1.0) -> UIFont {
		let key = Key(font: font, scale: scale)

		lock.lock()
		defer { lock.unlock() }

		if let cached = fonts[key] {
			return cached
		}

		let realized = font.font(scale: scale)
		fonts[key] = realized
		return realized
	}
}
