# SBJStructure

SBJStructure is a Swift framework for describing `Codable` models and declaring additional business rules, documentation, accessibility information, and usage hints beside the properties they affect. The Codable shape is the structure; SBJ property annotations refine that structure with information Swift and `CodingKeys` do not already express. Consumers decide when and how to use those declarations.

`SBJCodableEditor` is included as one consumer of that information, but the editor is not the purpose of the framework. The same metadata can be used by application validation, other UIs, diagnostics, import/export tools, documentation, tests, or any other consumer that understands SBJStructure.

See `SBJStructuredEditorPreview` for a detailed example.

## Design principles

### Declarations are passive

SBJStructure does **not** wrap annotated stored properties or insert validation into their getters or setters. It does not use `precondition`, `assert`, or automatic rejection of assignments.

```swift
@SBJStructure
struct Character: Codable {
    @SBJInteger(range: 1...20)
    var level: Int = 1
}

var character = Character()
character.level = 99       // ordinary Swift assignment; permitted
let level = character.level // ordinary Swift access
```

The annotation declares that `1...20` is the valid business domain. It does not make assignment itself conditional.

A consumer explicitly chooses when to apply the declaration:

```swift
try character.invariant(at: \Character.self)
```

This separation is intentional. A model may temporarily contain incomplete or invalid data while it is being constructed, decoded, migrated, edited, or repaired. The framework records the rules without imposing a lifecycle on the model.

### Codable membership is the structure

`@SBJStructure` treats the model's coded stored properties as the structural declaration. If the model defines `CodingKeys`, those keys determine which stored properties participate. If it does not, all eligible stored properties participate.

A property does **not** need an SBJ annotation merely to participate, appear in `sbjProperties`, or receive a built-in editor. Swift already declares its type; `CodingKeys` already declares coded membership.

SBJ property annotations exist only to add information that is not already present in the Codable declaration: business rules such as ranges and uniqueness, or usage hints such as multiline text, reordering, and color alpha support.

As a style rule, do not add an SBJ property annotation with no effective rule or hint. If the annotation says nothing beyond the Swift type and coded membership, omit it.

### No parallel builder schema

Additional rules live beside the properties they describe:

```swift
@SBJText(minLength: 1, maxLength: 80)
var name: String

@SBJArray(minCount: 1, uniqueBy: \Attack.id)
var attacks: [Attack]
```

There is no separate chain of field builders that must duplicate the model declaration.

### Metadata is UI-independent

`@SBJStructure` synthesizes `SBJPropertyMetadata` for coded stored properties. Business constraints, documentation, and usage hints are available without presenting an editor.

```swift
let properties = Character.sbjProperties
let metadata = Character.propertyMetadata(for: \Character.name)
```

### Editor integration is optional

Writable coded properties are also exposed to `SBJCodableEditor`. The editor consumes the same structural metadata rather than maintaining a separate copy of annotation settings.

```swift
SBJCodableEditor(value: $character)
```

## Basic model declaration

```swift
@SBJStructure
struct Character: Codable {
    @SBJText(minLength: 1, maxLength: 80)
    var name: String

    @SBJInteger(range: 1...20)
    var level: Int

    @SBJOptional(required: true)
    var background: Background?

    @SBJArray(
        reorderable: true,
        title: \Attack.name,
        minCount: 1,
        maxCount: 10,
        uniqueBy: \Attack.id
    )
    var attacks: [Attack]

    @SBJData(min: 16, max: 64, modulo: 16)
    var payload: Data
}
```

`CodingKeys` is authoritative for structural membership when it is present. Properties do not require SBJ property annotations to participate.

## Structural metadata

Types annotated with `@SBJStructure` conform to `SBJStructured` and expose:

```swift
static var sbjProperties: [SBJPropertyMetadata<Self>] { get }

static func propertyMetadata<Value>(
    for keyPath: KeyPath<Self, Value>
) -> SBJPropertyMetadata<Self>?

static func propertyInfo<Value>(
    for keyPath: KeyPath<Self, Value>
) -> SBJPropertyInfo?

static func sbjDefaultValue() -> Self?
```

