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
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(spacing: 8) {
            SearchField(searching: $searchText)
            Button {
                criteria.showChangedOnly.toggle()
            } label: {
                HStack(spacing: 4) {
                    if differentiateWithoutColor && criteria.showChangedOnly {
                        Image(SBJSemanticImageName.selected)
                            .font(.caption.weight(.semibold))
                    }
                    SBJEditorStatusSymbol(kind: .changed)
                    Text("Changed")
                        .font(.caption)
                }
                .sbjActiveControl(isSelected: criteria.showChangedOnly, verticalPadding: 0)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showChangedOnly ? "Show all values" : "Show changed values only")

            Button {
                criteria.showEmptyContentOnly.toggle()
            } label: {
                HStack(spacing: 4) {
                    if differentiateWithoutColor && criteria.showEmptyContentOnly {
                        Image(SBJSemanticImageName.selected)
                            .font(.caption.weight(.semibold))
                    }
                    SBJEditorStatusSymbol(kind: .empty)
                    Text("Empty")
                        .font(.caption)
                }
                .sbjActiveControl(isSelected: criteria.showEmptyContentOnly, verticalPadding: 0)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showEmptyContentOnly ? "Show all values" : "Show values with no content only")

            SBJIssueButton(
                hasIssues: hasIssues,
                accessibilityLabel: hasIssues == nil ? "Check issues" : "Show issues",
                action: showIssues
            )
        }
    }
}
