import Foundation
import CoreGraphics

/// Runtime validation helpers used by macro-generated and handwritten invariants.
///
/// Nothing in this type is invoked by ordinary property reads or writes. A
/// consumer must explicitly request validation, normally through `invariant`.
public enum SBJInvariantCheck {
    public static func validate<T>(_ value: T, at keyPath: SBJValidationKeyPath) throws {
        if let checkable = value as? any HasContentCheckable {
            try checkable.invariant(at: keyPath)
        }
    }

    public static func validationError<T>(_ value: T, at keyPath: SBJValidationKeyPath) -> SBJValidationError? {
        do {
            try validate(value, at: keyPath)
            return nil
        } catch let error as SBJValidationError {
            return error
        } catch {
            return SBJValidationError(error.localizedDescription, at: keyPath)
        }
    }

    public static func require(
        _ condition: @autoclosure () -> Bool,
        at keyPath: SBJValidationKeyPath,
        _ message: String
    ) throws {
        guard condition() else { throw SBJValidationError(message, at: keyPath) }
    }

    public static func requireRange(_ value: Int, _ range: ClosedRange<Int>, at keyPath: SBJValidationKeyPath) throws {
        try require(range.contains(value), at: keyPath, "must be in \(range.lowerBound)...\(range.upperBound)")
    }