Each `SBJPropertyMetadata` contains:

- `sourceName` — the Swift property name.
- `displayName` — SBJStructure's default human-readable name.
- `keyPath` — the actual model key path.
- `kind` — the structural type category inferred from the Swift declaration when possible. For types the macro cannot determine syntactically, this is `.inferred`.
- `constraints` — declared business rules.
- `hints` — non-invariant presentation or usage hints.
- `info` — optional application documentation from `SBJPropertyInfo`.

The distinction between constraints and hints is deliberate. A count limit is a model invariant. Array reorderability is information a consumer may choose to honor.

## Generated members and extending generated behavior

`@SBJStructure` synthesizes several members. Most applications use the public members directly, while the underscore-prefixed members exist so a model can extend the generated behavior without reimplementing it.

For structs, the generated members are:

```swift
static var sbjProperties: [SBJPropertyMetadata<Self>] { get }

@MainActor
static var sbjEditorFields: [SBJEditorField<Self>] { get }

var _hasContent: Bool { get }
var hasContent: Bool { get }

func _invariant(at keyPath: SBJValidationKeyPath) throws
func invariant(at keyPath: SBJValidationKeyPath) throws

static func sbjDefaultValue() -> Self?
```

Associated-value enums additionally receive the enum/editor construction members used by `SBJCodableEditor`.

### `_hasContent` and `hasContent`

`_hasContent` is always the content calculation synthesized from the coded properties. Normally the macro also synthesizes `hasContent` as a forwarding property:

```swift
var hasContent: Bool {
    _hasContent
}
```

A model can replace the public `hasContent` behavior while retaining the generated property checks by declaring `hasContent` in the annotated type body:

```swift
@SBJStructure
struct Character: Codable {
    @SBJText
    var name: String = ""

    var isTemplate = false

    var hasContent: Bool {
        isTemplate || _hasContent
    }
}
```

The macro sees the explicit `hasContent`, still generates `_hasContent`, and does not generate the forwarding `hasContent` property.

### `_invariant(at:)` and `invariant(at:)`

`_invariant(at:)` always contains the invariant checks synthesized from SBJ annotations and recursive coded properties. Normally the public `invariant(at:)` simply calls it.

To add model-specific business rules **in addition to** the generated rules, declare `invariant(at:)` in the annotated type body and call `_invariant(at:)` first (or at the point appropriate for the model):

```swift
@SBJStructure
struct DateRange: Codable {
    var start: Date
    var end: Date

    func invariant(at keyPath: SBJValidationKeyPath) throws {
        try _invariant(at: keyPath)
        try SBJInvariantCheck.require(
            start <= end,
            at: keyPath,
            "start date must not be after end date"
        )
    }
}
```

This is the intended extension point for generated validation. Calling `_invariant(at:)` preserves all annotation-generated checks; omitting it intentionally replaces them.

**Important:** the macro can only detect members present in the declaration it is attached to. If custom `hasContent` or `invariant(at:)` behavior is placed in a separate extension, the macro will already have synthesized the public member and the extension will redeclare it. Put these customizations inside the `@SBJStructure` type body and use the underscore-prefixed generated member to extend the default behavior.

### `sbjDefaultValue()`

`SBJStructured` provides a default `sbjDefaultValue()` implementation that returns `nil`. For a struct whose `Codable` conformance is direct or inherited through another protocol, `@SBJStructure` synthesizes:

```swift
static func sbjDefaultValue() -> Self? {
    .init()
}
```

when the macro can prove a zero-argument initialization is valid. This happens when an explicit non-failable, non-throwing initializer has defaults for every parameter, or when the struct has no explicit initializer and every stored instance property has an initializer. The macro does not require the literal token `Codable` in the inheritance clause: `SBJEditable` itself refines `SBJStructured`, which refines `Codable`, so Swift's type checker resolves the complete protocol tree. The generated method is used by generic creation consumers without adding any work to property access.

