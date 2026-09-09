#if !os(watchOS)
import SwiftUI
import Foundation
import UniformTypeIdentifiers

/// Standard SwiftUI help entry point backed by SBJFoundation's help system.
///
/// SwiftUI's native `HelpLink` is used on platforms where Apple makes it
/// available. iOS, including Mac Catalyst, uses the same semantic help action
/// through SBJFoundation's shared UI vocabulary instead.
@MainActor
public struct SBJHelpLink: View {
    public let asset: SBJHelpAsset
    public let auto: Bool
    public let substitutions: [String: String]
    public let configuration: SBJHelpConfiguration
    public let showAbout: Bool
    public let presenter: SBJAnyHelpContentPresenter?

    public init(
        _ title: String,
        folder: String = "help",
        bundle: Bundle = .main,
        contentType: UTType? = nil,
        auto: Bool = false,
        substitutions: [String: String] = [:],
        configuration: SBJHelpConfiguration = .standard,
        showAbout: Bool = true,
        presenter: SBJAnyHelpContentPresenter? = nil
    ) {
        self.init(
            asset: SBJHelpAsset(
                title: title,
                folder: folder,
                bundle: bundle,
                contentType: contentType
            ),
            auto: auto,
            substitutions: substitutions,
            configuration: configuration,
            showAbout: showAbout,
            presenter: presenter
        )
    }

    public init(
        _ title: String,
        folder: String = "help",
        bundle: Bundle = .main,
        filenameExtension: String,
        auto: Bool = false,
        substitutions: [String: String] = [:],
        configuration: SBJHelpConfiguration = .standard,
        showAbout: Bool = true,
        presenter: SBJAnyHelpContentPresenter? = nil
    ) {
        self.init(
            asset: SBJHelpAsset(
                title: title,
                folder: folder,
                bundle: bundle,
                filenameExtension: filenameExtension
            ),
            auto: auto,
            substitutions: substitutions,
            configuration: configuration,
            showAbout: showAbout,
            presenter: presenter
        )
    }

    public init(
        asset: SBJHelpAsset,
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
