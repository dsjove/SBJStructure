import SwiftUI

/// Shared presentation state for the stock SwiftUI structured editor.
///
/// Keep this state in the client when hosting ``SBJEditorSearchView`` and
/// ``SBJEditorView`` separately. That lets the client choose its own scrolling,
/// form, toolbar, sheet, or inspector layout while both views share filters and
/// issue presentation.
public struct SBJEditorViewState: Equatable, Sendable {
    public var searchCriteria: SBJEditSearchCriteria
    public var isShowingIssues: Bool

    public init(
        searchCriteria: SBJEditSearchCriteria = .init(),
        isShowingIssues: Bool = false
    ) {
        self.searchCriteria = searchCriteria
        self.isShowingIssues = isShowingIssues
    }
}

/// The reflected editor content without search controls or a scrolling container.
///
/// The host owns layout and scrolling. Pair this with ``SBJEditorSearchView``
/// when the stock search/filter UI is desired.
public struct SBJEditorView<Value: SBJSwiftUIEditable>: View {
    @Binding private var value: Value
    @Binding private var state: SBJEditorViewState
    private let registry: SBJEditorRegistry
    @State private var originalValue: Value

    public init(
        value: Binding<Value>,
        state: Binding<SBJEditorViewState>,
        registry: SBJEditorRegistry = .init()
    ) {
        self._value = value
        self._state = state
        self.registry = registry
        self._originalValue = State(initialValue: value.wrappedValue.sbjCodableCopy())
    }

    private var rootSnapshot: [SBJEditorSnapshotItem<SBJEditorField<Value>>] {
        Value.sbjEditorFields.enumerated().compactMap { offset, field in
            guard field.isIncluded(
                root: value,
                originalRoot: originalValue,
                registry: registry,
                criteria: state.searchCriteria
            ) else { return nil }
            return SBJEditorSnapshotItem(
                itemIdentifier: SBJEditorItemIdentifier.root.appending("property:\(field.name)"),
                indexPath: SBJEditorIndexPath.root.appending("field:\(offset)"),
                content: field
            )
        }
    }

    public var body: some View {
        let rootValidation = SBJEditorRootValidationResult.computed(
            SBJInvariantCheck.validationError(
                value,
                at: SBJValidationKeyPath(\Value.self)
            )
        )

        VStack(alignment: .leading, spacing: 8) {
            ForEach(rootSnapshot) { item in
                let field = item.content
                field.view(
                    root: $value,
                    originalRoot: originalValue,
                    registry: registry,
                    context: SBJEditTraversalContext(
                        treeLevel: 0,
                        itemIdentifier: item.itemIdentifier,
                        indexPath: item.indexPath
                    ),
                    rootValidation: rootValidation,
                    applyFiltering: false
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.sbjEditorSearchCriteria, state.searchCriteria)
        .environment(\.sbjEditorShowIssues, {
            state.isShowingIssues = true
        })
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }
}

/// Stock search/filter controls for an ``SBJEditorView``.
///
/// This view deliberately does not own scrolling or editor content. Place it
/// wherever the client wants the controls to remain visible.
public struct SBJEditorSearchView<Value: SBJSwiftUIEditable>: View {
    private let value: Value
    @Binding private var state: SBJEditorViewState
    private let registry: SBJEditorRegistry
    @State private var cachedIssues: [SBJEditorIssue]?
    @State private var draftSearchText: String

    public init(
        value: Value,
        state: Binding<SBJEditorViewState>,
        registry: SBJEditorRegistry = .init()
    ) {
        self.value = value
        self._state = state
        self.registry = registry
        self._cachedIssues = State(initialValue: nil)
        self._draftSearchText = State(initialValue: state.wrappedValue.searchCriteria.searchQuery)
    }

    private func refreshIssuesAndShow() {
        cachedIssues = SBJEditorDiagnostics.issues(for: value, registry: registry)
        state.isShowingIssues = true
    }

    public var body: some View {
        SBJEditorSearchBar(
            searchText: $draftSearchText,
            criteria: $state.searchCriteria,
            hasIssues: cachedIssues.map { !$0.isEmpty },
            showIssues: refreshIssuesAndShow
        )
        .sheet(isPresented: $state.isShowingIssues) {
            SBJEditorIssueList(issues: cachedIssues ?? [])
        }
        // Keep keystrokes local to the search control. The potentially very
        // large editor tree only sees a new query after the user pauses, rather
        // than being invalidated and laid out for every character typed.
        .task(id: draftSearchText) {
            if draftSearchText.isEmpty {
                state.searchCriteria.searchQuery = ""
                return
            }

            do {
                try await Task.sleep(for: .milliseconds(180))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            state.searchCriteria.searchQuery = draftSearchText
        }
        .onChange(of: state.searchCriteria.searchQuery) { _, newValue in
            // Preserve programmatic changes made by a host without fighting
            // ordinary typing (which already has the same value after debounce).
            if newValue != draftSearchText {
                draftSearchText = newValue
            }
        }
    }
}

/// Reusable default composition for values annotated with ``SBJStructure()``.
///
/// This convenience view keeps search and editor content together but still
/// leaves scrolling to its host. Clients that need independent placement should
/// use ``SBJEditorSearchView`` and ``SBJEditorView`` directly.
public struct SBJCodableEditorCore<Value: SBJSwiftUIEditable>: View {
    @Binding private var value: Value
    private let registry: SBJEditorRegistry
    @State private var state = SBJEditorViewState()

    public init(
        value: Binding<Value>,
        registry: SBJEditorRegistry = .init()
    ) {
        self._value = value
        self.registry = registry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SBJEditorSearchView(value: value, state: $state, registry: registry)
            SBJEditorView(value: $value, state: $state, registry: registry)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Compatibility wrapper around ``SBJCodableEditorCore``.
public struct SBJCodableEditor<Value: SBJSwiftUIEditable>: View {
    @Binding private var value: Value
    private let registry: SBJEditorRegistry

    public init(
        _ title: String? = nil,
        value: Binding<Value>,
        registry: SBJEditorRegistry = .init()
    ) {
        self._value = value
        self.registry = registry
    }

    public var body: some View {
        SBJCodableEditorCore(value: $value, registry: registry)
    }
}
