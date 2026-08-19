import Foundation
import UIKit
import SwiftUI

//TODO: asset color by name

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

	public init(color: Color.Resolved) {
		self = .init(
			Double(color.red),
			Double(color.green),
			Double(color.blue),
			Double(color.opacity))
	}
	
	public var swiftUIColor: Color {
		get {
			Color(red: red, green: green, blue: blue, opacity: opacity)
		}
	}

	public init(color: UIColor) {
		if let uiColor = color.cgColor.components, uiColor.count >= 3 {
			self.init(
				uiColor[0],
				uiColor[1],
				uiColor[2],
				uiColor.count > 3 ? uiColor[3] : 1.0
			)
		}
		else {
			self.init(0, 0, 0, 1.0)
		}
	}
}
