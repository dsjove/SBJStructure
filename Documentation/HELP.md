# Help System

SBJFoundation owns the reusable application help system. Every SBJ application can use the same
resource lookup, token expansion, presentation chrome, About behavior, and first-use presentation
without depending on SBJKit. SBJKit retains only source-compatible adapters for older applications.

## Design goals

- Preserve the existing asset-catalog HTML help authored by SBJ applications.
- Preserve the historical template-token contract, including application metadata and embedded
  SF Symbol/application-asset images.
- Treat About as a help resource and keep its entry point in the help presentation toolbar.
- Use Apple's semantic content-type system rather than a parallel help-format enumeration.
- Keep the sheet/chrome independent of the content presenter so new formats can be added later.
- Use native SwiftUI help UI when the target SDK provides it, while retaining the same behavior on
  iOS and Mac Catalyst where `SwiftUI.HelpLink` is unavailable.
- Keep reusable help imagery in SBJFoundation's shared UI vocabulary.

## Source organization

`Sources/SBJFoundation/Help/` contains:

- `SBJHelpAsset` — help content stored either in an asset-catalog data set or as a normal bundled resource, plus its `UTType`.
- `SBJHelpTemplateRenderer` — standard and caller token expansion.
- `SBJHelpDocument` — loaded, expanded content ready for presentation.
- `SBJHelpContentPresenter` / `SBJAnyHelpContentPresenter` — format-specific presentation boundary.
- `SBJHTMLHelpPresenter` — WebKit presentation for existing HTML help.
- `SBJMarkdownHelpPresenter` — native SwiftUI presentation for Markdown help.
- `SBJHelpSheet` — shared navigation chrome, About entry point, and presenter dispatch.
- `SBJHelpTrigger` — sheet and first-use presentation behavior.
- `SBJHelpLink` — standard entry control for new application code.
- `SBJHelpConfiguration` — application metadata, About/style resources, and shared substitutions.

## Content types

Help formats are identified by `UniformTypeIdentifiers.UTType`; SBJFoundation does not define a
parallel `SBJHelpFormat` enumeration or identifier namespace.

For asset-catalog data sets, `SBJHelpAsset` normally reads the uniform type identifier from
`NSDataAsset.typeIdentifier`. The asset catalog therefore remains the authority for the
representation of a data asset. An explicit `UTType` override is available for generic data sets,
and an initializer accepting a filename extension resolves that extension through
`UTType(filenameExtension:)`.

`SBJHelpAsset` can also address an ordinary file resource in any bundle. This is the preferred way
for a Swift package to ship reusable help because the package owns the text and can expose a stable
semantic asset without requiring the host application to duplicate an asset-catalog data set.

```swift
let automatic = SBJHelpAsset(title: "Recipe Details")
let explicitHTML = SBJHelpAsset(title: "Recipe Details", contentType: .html)
let markdown = SBJHelpAsset(title: "Recipe Details", filenameExtension: "md")
```

The explicit content type takes precedence over the asset catalog identifier.

## Framework-bundled and embedded help

SBJFoundation ships help for its generated structure editor as `SBJHelpAsset.structureEditor`. An
application can present that resource exactly like application-owned help:

```swift
SBJHelpLink(asset: .structureEditor)
```

Reusable help can also be composed into an application's larger topic.
`SBJHelpConfiguration.embeddedAssets` maps template tokens to help assets. The standard
configuration maps `SBJ_STRUCTURE_EDITOR_HELP` to `.structureEditor`. When that token occurs in an
application HTML help document, `SBJHelpTemplateRenderer` recursively renders the framework help
and substitutes it into the parent document. This lets an application surround framework help
with app-specific context while keeping the shared instructions authoritative in SBJFoundation.

Embedding is deliberately generic: applications and future frameworks may add their own named
embedded assets to the configuration. Recursive inclusion is guarded against by resource identity.

## Presenter dispatch and extension

The built-in presenter registry supports HTML and Markdown. Presenter selection uses the asset's
resolved `UTType`; a presenter may also be supplied explicitly.

A future format does not require a change to `SBJHelpAsset` or `SBJHelpSheet`. Define or obtain an
appropriate `UTType`, conform a presenter to `SBJHelpContentPresenter`, and pass its type-erased
form where help is presented.

```swift
struct PlainTextHelpPresenter: SBJHelpContentPresenter {
    let contentType: UTType = .plainText

    @MainActor
    func makeView(document: SBJHelpDocument) -> AnyView {
        AnyView(ScrollView { Text(document.source).padding() })
    }
}
```

This boundary is intentionally representation-focused: shared navigation, About, automatic
first-use behavior, and token expansion do not belong to individual presenters.

## HTML help and template tokens

HTML remains a first-class format because existing applications have substantial authored content.
`SBJHTMLHelpPresenter` uses `WKWebView`; there is no requirement to rewrite existing help.

`SBJHelpTemplateRenderer` preserves the established substitutions:

