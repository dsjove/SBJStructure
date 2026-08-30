import Foundation

/// Converts arbitrary text into a valid Swift identifier suitable for generated source.
public func swiftIdentifier(for name: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))

    let parts = name.split(whereSeparator: { $0.isWhitespace })

    var result = parts.enumerated()
        .map { index, part in
            let cleaned = part.unicodeScalars
                .map { allowed.contains($0) ? String($0) : "_" }
                .joined()

            guard index > 0, let first = cleaned.first else {
                return cleaned
            }

            return first.uppercased() + cleaned.dropFirst()
        }
        .joined()

    if result.isEmpty {
        result = "character"
    }

    if let first = result.unicodeScalars.first,
       CharacterSet.decimalDigits.contains(first) {
        result = "_" + result
    }

    let keywords: Set<String> = [
        "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
        "import", "return", "switch", "case", "default", "if", "else", "for", "while",
        "do", "catch", "throw", "throws", "try", "in", "where", "as", "is", "nil",
        "true", "false", "self", "Self", "super"
    ]

    if keywords.contains(result) {
        result = "_" + result
    }

    return result
}