If construction requires domain context, the macro leaves the protocol default (`nil`) in place. The model may implement `sbjDefaultValue()` itself or an application may register an exact creator with `SBJEditorRegistry`.

### Structural metadata

`sbjProperties` is the generated UI-independent schema and may be consumed directly:

```swift
for property in Character.sbjProperties {
    print(property.sourceName, property.kind, property.constraints)
}
```

For one known property, prefer the typed key-path lookup:

```swift
let metadata = Character.propertyMetadata(for: \Character.level)
let info = Character.propertyInfo(for: \Character.level)
```

`sbjEditorFields` is editor integration metadata and is `@MainActor`; non-UI consumers should normally use `sbjProperties` instead.

## Explicit validation

Generated validation is invoked explicitly through `invariant(at:)` or through the public `SBJInvariantCheck` helpers.

```swift
do {
    try character.invariant(at: \Character.self)
} catch let error as SBJValidationError {
    print(error.keyPath)
    print(error.localizedDescription)
}
```

Nested validation paths retain useful collection locations, including array indices, dictionary keys, and set members.

Handwritten invariants may use the same helpers as generated invariants:

```swift
try SBJInvariantCheck.require(
    startDate <= endDate,
    at: path,
    "start date must not be after end date"
)
```

Other helpers include range, minimum, required optional, text length, collection count, uniqueness, key-path uniqueness, and Data byte-count validation.

## Property documentation and accessibility

`SBJPropertyInfo` is application/model documentation, not editor-only configuration. Any UI or tool may consume it.

```swift
extension Character {
    static func propertyInfo<Value>(
        for keyPath: KeyPath<Character, Value>
    ) -> SBJPropertyInfo? {
        switch keyPath {
        case \Character.level:
            return SBJPropertyInfo(
                title: "Character Level",
                summary: "The character's total level.",
                details: "Levels normally range from 1 through 20.",
                accessibilityLabel: "Character level",
                accessibilityHint: "Enter a value from 1 through 20",
                accessibilityValue: nil
            )
        default:
            return nil
        }
    }
}
```

`SBJPropertyInfo` provides:

- `title`
- `summary`
- `details`
- `accessibilityLabel`
- `accessibilityHint`
- `accessibilityValue`

`SBJCodableEditor` applies the accessibility values to the rendered property. Specialized scalar editors also provide meaningful current-value accessibility descriptions when appropriate.

## Annotation reference

### `@SBJStructure`

Attaches SBJStructure metadata generation to a `Codable` struct or enum.

For structs, coded stored properties become structural metadata and writable properties become generic editor fields. Structural metadata and explicit invariant generation are independent of editor eligibility.

For enums, associated-value case information is generated for recursive editor support.


### Declaration diagnostics

SBJ annotations are declarations, so configuration errors that are knowable from source are diagnosed at compile time. Examples include applying an annotation to an incompatible property type, negative text/collection/Data size limits, minimum values greater than maximum values, and a non-positive Data modulo. This is distinct from model validation: a declaration such as `@SBJInteger(range: 1...20)` must itself be well-formed, while assigning `99` to the property remains ordinary Swift and is reported only when a consumer explicitly requests validation.

Editor diagnostics evaluate the owning `SBJStructured` value as well as recursively inspecting editor support. This means an owner-declared rule such as `@SBJInteger(range:)` appears in the Editor Issues list; invalid values remain warnings and do not prevent editing or saving.

Optional scalar values inherit their property's scalar editor metadata. For example, `@SBJDate(range:) var date: Date?` passes the declared range to the unwrapped Date editor, and `@SBJColor(alpha: false) var color: CodableColor?` passes the alpha hint to the unwrapped color editor. Collection element annotations are intentionally a separate future design problem; current collection-level scalar hint propagation is not a substitute for a general element-annotation API.

