import Foundation

public extension String {
	func sanitizedFilename(
		removeSpaces: Bool = false,
		replacement: String = "-"
	) -> String {
		let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty else { return "" }

		let originalName = trimmed // we assume no path
		guard !originalName.isEmpty else { return "" }

		let invalid = CharacterSet(charactersIn: "/\\?%*|\"<>:")
			.union(.newlines)
			.union(.illegalCharacters)
			.union(.controlCharacters)

		var result = ""
		var lastWasReplacement = false

		for scalar in originalName.unicodeScalars {
			if invalid.contains(scalar) {
				if !replacement.isEmpty && !lastWasReplacement {
					result += replacement
					lastWasReplacement = true
				}
			} else {
				result.unicodeScalars.append(scalar)
				lastWasReplacement = false
			}
		}

		while result.hasPrefix(replacement), !replacement.isEmpty {
			result.removeFirst(replacement.count)
		}

		while result.hasSuffix(replacement), !replacement.isEmpty {
			result.removeLast(replacement.count)
		}

		if removeSpaces {
			result = result.replacingOccurrences(of: " ", with: "")
		}

		result = result.trimmingCharacters(in: .whitespacesAndNewlines)

		let reservedWindowsNames: Set<String> = [
			"CON", "PRN", "AUX", "NUL",
			"COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9",
			"LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
		]

		let baseName = URL(fileURLWithPath: result).deletingPathExtension().lastPathComponent
		if reservedWindowsNames.contains(baseName.uppercased()) {
			result = "_" + result
		}

		return result
	}
}
