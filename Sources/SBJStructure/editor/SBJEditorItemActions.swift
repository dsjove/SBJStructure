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
                Image(.system("minus.circle"))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .frame(minHeight: SBJEditorRowMetrics.firstLineHeight, alignment: .center)
            .accessibilityLabel("Remove item")
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
                    Image(.system("arrow.up.circle"))
                }
                .buttonStyle(.borderless)
                .disabled(moveUp == nil)
                .accessibilityLabel("Move item up")

                Button {
                    moveDown?()
                } label: {
                    Image(.system("arrow.down.circle"))
                }
                .buttonStyle(.borderless)
                .disabled(moveDown == nil)
                .accessibilityLabel("Move item down")
            }
            .frame(minHeight: SBJEditorRowMetrics.firstLineHeight, alignment: .center)
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

