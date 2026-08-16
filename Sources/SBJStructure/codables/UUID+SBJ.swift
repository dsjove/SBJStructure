import Foundation

public extension UUID {
    /// The all-zero UUID value, useful for sentinel checks and model invariants.
    static let sbjZero = UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))

    /// Whether this UUID is the all-zero UUID.
    var sbjIsZero: Bool { self == .sbjZero }
}
