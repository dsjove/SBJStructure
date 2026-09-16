import Foundation

public struct GeometricMirror: Equatable {
	public var horizontalOnly: Bool
	public let horizontalInit: Bool
	public let verticalInit: Bool
	public var horizontal: Bool
	public var vertical: Bool

	public init(horizontalOnly: Bool = false, horizontal: Bool = false, vertical: Bool = false) {
		self.horizontalOnly = horizontalOnly
		self.horizontalInit = horizontal
		self.horizontal = horizontal
		self.verticalInit = vertical
		self.vertical = vertical
	}

	public mutating func reset() {
		horizontal = horizontalInit
		vertical = verticalInit
	}

	public var hasEdits: Bool { horizontal || vertical }

	public var idx: Int {
		horizontal ? vertical ? 2 : 1 : vertical ? 3 : 0
	}

	public var next: GeometricMirror {
		let o = horizontalOnly
		var h = false
		var v = false
		if horizontalOnly {
			h = !horizontal
		} else {
			if !horizontal && !vertical {
				h = true
			}
			else if horizontal && !vertical {
				h = true
				v = true
			}
			else if horizontal && vertical {
				v = true
			}
		}
		return .init(horizontalOnly: o, horizontal: h, vertical: v)
	}
}
