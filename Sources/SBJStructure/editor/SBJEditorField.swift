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

    public init<Value: Codable>(
        name: String,
        _ keyPath: WritableKeyPath<Root, Value>
    ) {
        self.name = name
        self.validationKeyPath = keyPath
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
            let value = Binding<Value>(
                get: { root.wrappedValue[keyPath: keyPath] },
                set: { root.wrappedValue[keyPath: keyPath] = $0 }
            )
            let originalValue = originalRoot.map { $0[keyPath: keyPath] }
            let label = overrideName ?? name
            let defaultContent = SBJValueEditor.makeView(
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
        let invalid = validationError(root.wrappedValue) != nil ||
            (rootValidationError?.keyPath.contains(property: validationKeyPath) == true)
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
