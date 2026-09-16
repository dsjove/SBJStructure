import SwiftUI

extension CGSize {
	static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
		CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
	}
	static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
		CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
	}
	static func * (lhs: CGSize, rhs: CGFloat) -> CGSize {
		CGSize(width: lhs.width * rhs, height: lhs.height * rhs)
	}
	static func / (lhs: CGSize, rhs: CGFloat) -> CGSize {
		CGSize(width: lhs.width / rhs, height: lhs.height / rhs)
	}
	var magnitude: CGFloat {
		sqrt(width * width + height * height)
	}
}

extension CGPoint {
	static func + (lhs: CGPoint, rhs: CGSize) -> CGPoint {
		CGPoint(x: lhs.x + rhs.width, y: lhs.y + rhs.height)
	}
	static func - (lhs: CGPoint, rhs: CGSize) -> CGPoint {
		CGPoint(x: lhs.x - rhs.width, y: lhs.y - rhs.height)
	}
	static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
	}
	static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
		CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
	}
}
