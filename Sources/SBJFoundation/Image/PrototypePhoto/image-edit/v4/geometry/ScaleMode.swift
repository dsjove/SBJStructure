import Foundation

public enum ScaleMode: Codable, CustomStringConvertible {
	case fit
	case fill

	public var description: String {
		switch self {
		case .fit:
			return "fit"
		case .fill:
			return "fill"
		}
	}
}
