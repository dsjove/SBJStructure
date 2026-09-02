import SwiftUI

/// Reusable editor body for values annotated with ``SBJStructure()``.
///
/// This view owns only editor behavior. Application navigation, presentation,
/// restore/done buttons, and other window/sheet chrome belong outside it.
public struct SBJCodableEditorCore<Value: SBJSwiftUIEditable>: View {
    @Binding private var value: Value
    private let registry: SBJEditorRegistry
    @State private var isShowingIssues = false
    @State private var searchCriteria = SBJEditSearchCriteria()
    @State private var effectiveSearchText = ""
    @State private var originalValue: Value

    public init(
        value: Binding<Value>,
        registry: SBJEditorRegistry = .init()
    ) {
        self._value = value
        self.registry = registry
        self._originalValue = State(initialValue: value.wrappedValue.sbjCodableCopy())
    }


    private var effectiveSearchCriteria: SBJEditSearchCriteria {
        var criteria = searchCriteria
        criteria.searchQuery = effectiveSearchText
        return criteria
    }

    private var issues: [SBJEditorIssue] {
        SBJEditorDiagnostics.issues(for: value, registry: registry)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SBJEditorSearchBar(
                criteria: $searchCriteria,
                hasIssues: !issues.isEmpty,
                showIssues: { isShowingIssues = true }
            )

            ForEach(Array(Value.sbjEditorFields.enumerated()), id: \.offset) { _, field in
                field.view(root: $value, originalRoot: originalValue, registry: registry, context: .root)
            }
        }
        .environment(\.sbjEditorSearchCriteria, effectiveSearchCriteria)
        .task(id: searchCriteria.searchQuery) {
            if searchCriteria.searchQuery.isEmpty {
                effectiveSearchText = ""
                return
            }

            do {
                try await Task.sleep(for: .milliseconds(150))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            effectiveSearchText = searchCriteria.searchQuery
        }
        .environment(\.sbjEditorShowIssues, {
            isShowingIssues = true
        })
        .sheet(isPresented: $isShowingIssues) {
            SBJEditorIssueList(issues: issues)
        }
        .transaction { transaction in
            transaction.animation = nil
            transaction.disablesAnimations = true
        }
    }
}

/// Compatibility wrapper around ``SBJCodableEditorCore``.
///
/// Existing clients can keep using `SBJCodableEditor`; new code that wants to
/// make the editor/shell separation explicit can use `SBJCodableEditorCore`.
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
