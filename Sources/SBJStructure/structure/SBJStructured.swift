import Foundation

/// UI-independent description of a model annotated with `@SBJStructure`.
///
/// SBJStructure declarations describe the model; they do not intercept property
/// access or automatically enforce invariants. Consumers explicitly choose when
/// to inspect metadata, content state, or validation rules.
public protocol SBJStructured: Codable, HasContentCheckable {
    /// Structural metadata for the coded stored properties of this model.
    static var sbjProperties: [SBJPropertyMetadata<Self>] { get }

    /// Supplemental documentation and accessibility information for a property.
    ///
    /// The default implementation returns `nil`. Applications may implement this
    /// method to provide documentation consumed by editors or any other UI/tool.
    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo?

    /// Returns a sensible default instance when the structured type can be
    /// constructed without application-specific context. `@SBJStructure`
    /// synthesizes this when a zero-argument initialization is provably valid.
    static func sbjDefaultValue() -> Self?
}

public extension SBJStructured {
    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? { nil }

    static func sbjDefaultValue() -> Self? { nil }

    /// Returns the generated structural metadata for a specific property.
    static func propertyMetadata<Value>(
        for keyPath: KeyPath<Self, Value>
    ) -> SBJPropertyMetadata<Self>? {
        sbjProperties.first { $0.keyPath == keyPath }
    }
}

/// UI-independent metadata describing one coded stored property on `Root`.
///
/// The key path identifies the actual model property. `sourceName` is the Swift
/// declaration name, while `displayName` provides SBJStructure's default human-
/// readable presentation. Consumers are free to ignore either value.
public struct SBJPropertyMetadata<Root: SBJStructured> {
    public let sourceName: String
    public let displayName: String
    public let keyPath: PartialKeyPath<Root>
    public let kind: SBJPropertyKind
    public let constraints: [SBJPropertyConstraint]
    public let hints: [SBJPropertyHint]
    public let info: SBJPropertyInfo?

    public init<Value>(
        sourceName: String,
        displayName: String,
        keyPath: KeyPath<Root, Value>,
        kind: SBJPropertyKind = .inferred,
        constraints: [SBJPropertyConstraint] = [],
        hints: [SBJPropertyHint] = [],
        info: SBJPropertyInfo? = nil
    ) {
        self.sourceName = sourceName
        self.displayName = displayName
        self.keyPath = keyPath
        self.kind = kind
        self.constraints = constraints
        self.hints = hints
        self.info = info
    }
}

/// The structural type category inferred from the Swift property declaration.
///
/// Property annotations refine rules and hints; they are not required to establish
/// the kind. ``inferred`` is reserved for model types that do not map to a built-in
/// SBJStructure category.
public enum SBJPropertyKind: Sendable, Equatable {
    case inferred
    case text
    case bool
    case integer
    case number
    case optional
    case array
    case set
    case dictionary
    case url
    case uuid
    case date
    case data
    case color
}

/// A business rule declared for a model property.
///
/// These values are descriptive metadata. They do not intercept assignment or
/// enforce themselves. Validation and other consumers explicitly interpret them.
public enum SBJPropertyConstraint: Sendable, Equatable {
    case textLength(min: Int?, max: Int?)
    case integerRange(ClosedRange<Int>)
    case integerMinimum(Int)
    case numberRange(ClosedRange<Double>)
    case numberMinimum(Double)
    case required(Bool)
    case count(min: Int?, max: Int?)
    case unique
    /// Human-readable representation of the compiler-checked element key path.
    /// Generated validation retains and uses the actual key path expression.
    case uniqueBy(String)
    case dataSize(min: Int?, max: Int?, modulo: Int?)
    case uuidNonzero
    case dateRange(ClosedRange<Date>)
}

/// Non-invariant usage or presentation information declared on a model property.
/// Consumers may honor these hints, but they do not participate in validation.
public enum SBJPropertyHint: Sendable, Equatable {
    case textStyle(SBJTextStyle)
    case reorderable(Bool)
    case colorSupportsAlpha(Bool)
    /// Human-readable representation of the compiler-checked item-title key path.
    case itemTitle(String)
}