### Property annotations

Property annotations are **refinements**, not membership markers. Omit an annotation when the Swift/Codable declaration already says everything a consumer needs.

### `@SBJText`

Adds String length rules and/or text presentation. An ordinary `String` needs no annotation.

```swift
@SBJText(.singleLine, minLength: 1, maxLength: 40)
var name: String

@SBJText(.multiline, maxLength: 2_000)
var notes: String
```

Parameters:

- style: `.singleLine` or `.multiline`
- `minLength`
- `maxLength`

Length rules are applied only during explicit validation.

### `@SBJInteger`

Adds an integer constraint using either a closed range or a minimum.

```swift
@SBJInteger(range: 1...20)
var level: Int

@SBJInteger(min: 0)
var experience: Int
```

### `@SBJNumber`

Adds a floating-point constraint using either a closed range or a minimum.

```swift
@SBJNumber(range: 0...1)
var opacity: Double

@SBJNumber(min: 0.0)
var scale: Double
```

Non-finite floating-point values fail generated range and minimum validation.

### `@SBJOptional`

Adds a presence requirement to an optional value.

```swift
@SBJOptional(required: true)
var owner: Owner?
```

`required` is a business rule checked only when validation is requested.

### `@SBJArray`

Adds Array constraints and usage hints. An ordinary Array needs no annotation.

```swift
@SBJArray(
    reorderable: true,
    title: \Attack.name,
    minCount: 1,
    maxCount: 10,
    uniqueBy: \Attack.id
)
var attacks: [Attack]
```

Parameters:

- `reorderable` — whether a consumer may allow the user to change stored order.
- `title` — element key path used as a human-readable item title.
- `minCount`
- `maxCount`
- `unique` — requires Hashable elements to be unique.
- `uniqueBy` — requires uniqueness by a Hashable element key path.

`unique` and `uniqueBy` are alternative declarations and may not be used together.

Arrays always preserve their stored order. `reorderable` does not imply sorting.

### `@SBJSet`

Adds Set count rules and item-title metadata. An ordinary Set needs no annotation.

```swift
@SBJSet(
    title: \Proficiency.name,
    minCount: 1,
    maxCount: 20
)
var proficiencies: Set<Proficiency>
```

Sets are inherently unique and have no stored order. The generic editor therefore presents them deterministically rather than exposing reordering.

### `@SBJDictionary`

Adds dictionary entry-count rules. An ordinary Dictionary needs no annotation.

```swift
@SBJDictionary(minCount: 0, maxCount: 20)
var modifiers: [String: Int]
```

The generic editor stages key edits and rejects key collisions rather than overwriting another entry.

### `@SBJDate`

Adds an allowed range to a `Date`. Plain Date properties already participate and use the native date editor without an annotation.

```swift
@SBJDate(range: earliestAllowed...latestAllowed)
var modified: Date
```

The range is a business constraint checked during explicit validation. `SBJCodableEditor` also supplies the same range to `DatePicker`.

### URL

A plain `URL` requires no annotation:

```swift
var documentationURL: URL
```

The generic editor stages textual input, commits only a URL with an explicit scheme, and provides an Open action. URL-specific business-rule annotations are intentionally deferred because the useful URL rule surface is larger than this iteration. The legacy `@SBJURL` marker is deprecated because it adds no information.

### `@SBJUUID`

Adds a nonzero rule to a `UUID`. Plain UUID properties already participate and receive smart UUID editing.

```swift
@SBJUUID(nonzero: true)
var identifier: UUID
```

When enabled, explicit validation rejects the all-zero UUID (`UUID.sbjZero`). The public `UUID.sbjIsZero` and `UUID.sbjZero` helpers are also available to application code.

The generic editor accepts canonical, compact, and brace-wrapped UUID text, normalizes valid input, and provides a generate action regardless of whether this annotation is present.

### `@SBJData`

Adds Data byte-count constraints. Plain Data properties already participate and use the multiline hexadecimal editor without an annotation.