    public static func requireRange(_ value: Int?, _ range: ClosedRange<Int>, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireRange(value, range, at: keyPath) }
    }

    public static func requireRange(_ values: [Int], _ range: ClosedRange<Int>, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireRange(value, range, at: keyPath.appending(index: index))
        }
    }

    public static func requireMinimum(_ value: Int, _ minimum: Int, at keyPath: SBJValidationKeyPath) throws {
        try require(value >= minimum, at: keyPath, "must be at least \(minimum)")
    }

    public static func requireMinimum(_ value: Int?, _ minimum: Int, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireMinimum(value, minimum, at: keyPath) }
    }

    public static func requireMinimum(_ values: [Int], _ minimum: Int, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireMinimum(value, minimum, at: keyPath.appending(index: index))
        }
    }


    private static func requireIntegerRange<T: FixedWidthInteger>(
        _ value: T, _ range: ClosedRange<Int>, at keyPath: SBJValidationKeyPath
    ) throws {
        guard let converted = Int(exactly: value) else {
            throw SBJValidationError("must be in \(range.lowerBound)...\(range.upperBound)", at: keyPath)
        }
        try requireRange(converted, range, at: keyPath)
    }

    public static func requireRange<T: FixedWidthInteger>(_ value: T, _ range: ClosedRange<Int>, at keyPath: SBJValidationKeyPath) throws {
        try requireIntegerRange(value, range, at: keyPath)
    }

    public static func requireRange<T: FixedWidthInteger>(_ value: T?, _ range: ClosedRange<Int>, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireIntegerRange(value, range, at: keyPath) }
    }

    public static func requireRange<T: FixedWidthInteger>(_ values: [T], _ range: ClosedRange<Int>, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireIntegerRange(value, range, at: keyPath.appending(index: index))
        }
    }

    private static func requireIntegerMinimum<T: FixedWidthInteger>(
        _ value: T, _ minimum: Int, at keyPath: SBJValidationKeyPath
    ) throws {
        if let converted = Int(exactly: value) {
            try require(converted >= minimum, at: keyPath, "must be at least \(minimum)")
            return
        }
        // An unsigned value that does not fit Int is necessarily greater than Int.max
        // and therefore satisfies any Int minimum.
        if T.min == 0 { return }
        throw SBJValidationError("must be at least \(minimum)", at: keyPath)
    }

    public static func requireMinimum<T: FixedWidthInteger>(_ value: T, _ minimum: Int, at keyPath: SBJValidationKeyPath) throws {
        try requireIntegerMinimum(value, minimum, at: keyPath)
    }

    public static func requireMinimum<T: FixedWidthInteger>(_ value: T?, _ minimum: Int, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireIntegerMinimum(value, minimum, at: keyPath) }
    }

    public static func requireMinimum<T: FixedWidthInteger>(_ values: [T], _ minimum: Int, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireIntegerMinimum(value, minimum, at: keyPath.appending(index: index))
        }
    }

    public static func requireRange(_ value: Double, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        try require(value.isFinite && range.contains(value), at: keyPath, "must be finite and in \(range.lowerBound)...\(range.upperBound)")
    }

    public static func requireRange(_ value: Double?, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireRange(value, range, at: keyPath) }
    }

    public static func requireRange(_ values: [Double], _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireRange(value, range, at: keyPath.appending(index: index))
        }
    }

    public static func requireRange(_ value: Float, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        try requireRange(Double(value), range, at: keyPath)
    }

    public static func requireRange(_ value: Float?, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireRange(value, range, at: keyPath) }
    }


    public static func requireRange(_ value: CGFloat, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        try requireRange(Double(value), range, at: keyPath)
    }

    public static func requireRange(_ value: CGFloat?, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireRange(value, range, at: keyPath) }
    }

    public static func requireRange(_ value: Decimal, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        let number = NSDecimalNumber(decimal: value).doubleValue
        try requireRange(number, range, at: keyPath)
    }

    public static func requireRange(_ value: Decimal?, _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireRange(value, range, at: keyPath) }
    }

    public static func requireRange<T: BinaryFloatingPoint>(_ values: [T], _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireRange(Double(value), range, at: keyPath.appending(index: index))
        }
    }

    public static func requireRange(_ values: [Decimal], _ range: ClosedRange<Double>, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireRange(value, range, at: keyPath.appending(index: index))
        }
    }

    public static func requireMinimum(_ value: Double, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        try require(value.isFinite && value >= minimum, at: keyPath, "must be finite and at least \(minimum)")
    }

    public static func requireMinimum(_ value: Double?, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireMinimum(value, minimum, at: keyPath) }
    }

    public static func requireMinimum(_ value: Float, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        try requireMinimum(Double(value), minimum, at: keyPath)
    }

    public static func requireMinimum(_ value: Float?, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireMinimum(value, minimum, at: keyPath) }
    }

    public static func requireMinimum(_ value: CGFloat, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        try requireMinimum(Double(value), minimum, at: keyPath)
    }

    public static func requireMinimum(_ value: CGFloat?, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireMinimum(value, minimum, at: keyPath) }
    }

    public static func requireMinimum(_ value: Decimal, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        try requireMinimum(NSDecimalNumber(decimal: value).doubleValue, minimum, at: keyPath)
    }

    public static func requireMinimum(_ value: Decimal?, _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireMinimum(value, minimum, at: keyPath) }
    }

    public static func requireMinimum<T: BinaryFloatingPoint>(_ values: [T], _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireMinimum(Double(value), minimum, at: keyPath.appending(index: index))
        }
    }

    public static func requireMinimum(_ values: [Decimal], _ minimum: Double, at keyPath: SBJValidationKeyPath) throws {
        for (index, value) in values.enumerated() {
            try requireMinimum(value, minimum, at: keyPath.appending(index: index))
        }
    }

    public static func requirePresent<T>(_ value: T?, required: Bool, at keyPath: SBJValidationKeyPath) throws {
        if required { try require(value != nil, at: keyPath, "must be present") }
    }

    public static func requireNonzero(_ value: UUID, at keyPath: SBJValidationKeyPath) throws {
        try require(!value.sbjIsZero, at: keyPath, "must not be the zero UUID")
    }

    public static func requireNonzero(_ value: UUID?, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireNonzero(value, at: keyPath) }
    }

    public static func requireRange(_ value: Date, _ range: ClosedRange<Date>, at keyPath: SBJValidationKeyPath) throws {
        try require(range.contains(value), at: keyPath, "must be in the declared date range")
    }

    public static func requireRange(_ value: Date?, _ range: ClosedRange<Date>, at keyPath: SBJValidationKeyPath) throws {
        if let value { try requireRange(value, range, at: keyPath) }
    }

    public static func requireText(_ value: String, minLength: Int?, maxLength: Int?, at keyPath: SBJValidationKeyPath) throws {
        if let minLength {
            try require(value.count >= minLength, at: keyPath, "must contain at least \(minLength) characters")
        }
        if let maxLength {
            try require(value.count <= maxLength, at: keyPath, "must contain at most \(maxLength) characters")
        }
    }

    public static func requireCount<C: Collection>(
        _ value: C,
        minCount: Int?,
        maxCount: Int?,
        at keyPath: SBJValidationKeyPath
    ) throws {
        if let minCount {
            try require(value.count >= minCount, at: keyPath, "must contain at least \(minCount) elements")
        }
        if let maxCount {
            try require(value.count <= maxCount, at: keyPath, "must contain at most \(maxCount) elements")
        }
    }

    public static func requireUnique<C: Collection>(
        _ values: C,
        at keyPath: SBJValidationKeyPath,
        _ message: String = "must contain unique values"
    ) throws where C.Element: Hashable {
        var seen = Set<C.Element>()
        for (index, value) in values.enumerated() {
            guard seen.insert(value).inserted else {
                throw SBJValidationError(message, at: keyPath.appending(index: index))
            }
        }
    }

    public static func requireUnique<C: Collection, Key: Hashable>(
        _ values: C,
        by keyPathToKey: KeyPath<C.Element, Key>,
        at keyPath: SBJValidationKeyPath,
        _ message: String = "must contain values with unique keys"
    ) throws {
        var seen = Set<Key>()
        for (index, value) in values.enumerated() {
            guard seen.insert(value[keyPath: keyPathToKey]).inserted else {
                throw SBJValidationError(message, at: keyPath.appending(index: index))
            }
        }
    }

    /// Applies byte-count business rules to `Data`. This is available before the
    /// dedicated Data annotation/editor so custom consumers can use the same
    /// invariant implementation.
    public static func requireData(
        _ value: Data,
        min: Int? = nil,
        max: Int? = nil,
        modulo: Int? = nil,
        at keyPath: SBJValidationKeyPath
    ) throws {
        if let min {
            try require(value.count >= min, at: keyPath, "must contain at least \(min) bytes")
        }
        if let max {
            try require(value.count <= max, at: keyPath, "must contain at most \(max) bytes")
        }
        if let modulo {
            try require(modulo > 0, at: keyPath, "modulo must be greater than zero")
            try require(value.count.isMultiple(of: modulo), at: keyPath, "byte count must be a multiple of \(modulo)")
        }
    }

    public static func requireData(
        _ value: Data?,
        min: Int? = nil,
        max: Int? = nil,
        modulo: Int? = nil,
        at keyPath: SBJValidationKeyPath
    ) throws {
        if let value { try requireData(value, min: min, max: max, modulo: modulo, at: keyPath) }
    }
}

// MARK: - Handwritten invariant conveniences

public func require(
    _ condition: @autoclosure () -> Bool,
    _ keyPath: SBJValidationKeyPath,
    _ requirement: String
) throws {
    try SBJInvariantCheck.require(condition(), at: keyPath, requirement)
}

public func requireMeaningful(_ value: String, _ keyPath: SBJValidationKeyPath) throws {
    try require(
        value.trimmingCharacters(in: .whitespacesAndNewlines).hasContent,
        keyPath,
        "must contain non-whitespace text"
    )
}

public func requireUnique<T: Hashable>(
    _ values: [T],
    _ keyPath: SBJValidationKeyPath,
    _ requirement: String = "must contain unique values"
) throws {
    try SBJInvariantCheck.requireUnique(values, at: keyPath, requirement)
}

public func requireUnique<Element, Key: Hashable>(
    _ values: [Element],
    by keyPathToKey: KeyPath<Element, Key>,
    _ keyPath: SBJValidationKeyPath,
    _ requirement: String = "must contain values with unique keys"
) throws {
    try SBJInvariantCheck.requireUnique(values, by: keyPathToKey, at: keyPath, requirement)
}
