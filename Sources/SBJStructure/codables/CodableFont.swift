import Foundation
import UIKit
import SwiftUI

public struct CodableFont: Codable, Comparable, Equatable, Hashable, Sendable, CustomDebugStringConvertible {
	public var name: String?
	public var size: Double
	public var bold: Bool
	public var italic: Bool

	public init(
		_ name: String? = nil,
		ofSize size: Double = 12.0,
		bold: Bool = false,
		italic: Bool = false
	) {
		self.name = name
		self.size = size
		self.bold = bold
		self.italic = italic
	}

	public static func < (lhs: CodableFont, rhs: CodableFont) -> Bool {
		switch (lhs.name, rhs.name) {
		case (nil, nil):
			break
		case (nil, _?):
			return true
		case (_?, nil):
			return false
		case let (lhsName?, rhsName?) where lhsName != rhsName:
			return lhsName.localizedStandardCompare(rhsName) == .orderedAscending
		default:
			break
		}

		if lhs.size != rhs.size { return lhs.size < rhs.size }
		if lhs.bold != rhs.bold { return !lhs.bold }
		if lhs.italic != rhs.italic { return !lhs.italic }
		return false
	}

	public var debugDescription: String {
		"\(name.map(\.debugDescription) ?? "System")\(size) B-\(bold) I-\(italic)"
	}

	public var font: UIFont {
		font(scale: 1.0)
	}

	public func font(scale: Double) -> UIFont {
		let scaledSize = size * scale
		let baseFont: UIFont
		if let name {
			baseFont = UIFont(name: name, size: scaledSize) ?? UIFont.systemFont(ofSize: scaledSize)
		} else {
			baseFont = UIFont.systemFont(ofSize: scaledSize)
		}

		var traits: UIFontDescriptor.SymbolicTraits = []
		if bold {
			traits.insert(.traitBold)
		}
		if italic {
			traits.insert(.traitItalic)
		}
		guard !traits.isEmpty, let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits)
		else {
			return baseFont
		}
		return UIFont(descriptor: descriptor, size: scaledSize)
	}
}