```swift
@SBJData(min: 16, max: 64, modulo: 16)
var payload: Data
```

Parameters operate on **bytes**:

- `min` — minimum byte count.
- `max` — maximum byte count.
- `modulo` — byte count must be evenly divisible by this positive value.

The generic editor presents Data as multiline hexadecimal and does not mutate the model while textual input is invalid or contains an incomplete byte.

### `@SBJColor`

Adds color usage information to a `CodableColor`. Plain `CodableColor` properties already participate and use `ColorPicker` with alpha support.

```swift
@SBJColor(alpha: false)
var accent: CodableColor
```

`alpha: false` tells consumers that the color should be treated as RGB-only. `SBJCodableEditor` honors this by disabling the opacity component in the standard `ColorPicker`.

### `@SBJNotEditable`

Suppresses generic editor generation for a coded property without removing it from the structural model.

```swift
@SBJNotEditable
var generatedSummary: String
```

The property still participates in `sbjProperties`, content inspection, and explicit invariant validation. This annotation is about editor eligibility, not model membership.

### `@SBJEditorProperty`

Exposes a writable computed property to the generic editor without making it part of the structural model. This is useful for UI-facing adapters backed by separate storage.

```swift
@SBJEditorProperty
var portraitImage: PlatformImage? {
    get { imageStore.load(id) }
    set { imageStore.stage(newValue, id: id) }
}
```

The property appears in `sbjEditorFields`, but not in `sbjProperties`, generated content inspection, or invariant validation. Its value does not need to conform to `Codable`. Applications normally register an exact editor for nonstandard values with `SBJEditorRegistry`.

Editor-only fields deliberately do not infer structural change, empty-content, or validation state, because there is no Codable/structural contract from which to derive those semantics. The owning model may still track the backing state normally.

## Unannotated coded values

Unannotated coded properties are the normal case. `@SBJStructure` includes them because they are part of the Codable model, not because they carry an SBJ property annotation. Current built-in scalar editing includes:

- `String`
- `Bool`
- signed and unsigned fixed-width integers
- `Float`
- `Double`
- `CGFloat`
- `Decimal`
- `Date`
- `URL`
- `UUID`
- `Data`
- `CodableColor`

Add an SBJ property annotation only when the model needs to declare an additional rule or usage hint.

## Content semantics

`HasContentCheckable` allows a type to define whether it contains meaningful domain content and to participate in recursive explicit invariant validation.

SBJStructure supplies content behavior for common containers such as Optional, Array, Set, and Dictionary. Models generated with `@SBJStructure` recursively inspect their coded members.

`hasContent` is observation, not enforcement. Reading it does not alter the model.

## Reusable SBJ utilities

Several operations used by the generic editor are public model/value utilities because they are useful independently of the editor and are discoverable from their primary Swift types.

### Hexadecimal Data

```swift
let text = data.sbjHexFormat(bytesPerRow: 16)
let parsed = try text.sbjHexData()
```

`Data` provides `sbjHexDescription`, `sbjHexFormat(...)`, and `isZero`. `String` provides throwing `sbjHexData()` and optional `sbjHexToData()` parsing.

### URL and UUID parsing

```swift
let url = " https://example.com ".sbjURL
let uuid = "550E8400E29B41D4A716446655440000".sbjUUID
```

These are the same parsing rules used by the smart scalar editors.

### Safe collection mutation

```swift
var names: Set = ["one", "two"]
names.sbjReplace("one", with: "three")

var values = ["one": 1, "two": 2]
values.sbjRenameKey("one", to: "three")
```

Both operations reject collisions and leave the collection unchanged on failure.

### Codable comparison and copying

```swift
let changed = edited.sbjEncodedIsDifferent(from: original)
let snapshot = edited.sbjCodableCopy()
```

The editor uses these same public operations for change tracking and snapshots.

## The generic Codable editor

`SBJCodableEditor` recursively presents writable model properties using generated `SBJEditorField` information and structural metadata.

