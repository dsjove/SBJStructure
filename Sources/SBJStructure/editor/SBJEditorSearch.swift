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

//TODO: allow the search field to not be scrollable

@MainActor
struct SBJEditorSearchBar: View {
    @Binding var criteria: SBJEditSearchCriteria
    let hasIssues: Bool
    let showIssues: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            SearchField(searching: $criteria.searchQuery)
            Button {
                criteria.showChangedOnly.toggle()
            } label: {
                Image(.system("line.3.horizontal.decrease.circle"))
                    .foregroundStyle(criteria.showChangedOnly ? Color.white : Color.secondary)
                    .frame(width: 28, height: 28)
                    .background {
                        if criteria.showChangedOnly {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor)
                        }
                    }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showChangedOnly ? "Show all values" : "Show changed values only")

            Button {
                criteria.showEmptyContentOnly.toggle()
            } label: {
                Image(.system("circle"))
                    .foregroundStyle(criteria.showEmptyContentOnly ? Color.white : Color.secondary)
                    .frame(width: 28, height: 28)
                    .background {
                        if criteria.showEmptyContentOnly {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor)
                        }
                    }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showEmptyContentOnly ? "Show all values" : "Show values with no content only")

            if hasIssues {
                Button(action: showIssues) {
                    Image(.system("exclamationmark.circle.fill"))
                        .foregroundStyle(.red)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Show editor issues")
            }
        }
    }
}
