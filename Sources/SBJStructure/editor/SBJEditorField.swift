import SwiftUI

/// Type-erased metadata for one writable property on `Root`.
///
/// Editor fields are UI metadata: they hold SwiftUI bindings and view factories,
/// so the entire abstraction is isolated to the main actor. Keeping construction
/// and use in the same isolation domain also prevents writable key paths from
/// being transferred into a main-actor closure from a nonisolated context.
@MainActor
public struct SBJEditorField<Root: SBJStructured> {
    public let name: String
    private let makeView: (Binding<Root>, Root?, SBJEditorRegistry, String?, SBJEditorFocusRequest?, Bool) -> AnyView
    private let collectIssues: (Root, [String], SBJEditorRegistry) -> [SBJEditorIssue]
    private let matchesSearch: (Root, String, SBJEditorRegistry) -> Bool
    private let hasChanged: (Root, Root?) -> Bool
    private let hasContent: (Root) -> Bool?
    private let containsEmptyContent: (Root, SBJEditorRegistry) -> Bool
    private let validationError: (Root) -> SBJValidationError?
    private let validationKeyPath: AnyKeyPath
    private let participatesInStructuralValidation: Bool

    public init<Value: Codable>(
        name: String,
        _ keyPath: WritableKeyPath<Root, Value>
    ) {
        self.name = name
        self.validationKeyPath = keyPath
        self.participatesInStructuralValidation = true
        let metadata = Root.propertyMetadata(for: keyPath)
        let propertyInfo = metadata?.info
        let textStyle = metadata?.hints.compactMap { hint -> SBJTextStyle? in
            if case let .textStyle(style) = hint { return style }
            return nil
        }.first
        let integerRange = metadata?.constraints.compactMap { constraint -> ClosedRange<Int>? in
            switch constraint {
            case let .integerRange(range): return range
            case let .integerMinimum(minimum): return minimum...Int.max
            default: return nil
            }
        }.first
        let dateRange = metadata?.constraints.compactMap { constraint -> ClosedRange<Date>? in
            if case let .dateRange(range) = constraint { return range }
            return nil
        }.first
        let colorSupportsAlpha = metadata?.hints.compactMap { hint -> Bool? in
            if case let .colorSupportsAlpha(value) = hint { return value }
            return nil
        }.first ?? true
        let collectionReorderable = metadata?.hints.compactMap { hint -> Bool? in
            if case let .reorderable(value) = hint { return value }
            return nil
        }.first ?? true
        let collectionItemTitleKey = metadata?.hints.compactMap { hint -> String? in
            if case let .itemTitle(value) = hint { return value }
            return nil
        }.first
        self.makeView = { root, originalRoot, registry, overrideName, focusRequest, labelIsUnknown in
            let defaultValue = Binding<Value>(
                get: { root.wrappedValue[keyPath: keyPath] },
                set: { root.wrappedValue[keyPath: keyPath] = $0 }
            )
            let value = registry.customBinding(keyPath: keyPath, root: root) ?? defaultValue
            let originalValue = originalRoot.map { $0[keyPath: keyPath] }
            let label = overrideName ?? name
            let defaultContent: AnyView
            if Root.self == CodableFont.self,
               name == "Name",
               Value.self == Optional<String>.self {
                let fontFamily = Binding<String?>(
                    get: { value.wrappedValue as! String? },
                    set: { value.wrappedValue = $0 as! Value }
                )
                defaultContent = SBJValueEditor.makeFontFamilyView(
                    label: "Font",
                    value: fontFamily,
                    labelIsUnknown: labelIsUnknown
                )
            } else {
                defaultContent = SBJValueEditor.makeView(
                    label: label,
                    value: value,
                    originalValue: originalValue.map { SBJEditorOriginalValue($0) },
                    registry: registry,
                    textStyle: textStyle,
                    integerRange: integerRange,
                    dateRange: dateRange,
                    colorSupportsAlpha: colorSupportsAlpha,
                    collectionReorderable: collectionReorderable,
                    collectionItemTitleKey: collectionItemTitleKey,
                    focusRequest: focusRequest,
                    labelIsUnknown: labelIsUnknown
                )
            }
            let content = registry.customLineItem(
                keyPath: keyPath,
                label: label,
                binding: value,
                defaultContent: defaultContent
            ) ?? defaultContent
            return AnyView(SBJEditorPropertyInfoContainer(content: content, propertyName: name, info: propertyInfo))
        }
        self.collectIssues = { root, path, registry in
            SBJValueEditor.collectIssues(
                value: root[keyPath: keyPath],
                path: path + [name],
                registry: registry,
                collectionItemTitleKey: collectionItemTitleKey
            )
        }
        self.matchesSearch = { root, query, registry in
            SBJValueEditor.matchesSearch(
                label: name,
                value: root[keyPath: keyPath],
                query: query,
                registry: registry,
                collectionItemTitleKey: collectionItemTitleKey
            )
        }
        self.hasChanged = { root, originalRoot in
            guard let originalRoot else { return true }
            return root[keyPath: keyPath].sbjEncodedIsDifferent(from: originalRoot[keyPath: keyPath])
        }
        self.hasContent = { root in
            (root[keyPath: keyPath] as? any HasContentCheckable)?.hasContent
        }
        self.containsEmptyContent = { root, registry in
            SBJValueEditor.containsEmptyContent(
                value: root[keyPath: keyPath],
                registry: registry
            )
        }
        self.validationError = { root in
            SBJInvariantCheck.validationError(
                root[keyPath: keyPath],
                at: SBJValidationKeyPath(keyPath)
            )
        }
    }

