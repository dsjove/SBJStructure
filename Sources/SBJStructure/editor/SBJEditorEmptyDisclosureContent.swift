import SwiftUI

/// Understated explanatory content for a disclosure that is open but has no
/// visible editor rows beneath its header.
struct SBJEditorEmptyDisclosureContent: View {
    let message: String

    var body: some View {
        Text(message)
            .italic()
            .foregroundStyle(.secondary)
            .frame(
                maxWidth: .infinity,
                minHeight: SBJEditorRowMetrics.firstLineHeight,
                alignment: .leading
            )
    }
}
