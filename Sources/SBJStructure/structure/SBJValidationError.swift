import Foundation

/// Standard validation failure used by generated and custom invariants.
public struct SBJValidationError: LocalizedError, @unchecked Sendable {
    public let keyPath: SBJValidationKeyPath
    public let message: String

    public init(_ message: String, at keyPath: SBJValidationKeyPath) {
        self.message = message
        self.keyPath = keyPath
    }

    public init<Root, Value>(_ message: String, at keyPath: KeyPath<Root, Value>) {
        self.init(message, at: SBJValidationKeyPath(keyPath))
    }

    public var errorDescription: String? { message }
}
