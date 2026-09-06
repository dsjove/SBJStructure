import SwiftUI

private struct SBJEditorSearchCriteriaKey: EnvironmentKey {
    static let defaultValue = SBJEditSearchCriteria()
}

extension EnvironmentValues {
    var sbjEditorSearchCriteria: SBJEditSearchCriteria {
        get { self[SBJEditorSearchCriteriaKey.self] }
        set { self[SBJEditorSearchCriteriaKey.self] = newValue }
    }
}

@MainActor
struct SBJEditorSearchBar: View {
    @Binding var searchText: String
    @Binding var criteria: SBJEditSearchCriteria
    let hasIssues: Bool?
    let showIssues: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            SearchField(searching: $searchText)
            SBJToggleButton(
                "Changed",
                isOn: $criteria.showChangedOnly,
                accessibilityLabel: criteria.showChangedOnly ? "Show all values" : "Show changed values only"
            ) {
                SBJEditorStatusSymbol(kind: .changed)
            }

            SBJToggleButton(
                "Empty",
                isOn: $criteria.showEmptyContentOnly,
                accessibilityLabel: criteria.showEmptyContentOnly ? "Show all values" : "Show values with no content only"
            ) {
                SBJEditorStatusSymbol(kind: .empty)
            }

            SBJIssueButton(
                hasIssues: hasIssues,
                accessibilityLabel: hasIssues == nil ? "Check issues" : "Show issues",
                action: showIssues
            )
        }
    }
}
