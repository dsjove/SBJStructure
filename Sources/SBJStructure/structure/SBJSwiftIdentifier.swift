import Foundation

/// Converts arbitrary text into a valid Swift identifier suitable for generated source.
public func swiftIdentifier(for name: String) -> String {
    let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
    var result = name.unicodeScalars
        .map { allowed.contains($0) ? String($0) : "_" }
        .joined()

    if result.isEmpty { result = "character" }
    if let first = result.unicodeScalars.first, CharacterSet.decimalDigits.contains(first) {
        result = "_" + result
    }

    let keywords: Set<String> = [
        "class", "struct", "enum", "protocol", "extension", "func", "var", "let",
        "import", "return", "switch", "case", "default", "if", "else", "for", "while",
        "do", "catch", "throw", "throws", "try", "in", "where", "as", "is", "nil",
        "true", "false", "self", "Self", "super"
    ]
    if keywords.contains(result) { result = "_" + result }
    return result
}
