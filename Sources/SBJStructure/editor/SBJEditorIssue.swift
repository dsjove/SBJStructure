import Foundation

public enum SBJEditorIssueKind: Hashable {
    case unsupported
    case validation
}

public typealias SBJEditorIssue = SBJIssue<SBJEditorIssueKind>

public extension SBJIssue where Kind == SBJEditorIssueKind {
    init(path: String, typeName: String, valueDescription: String?, kind: Kind = .unsupported) {
        self.init(kind: kind, path: path, typeName: typeName, valueDescription: valueDescription)
    }

    static func validation(path: String, message: String) -> Self {
        .init(path: path, typeName: "Validation", valueDescription: message, kind: .validation)
    }
}

/// Editor diagnostics add editor-capability issues to UI-independent structure diagnostics.
public enum SBJEditorDiagnostics {
    @MainActor
    public static func issues<Value: SBJEditable>(
        for value: Value,
        registry: SBJEditorRegistry = .init()
    ) -> [SBJEditorIssue] {
        var collection = SBJIssueCollection<SBJEditorIssue>()
        collection.append(contentsOf: Value.sbjEditorFields.flatMap { field in
            field.issues(root: value, path: [], registry: registry)
        })
        collection.append(contentsOf: SBJStructureDiagnostics.issues(for: value).map { issue in
            SBJEditorIssue(
                path: issue.path,
                typeName: issue.typeName,
                valueDescription: issue.valueDescription,
                kind: .validation
            )
        })
        return SBJEditorIssue.removingRedundantIssues(from: collection.uniqued { $0 })
    }
}

import SwiftUI

private struct SBJEditorShowIssuesKey: EnvironmentKey {
    static let defaultValue: @MainActor () -> Void = {}
}

extension EnvironmentValues {
    var sbjEditorShowIssues: @MainActor () -> Void {
        get { self[SBJEditorShowIssuesKey.self] }
        set { self[SBJEditorShowIssuesKey.self] = newValue }
    }
}

public struct SBJEditorIssueList: View {
    public let issues: [SBJEditorIssue]

    public init(issues: [SBJEditorIssue]) { self.issues = issues }
    @Environment(\.dismiss) private var dismiss

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(issues) { issue in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(issue.path).fontWeight(.semibold)
                            Text(issue.typeName).foregroundStyle(.secondary)
                            if let valueDescription = issue.valueDescription {
                                Text(valueDescription).italic().foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        if issue.id != issues.last?.id { Divider() }
                    }
                }
                .padding()
            }
            .navigationTitle("Editor Issues")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
