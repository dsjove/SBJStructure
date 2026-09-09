import UIKit

public extension Bundle {
	var displayName: String? {
		self.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
		?? self.object(forInfoDictionaryKey: "CFBundleName") as? String
	}

	var version: String? {
		self.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
	}

	var build: String? {
		self.object(forInfoDictionaryKey: "CFBundleVersion") as? String
	}

	var fullVersion: String? {
		if let version {
			if let build {
				return "\(version) (\(build))"
			}
			return version
		} else if let build {
			return build
		}
		return nil
	}

	var icon: UIImage? {
		if let iconName = object(forInfoDictionaryKey: "CFBundleIconName") as? String {
			if let named = UIImage(named: iconName) { return named }
			if let url = url(forResource: iconName, withExtension: "icns"),
			   let image = UIImage(contentsOfFile: url.path) {
				return image
			}
		}
		let dictionaries = ["CFBundleIcons", "CFBundleIcons~ipad"]
		for key in dictionaries {
			guard
				let icons = infoDictionary?[key] as? [String: Any],
				let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
				let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String]
			else { continue }

			for iconFile in iconFiles.reversed() {
				if let named = UIImage(named: iconFile) { return named }
				let ns = iconFile as NSString
				let ext = ns.pathExtension.isEmpty ? nil : ns.pathExtension
				let name = ext == nil ? iconFile : ns.deletingPathExtension
				if let url = url(forResource: name, withExtension: ext),
				   let image = UIImage(contentsOfFile: url.path) {
					return image
				}
			}
		}
		return nil
	}
}