- `TITLE`
- `DISPLAY_NAME`
- `VERSION`
- `COMPANY_NAME`
- `EMAIL`
- `ICON`
- `STYLE_SHEET`
- `SF_<symbol>\\` for SF Symbol images
- `AS_<asset>\\` for application asset images

Configuration substitutions are applied after standard substitutions, and per-presentation caller
substitutions are applied last. Later values therefore override earlier values, matching the legacy
SBJKit behavior.

SF Symbol and application-asset token rasterization remains HTML-renderer work because those
values become embedded image data inside the HTML document. UI controls surrounding the document
do not hard-code symbol strings; they use `SBJSemanticImageReference`.

## Markdown help

Markdown data assets use `SBJMarkdownHelpPresenter`. Template substitutions occur before Markdown
parsing, so standard and caller tokens work for Markdown as well as HTML. The presenter converts
the expanded source to `AttributedString` and displays it in a native SwiftUI scroll view.

Markdown is additive. It does not replace HTML and does not change the legacy asset convention.

## Help entry control and Mac Catalyst

`SBJHelpLink` is the semantic help entry point for new code. It always routes into the same
SBJFoundation trigger, sheet, and presenter pipeline.

Where `SwiftUI.HelpLink` is available, `SBJHelpLink` uses it. The SwiftUI API is explicitly
unavailable in the iOS SDK, and Mac Catalyst compiles against that SDK surface. On iOS and Catalyst,
`SBJHelpLink` therefore uses an `SBJImageButton` with `SBJSemanticImageReference.help` as the
platform fallback. This is a presentation fallback only; help behavior and content are identical.

The platform conditional must remain compile-time. Referencing `SwiftUI.HelpLink` in an iOS or
Catalyst code path is a compile error even if guarded only by a runtime availability check.

## Shared UI vocabulary

Help-owned UI symbols are semantic entries in `SBJSemanticImageReference`, including Help, About,
Dismiss, unavailable/unsupported help, page down, and scroll-to-top. Help views consume those
references through `Image`, `Label`, or `SBJImageButton` rather than embedding raw SF Symbol names.

The HTML `SF_...\\` token mechanism is intentionally different: those symbol names are authored
content embedded in existing HTML and are resolved by the HTML template renderer.

## About

About is a help resource, not a separate application workflow. `SBJHelpConfiguration.aboutAsset`
defaults to the `help/About` HTML asset and uses the same lookup, token expansion, presenter, and
sheet implementation as ordinary help. When present, About appears in the help sheet toolbar.

This convention deliberately gives every application a consistent location for About/version/
support information without requiring each app to allocate another navigation destination.

## Automatic first-use presentation

`SBJHelpTrigger` preserves the legacy `auto` behavior. Presentation history is keyed by the help
asset's stable `fullName` and stored in `UserDefaults`. About can independently use the same
mechanism through `SBJHelpConfiguration.autoPresentAbout`.

## Legacy SBJKit compatibility

Existing applications may continue using SBJKit's `AssetPath`, `HelpButton`, and `HelpSheet`.
Those types are adapters only. `AssetPath` explicitly marks legacy resources as HTML and translates
the original bundle/folder convention into `SBJHelpAsset`; presentation and rendering remain in
SBJFoundation.

New applications should use the SBJFoundation help API directly.

## Testing contract

`Tests/SBJFoundationTests/Help/SBJHelpTests.swift` protects the semantic boundary rather than
snapshotting Apple UI. It verifies:

- filename-extension to `UTType` resolution;
- explicit content-type precedence over an asset catalog identifier;
- asset-catalog type-identifier resolution;
- the asset-catalog sanitized path convention;
- Foundation bundle-resource loading and content-type inference;
- bundled structure-editor help availability;
- recursive embedded-help expansion;
- built-in HTML/Markdown presenter selection;
- construction of `SBJHelpLink` on the current target (important for Catalyst compilation);
- use of shared semantic image references for Help UI.

Apple's own `HelpLink`, WebKit, and SwiftUI rendering behavior are not duplicated in unit tests.

## Semantic image tokens

HTML help can use `UI_name\` tokens for controls that are part of the shared UI vocabulary. For example, `UI_help\`, `UI_restore\`, `UI_add\`, and `UI_moveUp\` render the same imagery used by the SwiftUI controls. Applications may add or replace entries through `SBJHelpConfiguration.semanticImages`. Raw `SF_symbol.name\` and `AS_assetName\` tokens remain available for help-specific imagery.

## Application icon

The standard `ICON` token first uses `SBJHelpConfiguration.applicationIcon`. Its default is a main-bundle image asset named `HelpIcon`, which is useful because application icon sets are not reliably loadable as ordinary images on every UIKit/Catalyst configuration. If `HelpIcon` is absent, Help also tries the bundle's application-icon metadata.

## Bundled Foundation help

`SBJHelpAsset.structureEditor` is packaged with SBJFoundation and may be presented directly or embedded with the standard `SBJ_STRUCTURE_EDITOR_HELP` token. Bundle-resource lookup tolerates Swift Package Manager flattening processed resources, so the authored resource folder does not have to match the generated bundle layout.
