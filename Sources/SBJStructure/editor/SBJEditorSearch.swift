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
    @Binding var criteria: SBJEditSearchCriteria
    let hasIssues: Bool?
    let showIssues: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            SearchField(searching: $criteria.searchQuery)
            Button {
                criteria.showChangedOnly.toggle()
            } label: {
                HStack(spacing: 4) {
                    SBJEditorStatusSymbol(kind: .changed)
                    Text("Changed")
                        .font(.caption)
                }
                .foregroundStyle(criteria.showChangedOnly ? Color.white : Color.secondary)
                .padding(.horizontal, 7)
                .frame(height: 28)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(criteria.showChangedOnly ? Color.accentColor : Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            criteria.showChangedOnly ? Color.accentColor : Color.secondary.opacity(0.55),
                            lineWidth: 1
                        )
                }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showChangedOnly ? "Show all values" : "Show changed values only")

            Button {
                criteria.showEmptyContentOnly.toggle()
            } label: {
                HStack(spacing: 4) {
                    SBJEditorStatusSymbol(kind: .empty)
                    Text("Empty")
                        .font(.caption)
                }
                .foregroundStyle(criteria.showEmptyContentOnly ? Color.white : Color.secondary)
                .padding(.horizontal, 7)
                .frame(height: 28)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(criteria.showEmptyContentOnly ? Color.accentColor : Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            criteria.showEmptyContentOnly ? Color.accentColor : Color.secondary.opacity(0.55),
                            lineWidth: 1
                        )
                }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showEmptyContentOnly ? "Show all values" : "Show values with no content only")

            Button(action: showIssues) {
                Image(.system(hasIssues == true ? "exclamationmark.circle.fill" : "exclamationmark.circle"))
                    .foregroundStyle(hasIssues == true ? Color.red : Color.secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(hasIssues == nil ? "Check editor issues" : "Show editor issues")
        }
    }
}
