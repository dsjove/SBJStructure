import SwiftUI

/// Shared disclosure row used by the generated editor.
///
/// Disclosure, element actions, state indicators, title content and trailing
/// actions occupy explicit semantic lanes.  Controls are aligned to the first
/// row, so expanding a multiline/compound value never shifts their vertical
/// position.
struct SBJEditorDisclosureHeader: View {
    let title: String
    let treeLevel: Int
    @Binding var isExpanded: Bool
    let leadingActions: AnyView
    let optionalControl: AnyView?
    let trailingActions: AnyView
    let infoAction: AnyView?
    let titleIsUnknown: Bool
    let titleContent: AnyView?

    init(
        _ title: String,
        treeLevel: Int = 0,
        isExpanded: Binding<Bool>,
        leadingActions: AnyView = AnyView(EmptyView()),
        optionalControl: AnyView? = nil,
        trailingActions: AnyView = AnyView(EmptyView()),
        infoAction: AnyView? = nil,
        titleIsUnknown: Bool = false,
        titleContent: AnyView? = nil
    ) {
        self.title = title
        self.treeLevel = treeLevel
        self._isExpanded = isExpanded
        self.leadingActions = leadingActions
        self.optionalControl = optionalControl
        self.trailingActions = trailingActions
        self.infoAction = infoAction
        self.titleIsUnknown = titleIsUnknown
        self.titleContent = titleContent
    }

    var body: some View {
        SBJEditorRow(
            treeLevel: treeLevel,
            disclosureControl: AnyView(disclosureButton),
            elementAction: leadingActions,
            optionalControl: optionalControl,
            trailingActions: trailingActions,
            infoAction: infoAction
        ) {
            if let titleContent {
                titleContent
                    .frame(
                        maxWidth: .infinity,
                        minHeight: SBJEditorRowMetrics.firstLineHeight,
                        alignment: .leading
                    )
            } else {
                Button(action: toggle) {
                    HStack(spacing: 8) {
                        if titleIsUnknown {
                            Text(title)
                                .fontWeight(.semibold)
                                .italic()
                        } else {
                            Text(title)
                                .fontWeight(.semibold)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(
                        maxWidth: .infinity,
                        minHeight: SBJEditorRowMetrics.firstLineHeight,
                        alignment: .leading
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .contentShape(Rectangle())
    }

    private var disclosureButton: some View {
        Button(action: toggle) {
            Image(.system(isExpanded ? "chevron.down" : "chevron.right"))
                .font(.caption.weight(.semibold))
                .frame(width: 22, height: 22)
                .overlay(
                    Circle()
                        .stroke(.secondary.opacity(0.55), lineWidth: 1)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isExpanded ? "Collapse \(title)" : "Expand \(title)")
    }

    private func toggle() {
        var transaction = Transaction(animation: nil)
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            isExpanded.toggle()
        }
    }
}
