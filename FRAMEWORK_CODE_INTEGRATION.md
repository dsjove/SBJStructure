# Framework code integration

`SBJStructure` is evolving into a Foundation-level framework for shared model semantics, structural behavior, and reusable UI primitives that are consumed both by applications and by the bundled structured editor.

The guiding rule is to preserve established shared-framework APIs when they already express the concept well. Integration should remove duplicate concepts, not rename them into SBJ-prefixed equivalents.

## Search

There is one public search vocabulary:

- `SearchProtocol` lets a value deliberately expose searchable text beyond its obvious display representation.
- `Predicated` lets a value own custom matching semantics.
- `String.querify` retains its original contract: trim the query and return `nil` when blank.
- `String.predicated(search:)`, `Array.predicated(search:)`, and `Array.filter(search:)` retain their original names.
- `SearchField` is the shared SwiftUI search control.

The structured editor uses internal matching helpers built on those protocols. There is intentionally no public `SBJSearch` or `SBJSearchField` abstraction alongside them. Generic editor fallback matching may inspect `SBJValueDescription` and `String(describing:)`, but that is implementation detail rather than another public search model.

## Accessibility

The original API is canonical:

- `Accessible`
- `AccessibleItem`
- `AccessibleImage`
- `AccessibleImageItem`
- `View.accessibility(_:)`

`SBJPropertyInfo` conforms directly to `Accessible`, so property accessibility metadata remains model-level and presentation-independent. The protocol and concrete metadata live in `structure`; the SwiftUI adapter and image-bearing accessibility types live in `swiftUIComponents`. The adapter uses the restored shared `View.applyIf` helper rather than maintaining accessibility-specific optional modifier helpers.

There is intentionally no parallel `SBJAccessible` / `SBJAccessibility` protocol/value pair.

## Image naming

`ImageName` is a SwiftUI helper for bundled images and SF Symbols. `Image.init(_:)` and `Label.init(_:image:)` retain the established interface. It lives entirely under `swiftUIComponents`, and the structured editor uses it for icons so app UI and editor UI share the same naming convention.

`ImageSource` is a separate Foundation-level source description. Its enum (`none`, bundled resource, system symbol, or file URL) does not import UIKit. Platform realization is supplied separately by `ImageSource+UIKit`, including security-scoped file loading and image-data conversion. This keeps source semantics available on every supported platform without making `ImageName` and `ImageSource` competing abstractions.

## Shared SwiftUI/editor components

Reusable presentation primitives belong under `swiftUIComponents` when applications and the structured editor should intentionally share their behavior and appearance:

- `SearchField`
- `View.focusedHighlight(...)`
- `View.oneLiner(...)`
- `View.invalidDecoration(...)`
- `URLButton`
- `URLText`
- `ImageName`
- the `Accessible` SwiftUI adapter
- `View.applyIf(...)`

The editor composes these components rather than defining parallel private versions.

## URL opening

The established platform `URL.isValidURL`, `URL.open(_:)`, and `URL.open()` abstraction remains canonical. URL UI does not use SwiftUI's separate `openURL` path. `URLButton`, `URLText`, and the structured URL editor all use the same platform behavior.

`IdentifiedURL` remains a typealias of `Identified<URL>` rather than introducing another identity wrapper.

## Structural/business logic

The following are deliberately editor-independent and live in `structure`:

- generic issue representation and redundancy reduction;
- structure diagnostics/validation collection;
- default-value creation;
- recursive empty-content inspection;
- deterministic collection ordering and item identification;
- property metadata and documentation/accessibility semantics.

The editor layer adds only editor capability diagnostics, bindings/state, presentation, focus/disclosure, and collection editing behavior.

## Working boundary

`SBJStructure` may own model/value semantics, validation, diagnostics, deterministic representation, structural traversal, default creation, shared Foundation utilities, and UI primitives that intentionally establish common app/editor behavior.

It should not create a second abstraction simply to add an `SBJ` prefix to a mature shared-framework API, and it should not become a bucket for unrelated app-specific operations merely because they are reusable.
