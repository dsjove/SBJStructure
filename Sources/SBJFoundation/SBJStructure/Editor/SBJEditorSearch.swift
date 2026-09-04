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
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor

    var body: some View {
        HStack(spacing: 8) {
            SearchField(searching: $searchText)
            Button {
                criteria.showChangedOnly.toggle()
            } label: {
                HStack(spacing: 4) {
                    if differentiateWithoutColor && criteria.showChangedOnly {
                        Image(SBJEditorImageName.selected)
                            .font(.caption.weight(.semibold))
                    }
                    SBJEditorStatusSymbol(kind: .changed)
                    Text("Changed")
                        .font(.caption)
                }
                .foregroundStyle(criteria.showChangedOnly ? SBJUIAppearance.activeControlForegroundColor : SBJUIAppearance.inactiveControlColor)
                .padding(.horizontal, 7)
                .frame(minHeight: 28)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(criteria.showChangedOnly ? SBJUIAppearance.activeControlColor : Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            criteria.showChangedOnly ? SBJUIAppearance.activeControlColor : SBJUIAppearance.subtleStrokeColor(colorSchemeContrast),
                            lineWidth: SBJUIAppearance.borderThickness(colorSchemeContrast)
                        )
                }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showChangedOnly ? "Show all values" : "Show changed values only")

            Button {
                criteria.showEmptyContentOnly.toggle()
            } label: {
                HStack(spacing: 4) {
                    if differentiateWithoutColor && criteria.showEmptyContentOnly {
                        Image(SBJEditorImageName.selected)
                            .font(.caption.weight(.semibold))
                    }
                    SBJEditorStatusSymbol(kind: .empty)
                    Text("Empty")
                        .font(.caption)
                }
                .foregroundStyle(criteria.showEmptyContentOnly ? SBJUIAppearance.activeControlForegroundColor : SBJUIAppearance.inactiveControlColor)
                .padding(.horizontal, 7)
                .frame(minHeight: 28)
                .background {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(criteria.showEmptyContentOnly ? SBJUIAppearance.activeControlColor : Color.clear)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            criteria.showEmptyContentOnly ? SBJUIAppearance.activeControlColor : SBJUIAppearance.subtleStrokeColor(colorSchemeContrast),
                            lineWidth: SBJUIAppearance.borderThickness(colorSchemeContrast)
                        )
                }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(criteria.showEmptyContentOnly ? "Show all values" : "Show values with no content only")

            Button(action: showIssues) {
                Image(SBJEditorImageName.issues(filled: hasIssues == true))
                    .foregroundStyle(hasIssues == true ? SBJUIAppearance.issueColor : SBJUIAppearance.inactiveControlColor)
                    .frame(minWidth: 28, minHeight: 28)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(hasIssues == nil ? "Check editor issues" : "Show editor issues")
        }
    }
}
