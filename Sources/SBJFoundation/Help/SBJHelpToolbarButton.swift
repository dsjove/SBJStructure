#if !os(watchOS)
import SwiftUI

/// Toolbar-safe Help control for layouts where SwiftUI must be free to relocate
/// toolbar items between horizontal and vertical system chrome.
///
/// `SBJHelpLink` is the ordinary semantic Help entry point and may use native
/// `HelpLink`/shared compact-button presentation. `SBJHelpToolbarButton` instead
/// deliberately presents as a plain SwiftUI `Button` with a `Label`. Keeping the
/// visible control structurally ordinary lets the system participate fully in
/// toolbar collapsing and relocation (for example, onto iPhone Duo's vertical
/// toolbar) while still using SBJFoundation's single Help presentation pipeline.
///
/// Use this type only when the *placement behavior* of a toolbar item matters.
/// Help content, automatic presentation, About handling, substitutions, and
/// custom presenters remain owned by `SBJHelpTrigger`/`SBJHelpSheet`.
@MainActor
public struct SBJHelpToolbarButton: View {
    public let asset: SBJAssetReference
    public let auto: Bool
    public let substitutions: [String: String]
    public let configuration: SBJHelpConfiguration
    public let showAbout: Bool
    public let presenter: SBJAnyHelpContentPresenter?

    public init(
        asset: SBJAssetReference,
        auto: Bool = false,
        substitutions: [String: String] = [:],
        configuration: SBJHelpConfiguration = .standard,
        showAbout: Bool = true,
        presenter: SBJAnyHelpContentPresenter? = nil
    ) {
        self.asset = asset
        self.auto = auto
        self.substitutions = substitutions
        self.configuration = configuration
        self.showAbout = showAbout
        self.presenter = presenter
    }

    public var body: some View {
        SBJHelpTrigger(
            asset: asset,
            auto: auto,
            substitutions: substitutions,
            configuration: configuration,
            showAbout: showAbout,
            presenter: presenter
        ) { action in
            Button(action: action) {
                Label("Help", image: SBJSemanticImageReference.help)
                    .labelStyle(.iconOnly)
            }
            .accessibilityLabel("Help")
        }
    }
}
#endif