```swift
SBJCodableEditor(
    value: $character,
    registry: registry
)
```

The editor understands constraints and hints where they are relevant to editing, but the annotations remain model declarations. Using `SBJCodableEditor` is never required to use SBJStructure metadata or validation.

### Custom application types

Domain-specific types can register an exact editor with `SBJEditorRegistry`:

```swift
var registry = SBJEditorRegistry()
registry.register(DiceExpression.self) { label, value, _ in
    DiceExpressionEditor(label: label, value: value)
}
registry.registerCreator(DiceExpression.self) {
    DiceExpression(count: 1, sides: 6, modifier: 0)
}
```

A registered editor receives a real binding to the application type. Registration takes precedence over built-in editing.

### Default creation for structured values

`SBJStructured` exposes:

```swift
static func sbjDefaultValue() -> Self?
```

The default implementation returns `nil`. `@SBJStructure` synthesizes `.init()` when the macro can prove that the Codable struct can be constructed without arguments: either an initializer has defaults for every parameter, or the struct has no explicit initializer and every stored property has an initializer.

That means ordinary model declarations such as this need no editor-specific creation protocol:

```swift
@SBJStructure
struct Note: Codable {
    var title = ""
    var body = ""
}
```

Collection `+` controls, nil optionals, and associated-enum payload construction use the same structured default. If creation requires application-specific context, leave `sbjDefaultValue()` as `nil` and register an exact creator with `SBJEditorRegistry`, or implement `sbjDefaultValue()` explicitly in the annotated type.

For the narrower case where a new collection element depends on elements already present, conform the element to `SBJCollectionElementCreatable`:

```swift
extension AbilityScore: SBJCollectionElementCreatable {
    static func sbjCreateValue(existing: [Self]) -> Self? {
        let used = Set(existing.map(\.ability))
        guard let ability = Ability.allCases.first(where: { !used.contains($0) }) else { return nil }
        return AbilityScore(ability)
    }
}
```

This protocol describes collection construction semantics, not editor semantics; the generic editor is simply one consumer.

### Simple enums

A `CaseIterable & Hashable` enum is automatically rendered as a picker. No SBJ editor protocol is required. Codable enums therefore usually need only their normal model conformances:

```swift
enum Alignment: String, Codable, CaseIterable, Hashable {
    case lawfulGood
    case neutral
    case chaoticEvil
}
```

The case label is derived from the Swift case spelling, and the first declared case is used as the generic default value. Applications may still register an exact editor or creator when those defaults are not appropriate.

### Associated-value enums

`@SBJStructure` may be attached directly to a Codable enum:

```swift
@SBJStructure
enum Rule: Codable {
    case automatic
    case adjusted(amount: Int, enabled: Bool)
    case fixed(Int)
}
```

The editor renders a case selector and recursively generated controls for associated values. Changing an associated value reconstructs the selected case while preserving its other associated values.

`SBJEditorDefaultValue` is the shared type-erased factory used by generated associated-enum constructors and editor creation. It checks built-in scalar defaults, associated-value enum construction, `SBJStructured.sbjDefaultValue()`, and finally the first case of a plain `CaseIterable` enum. Applications normally customize creation through the structured default hook, `SBJCollectionElementCreatable`, or `SBJEditorRegistry` rather than calling the factory directly.

## Public API organization

SBJStructure intentionally favors APIs that are discoverable from the value they operate on. General operations on `Data`, `String`, `Set`, `Dictionary`, and Codable values are public extensions with `sbj`-prefixed names.

Namespace types remain where there is no natural primary receiver or the API represents a service family. Examples include:

- `SBJInvariantCheck` — explicit rule evaluation.
- `SBJEditorDiagnostics` — recursive editor diagnostics.
- `SBJEditorDefaultValue` — creation from an arbitrary metatype.

This keeps the framework usable as a core application dependency without hiding generally useful model operations inside editor implementation namespaces.
