#if !os(watchOS) && canImport(UIKit)
import SwiftUI

/// Semantic share control for content whose activity representation is
/// expensive or must remain stable for the full system share interaction.
///
/// The presenter is an explicit dependency. `prepare` runs exactly once for an
/// accepted user action, and the presenter retains that exact payload until the
/// activity controller dismisses.
@MainActor
public struct SBJShareButton<Label: View>: View {
    @ObservedObject private var presenter: SBJSharePresenter

    private let prepare: @MainActor () -> SBJSharePayload
    private let onPresent: (@MainActor () -> Void)?
    private let onDismiss: (@MainActor @Sendable () -> Void)?
    private let label: () -> Label

    public init(
        presenter: SBJSharePresenter,
        prepare: @escaping @MainActor () -> SBJSharePayload,
        onPresent: (@MainActor () -> Void)? = nil,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil,
        @ViewBuilder label: @escaping () -> Label
    ) {
        _presenter = ObservedObject(wrappedValue: presenter)
        self.prepare = prepare
        self.onPresent = onPresent
        self.onDismiss = onDismiss
        self.label = label
    }

    public var body: some View {
        Button {
            guard !presenter.isPresenting else { return }
            let payload = prepare()
            guard presenter.present(payload, onDismiss: onDismiss) else { return }
            onPresent?()
        } label: {
            label()
        }
        .disabled(presenter.isPresenting)
    }
}

public extension SBJShareButton where Label == SwiftUI.Label<Text, Image> {
    init(
        _ title: LocalizedStringKey,
        presenter: SBJSharePresenter,
        prepare: @escaping @MainActor () -> SBJSharePayload,
        onPresent: (@MainActor () -> Void)? = nil,
        onDismiss: (@MainActor @Sendable () -> Void)? = nil
    ) {
        self.init(
            presenter: presenter,
            prepare: prepare,
            onPresent: onPresent,
            onDismiss: onDismiss
        ) {
            Label(title, image: SBJSemanticImageReference.share)
                //.labelStyle(.titleAndIcon)
        }
    }
}
#endif