    /// Creates an editor field that is intentionally outside `Root`'s structural
    /// metadata. `Value` does not need to be `Codable`; the application may
    /// provide an exact-type editor through `SBJEditorRegistry`.
    public init<Value>(
        editorOnlyName name: String,
        _ keyPath: WritableKeyPath<Root, Value>
    ) {
        self.name = name
        self.validationKeyPath = keyPath
        self.participatesInStructuralValidation = false
        self.makeView = { root, originalRoot, registry, overrideName, focusRequest, labelIsUnknown in
            let defaultValue = Binding<Value>(
                get: { root.wrappedValue[keyPath: keyPath] },
                set: { root.wrappedValue[keyPath: keyPath] = $0 }
            )
            let value = registry.customBinding(keyPath: keyPath, root: root) ?? defaultValue
            let label = overrideName ?? name
            let defaultContent = SBJValueEditor.makeView(
                label: label,
                value: value,
                originalValue: originalRoot.map { SBJEditorOriginalValue($0[keyPath: keyPath]) },
                registry: registry,
                focusRequest: focusRequest,
                labelIsUnknown: labelIsUnknown
            )
            let content = registry.customLineItem(
                keyPath: keyPath,
                label: label,
                binding: value,
                defaultContent: defaultContent
            ) ?? defaultContent
            return AnyView(SBJEditorPropertyInfoContainer(content: content, propertyName: name, info: nil))
        }
        self.collectIssues = { _, _, _ in [] }
        self.matchesSearch = { _, query, _ in
            name.localizedCaseInsensitiveContains(query)
        }
        // Editor-only values have no structural encoding contract, so the
        // generic editor deliberately does not infer per-field change/content
        // state from them. The owning model may still track those changes.
        self.hasChanged = { _, _ in false }
        self.hasContent = { _ in nil }
        self.containsEmptyContent = { _, _ in false }
        self.validationError = { _ in nil }
    }

    func containsEmptyContent(
        root: Root,
        registry: SBJEditorRegistry
    ) -> Bool {
        containsEmptyContent(root, registry)
    }

    func issues(
        root: Root,
        path: [String],
        registry: SBJEditorRegistry
    ) -> [SBJEditorIssue] {
        var result = collectIssues(root, path, registry)
        if let error = validationError(root) {
            result.append(.validation(path: error.keyPath.description, message: error.localizedDescription))
        }
        return result
    }

    func view(
        root: Binding<Root>,
        originalRoot: Root? = nil,
        registry: SBJEditorRegistry,
        nameOverride: String? = nil,
        focusRequest: SBJEditorFocusRequest? = nil,
        labelIsUnknown: Bool = false
    ) -> AnyView {
        let changed = hasChanged(root.wrappedValue, originalRoot)
        let contentState = hasContent(root.wrappedValue)
        let rootValidationError = SBJInvariantCheck.validationError(
            root.wrappedValue,
            at: SBJValidationKeyPath(\Root.self)
        )
        let invalid = participatesInStructuralValidation && (
            validationError(root.wrappedValue) != nil ||
            (rootValidationError?.keyPath.contains(property: validationKeyPath) == true)
        )
        let content = makeView(root, originalRoot, registry, nameOverride, focusRequest, labelIsUnknown)
            .environment(\.sbjEditorIsChanged, changed)
            .environment(\.sbjEditorHasContent, contentState)
            .environment(\.sbjEditorIsInvalid, invalid)
            .sbjEditorValidationLineBackground(invalid)
        return AnyView(
            SBJEditorFilteredView(
                content: AnyView(content),
                isChanged: changed,
                matchesSearch: { query in
                    matchesSearch(root.wrappedValue, query, registry)
                },
                containsEmptyContent: {
                    containsEmptyContent(root.wrappedValue, registry)
                }
            )
        )
    }
}

@MainActor
struct SBJEditorFilteredView: View {
    let content: AnyView
    let isChanged: Bool
    let matchesSearch: (String) -> Bool
    let containsEmptyContent: () -> Bool
    @Environment(\.sbjEditorSearchQuery) private var query
    @Environment(\.sbjEditorShowChangedOnly) private var showChangedOnly
    @Environment(\.sbjEditorShowEmptyContentOnly) private var showEmptyContentOnly

    @ViewBuilder
    var body: some View {
        if (!showChangedOnly || isChanged) &&
            (!showEmptyContentOnly || containsEmptyContent()) &&
            (query.isEmpty || matchesSearch(query)) {
            content
        }
    }
}
