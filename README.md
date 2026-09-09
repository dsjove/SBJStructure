# SBJFoundation

`SBJFoundation` is the low-level shared framework for SBJ applications. It extends Apple platform frameworks with reusable primitives that are broadly useful across SBJ products: Codable/platform bridges, presentation vocabulary, image/resource content, search, units, and the SBJStructure structured-model/editor subsystem.

The framework is deliberately not a home for application workflow or domain policy. **SBJStructure remains SBJStructure** inside this package; the package name describes its layer, not a replacement identity for its major subsystems.

```swift
import SBJFoundation

@SBJStructure
struct Recipe: Codable {
    @SBJString(maxLength: 80)
    var name: String

    @SBJInteger(range: 1...24)
    var servings: Int
}
```

## Framework boundaries

```text
Apple platform frameworks
        ↓
   SBJFoundation
     ↙       ↘
SBJKit      SBJLayout
     \       /
      Applications
```

- **SBJFoundation** owns reusable values and contracts close to Apple frameworks: platform extensions, Codable support, presentation/UI vocabulary, image/resource payloads, search, units, observation helpers, and SBJStructure + SubjectEditor.
- **SBJKit** owns higher-level reusable application workflows assembled from Foundation primitives. It may depend on SBJFoundation.
- **SBJLayout** owns newspaper/print-style pagination, geometry, fitting, and PDF rendering. It may depend on SBJFoundation.
- **Applications/domain packages** own domain vocabulary, business rules, document policy, resource-store policy, vendor/server policy, and final presentation choices.

See [Framework Ownership and Dependency Boundaries](Documentation/ARCHITECTURE.md) for the canonical ownership statement.

## Source organization

Directory placement communicates ownership; it does not create separate modules.

- `Sources/SBJFoundation/SBJStructure/` — structural metadata, annotations, validation/diagnostics, resource-reference discovery, SubjectEditor, source export, and preview fixtures.
- `Sources/SBJFoundation/Image/` — reusable image references and image-resource UI, including `ImageReference`, `PhotoMenu`, and thumbnail/display controls.
- `Sources/SBJFoundation/UIVocabulary/` — shared SwiftUI visual vocabulary: semantic appearance, field chrome, active/focus/validation/search decoration, alerts, buttons, and reusable controls.
- `Sources/SBJFoundation/Search/` — general search values, matching, and `SearchField`.
- `Sources/SBJFoundation/Codables/` — Codable representations for platform-facing values.
- `Sources/SBJFoundation/PlatformExtensions/Foundation/` — Foundation-centered types and extensions, including `SBJResourceContent`
- `Sources/SBJFoundation/PlatformExtensions/UIKit/` — UIKit realization/bridges for platform-neutral values.
- `Sources/SBJFoundation/Units/` — codable reusable measurement semantics and editing policy.
- `Sources/SBJFoundation/Localization/` — presentation/localization building blocks shared across renderers.
- `Sources/SBJFoundation/Help/` — application help resources, UTType-based presenter dispatch, HTML/Markdown rendering, template substitution, About, and help presentation.
- `Sources/SBJFoundationMacros/` — macro implementations used by SBJStructure annotations.

`ImageReference` is the single concrete image reference type. It replaces the former split between named UI imagery and file-backed image sources, with `none`, `system`, `bundled`, and `file` cases realized by SwiftUI/UIKit adapters. Bundled references carry `Bundle` directly; no separate bundle-reference abstraction is required.

## Help

SBJFoundation owns the application help system so every application can use it without an SBJKit dependency. Existing HTML data assets and their template substitutions remain first-class; Markdown is also supported. Help representations are selected through `UTType`, and additional presenters can be introduced without changing the shared sheet/chrome. `SBJHelpLink` uses native SwiftUI HelpLink where the SDK exposes it and the shared UIVocabulary fallback on iOS/Mac Catalyst. About is intentionally a help resource and remains available from the help toolbar.

See [Help System](Documentation/HELP.md).

## SBJStructure and SubjectEditor

SBJStructure describes the structure of Codable models independently from business semantics. Generated metadata supports validation, comparison, content inspection, diagnostics, resource-reference discovery, source export, accessibility, and SubjectEditor.

`SBJStructuredEditorPreview` is the kitchen-sink compile/sample fixture. Every SBJStructure annotation must be represented there. See:

- [SBJStructure design and rationale](Documentation/SBJStructure/README.md)
- [SubjectEditor preview coverage](Documentation/SBJStructure/SAMPLE_COVERAGE.md)
- [Accessibility regression checklist](Documentation/SBJStructure/ACCESSIBILITY_REGRESSION.md)

## Resource identity, content, and images

SBJFoundation separates semantic resource identity from encoded payload:

- `SBJResourceID` is the stable reference stored by structured/document models.
- `SBJResourceContent` is an unnamed encoded payload: `Data` plus its Foundation `UTType`.
- `SBJResourceDiscovery` finds `SBJResourceID` usages throughout generated SBJStructure graphs and standard containers.

That boundary keeps file locations, UIKit objects, persistence callbacks, and application-specific attachment semantics out of structured models.

`PhotoMenu` edits a `Binding<SBJResourceContent?>`. Files, Photos, and Paste preserve encoded image bytes and content type when available; Camera output is encoded off the main actor. `PhotoThumbnailView` and `PhotoDisplayView` provide reusable presentation around the same resource-content model. The application remains responsible for storing returned content, assigning or retaining `SBJResourceID`, garbage collection, and document-save policy.

## Search and editor filtering

`SearchField` is reusable outside SubjectEditor and can optionally show the standard active-search decoration itself. `SBJEditorSearchBar` suppresses that field-local decoration and applies the same decoration around the complete search/filter control group whenever text, Changed-only, or Empty-only filtering is active.

Structural search/filter criteria are represented independently of SwiftUI by `SBJEditSearchCriteria`; editor views consume those criteria through the SubjectEditor environment.

## Localization and presentation resources

Localization is treated as a broader presentation-resource problem spanning text, formatting/units, imagery/symbology, semantic color, accessibility, vendor/document/server policy, and renderer fitting. The shared design is documented in [Localization and Presentation Resources](Documentation/LOCALIZATION_AND_PRESENTATION_RESOURCES.md).

SBJFoundation owns shared semantic/resource contracts. SBJLayout owns geometric selection and print/PDF rendering. Applications own domain meaning and policy.

## Testing

SBJFoundation is low-level enough that refactoring should be protected by focused behavior tests. SubjectEditor preview compile coverage complements, but does not replace, tests for structural behavior, macros, resource discovery/sendability, accessibility/localization, Codable support, observation, units, and editor behavior.

See [Testing](Documentation/TESTING.md).
