import Foundation

@MainActor
func shareItem(content: String, name: String? = nil, ext: String? = nil) -> Any {
	if let name {
		let suffix = ext.map { $0.isEmpty ? "" : ".\($0)" } ?? ""
		let fileName = name.sanitizedFilename() + suffix
		if let fileURL = writeToTempFile(named: fileName, content: content) {
			return fileURL
		}
	}
	return content
}

private func writeToTempFile(named: String, content: String) -> URL? {
	let tempDir = FileManager.default.temporaryDirectory
	let fileURL = tempDir.appendingPathComponent(named)
	do {
		try content.write(to: fileURL, atomically: true, encoding: .utf8)
		return fileURL
	} catch {
		return nil
	}
}
