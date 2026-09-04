import Foundation
import SwiftUI

@MainActor
struct SBJEditorItemActions {
    let remove: () -> Void
    let moveUp: (() -> Void)?
    let moveDown: (() -> Void)?

    var leadingView: AnyView {
        AnyView(
            Button(action: remove) {
                Image(SBJEditorImageName.remove)
                    .frame(minWidth: 22, minHeight: 22)
            }
            .buttonStyle(.borderless)
            .frame(minHeight: SBJEditorRowMetrics.firstLineMinimumHeight, alignment: .center)
            .accessibilityLabel("Remove item")
            .accessibilityHint("Removes this item from the collection")
        )
    }

    var trailingView: AnyView {
        guard moveUp != nil || moveDown != nil else {
            return AnyView(EmptyView())
        }
        return AnyView(
            HStack(spacing: 6) {
                Button {
                    moveUp?()
                } label: {
                    Image(SBJEditorImageName.moveUp)
                }
                .buttonStyle(.borderless)
                .disabled(moveUp == nil)
                .accessibilityLabel("Move item up")
                .accessibilityHint("Moves this item one position earlier")

                Button {
                    moveDown?()
                } label: {
                    Image(SBJEditorImageName.moveDown)
                }
                .buttonStyle(.borderless)
                .disabled(moveDown == nil)
                .accessibilityLabel("Move item down")
                .accessibilityHint("Moves this item one position later")
            }
            .frame(minHeight: SBJEditorRowMetrics.firstLineMinimumHeight, alignment: .center)
        )
    }
}

@MainActor
final class SBJEditorFocusRequest {
    private var claimed = false

    func claim() -> Bool {
        guard !claimed else { return false }
        claimed = true
        return true
    }
}

