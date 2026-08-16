import Foundation

public struct CodableColor: Codable, Comparable, Equatable, CustomDebugStringConvertible {
	public var red: Double
	public var green: Double
	public var blue: Double
	public var opacity: Double

	public init(_ red: Double, _ green: Double, _ blue: Double, _ opacity: Double = 1.0) {
		self.red = red
		self.green = green
		self.blue = blue
		self.opacity = opacity
	}

	public init() {
		self.red = 1.0
		self.green = 1.0
		self.blue = 1.0
		self.opacity = 1.0
	}

	public static func < (lhs: CodableColor, rhs: CodableColor) -> Bool {
		if lhs.red != rhs.red { return lhs.red < rhs.red }
		if lhs.green != rhs.green { return lhs.green < rhs.green }
		if lhs.blue != rhs.blue { return lhs.blue < rhs.blue }
		return lhs.opacity < rhs.opacity
	}

	public var debugDescription: String {
		"(\(red), \(green), \(blue), \(opacity))"
	}
}
