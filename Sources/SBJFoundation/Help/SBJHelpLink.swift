#if !os(watchOS)
import SwiftUI

/// Standard SwiftUI help entry point backed by SBJFoundation's help system.
///
/// The view accepts a finished `SBJAssetReference`
/// instead of mirroring every resource-storage constructor.
@MainActor
public struct SBJHelpLink: View {
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
            nativeOrFallbackHelpLink(action: action)
        }
    }

    @ViewBuilder
    private func nativeOrFallbackHelpLink(action: @escaping () -> Void) -> some View {
        #if os(macOS) && !targetEnvironment(macCatalyst)
        HelpLink(action: action)
        #else
        SBJImageButton(
            SBJSemanticImageReference.help,
            accessibilityLabel: "Help",
            action: action
        )
        #endif
    }
}
#endif
