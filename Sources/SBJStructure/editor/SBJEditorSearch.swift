import SwiftUI

private struct SBJEditorSearchQueryKey: EnvironmentKey {
    static let defaultValue = ""
}

extension EnvironmentValues {
    var sbjEditorSearchQuery: String {
        get { self[SBJEditorSearchQueryKey.self] }
        set { self[SBJEditorSearchQueryKey.self] = newValue }
    }
}

//TODO: allow the search field to not be scrollable

@MainActor
struct SBJEditorSearchBar: View {
    @Binding var text: String
    @Binding var showChangedOnly: Bool
    @Binding var showEmptyContentOnly: Bool
    let hasIssues: Bool
    let showIssues: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            SearchField(searching: $text)
            Button {
                showChangedOnly.toggle()
            } label: {
                Image(.system("line.3.horizontal.decrease.circle"))
                    .foregroundStyle(showChangedOnly ? Color.white : Color.secondary)
                    .frame(width: 28, height: 28)
                    .background {
                        if showChangedOnly {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor)
                        }
                    }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(showChangedOnly ? "Show all values" : "Show changed values only")

            Button {
                showEmptyContentOnly.toggle()
            } label: {
                Image(.system("circle"))
                    .foregroundStyle(showEmptyContentOnly ? Color.white : Color.secondary)
                    .frame(width: 28, height: 28)
                    .background {
                        if showEmptyContentOnly {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accentColor)
                        }
                    }
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(showEmptyContentOnly ? "Show all values" : "Show values with no content only")


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
