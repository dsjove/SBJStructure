# SBJStructure code review — 2026-09-02

This review focuses on the direction discussed during the recent refactors: SBJStructure as a Foundation-level model/structure framework with a bundled editor and a small set of shared SwiftUI primitives used consistently by both the editor and client apps.

## Changes made during this review

### 1. Accessibility: one canonical API

Resolved the duplicate accessibility models.

Canonical public API:

- `Accessible`
- `AccessibleItem`
- `AccessibleImage`
- `AccessibleImageItem`
- `View.accessibility(_:)`

`SBJAccessible` and `SBJAccessibility` were removed. `SBJPropertyInfo` now conforms directly to `Accessible`.

The protocol and concrete non-UI metadata are in `structure/AccessibleItem.swift`. SwiftUI application and image-bearing accessibility types are in `swiftUIComponents/Accessible+SwiftUI.swift`. This preserves the existing API while keeping SwiftUI out of the `structure` directory.

The original `AccessibleItem.swift` also depended on an `applyIf` helper that was not present in this package. The SwiftUI adapter no longer has that hidden dependency.

### 2. ImageName and ImageSource integrated

Added the established `ImageName` API and its `Image`/`Label` initializers under `swiftUIComponents`.

The structured editor now uses `ImageName` for its SF Symbol icons instead of directly calling `Image(systemName:)`, so editor and app UI use the same naming abstraction.

`ImageSource` was integrated under `uikitExtensions` because it is explicitly a `UIImage` abstraction. Its file-loading case reuses the existing security-scoped `UIImage(url:)` initializer rather than duplicating file access logic.

### 3. Search: one public vocabulary

Removed the public `SBJSearch` abstraction. The public search API is again:

- `SearchProtocol`
- `Predicated`
- `String.querify`
- `String.predicated(search:)`
- `Array.predicated(search:)`
- `Array.filter(search:)`
- `SearchField`

`SearchProtocol` now has a default `isEmpty` implementation based on `text`. The editor's generic fallback matching is internal and checks, in order:

1. custom `Predicated` behavior;
2. explicit `SearchProtocol.text`;
3. `SBJValueDescription`;
4. `String(describing:)`.

This preserves the useful ability for a model to contribute hidden aliases/derived text without maintaining a second public search engine.

`SearchField.swift` was moved into `swiftUIComponents`; the non-UI search protocols remain under `search`.

### 4. URL views: restored established names

`URLButton` and `URLText` are canonical again. The SBJ-prefixed duplicate names/aliases were removed. Both continue to use the package's explicit platform `URL.open()` abstraction rather than SwiftUI `openURL`.

### 5. Issue identity and deduplication

`SBJIssue.id` now uses the complete immutable issue value (`Self`) rather than constructing a string from only some fields. This avoids SwiftUI identity collisions when two distinct messages occur at the same path/type/kind.

Diagnostic `uniqued` passes now use the complete `SBJIssue` value as the key instead of rebuilding an incomplete string key.

The existing conservative redundant-parent filtering remains intact.

### 6. Tests repaired/expanded

Updated stale search tests that still referenced `SBJSearch` and stale `queryValue` naming.

Added/expanded tests for:

- `SearchProtocol` contributing non-obvious searchable text without also conforming to `Predicated`;
- custom `Predicated` behavior taking precedence;
- old `querify` behavior;
- original array search helpers;
- `AccessibleItem` initializer/properties;
- `SBJPropertyInfo` conforming to `Accessible`;
- `ImageName` empty semantics;
- `AccessibleImageItem` labeling behavior;
- compile-level smoke coverage for the established `ImageName`, `Label`, and `View.accessibility(_:)` SwiftUI interfaces;
- distinct issue messages producing distinct identities.

All Swift source and test files pass `swiftc -parse` with the toolchain available in this environment.

## Design review

### Structure/UI boundary — good after cleanup

The `structure` directory is again SwiftUI-free. Business/model concepts such as diagnostics, content traversal, defaults, collection ordering/identification, metadata, validation, and accessibility semantics can be consumed by non-editor tools.

Shared SwiftUI behavior that should look/act the same in apps and in the editor lives outside `structure` and is consumed by the editor rather than reimplemented there.

### Search — intentionally two complementary protocols, not two search systems

`SearchProtocol` and `Predicated` are complementary existing interfaces:

- `SearchProtocol` supplies searchable text/search state.
- `Predicated` supplies a custom predicate.

They are not competing engines. There is no longer a public `SBJSearch` facade alongside them.

### Accessibility — one semantic model

Accessibility no longer has an SBJ-prefixed semantic representation and an older `Accessible` representation in parallel. `SBJPropertyInfo` carries the same established protocol that client UI uses.

### ImageName — correct shared-UI placement

`ImageName` is not Foundation/model structure, but it *is* a shared presentation primitive that the editor should consume. `ImageSource`, by contrast, remains explicitly UIKit-specific.

## Open findings / recommended next work

### High: declared platform support does not match the font implementation

`Package.swift` declares iOS, macOS, and watchOS, but `CodableFont.swift`, `CodableFontCache.swift`, and `CodableFontTests.swift` import/use UIKit/`UIFont` unconditionally. This means the package's declared cross-platform contract and the font subsystem disagree.

Choose one direction deliberately:

1. If SBJStructure is really iOS/Mac Catalyst only, narrow the declared platforms.
2. If native macOS/watchOS support is intended, make `CodableFont`'s realization/cache layer platform-specific (`UIFont`/`NSFont`, and a watchOS policy) while keeping the Codable model shared.

I did not make that larger API/platform decision in this pass.

### Medium: generic editor still contains a CodableFont special case

`SBJEditorField` checks `Root.self == CodableFont.self`, a specific property name, and `Optional<String>` to substitute the font-family editor. That is a domain-type exception inside otherwise generic editor infrastructure.

A cleaner long-term direction is a built-in registry/editor specialization or a structural hint describing a font-family selector. That would let the generic field renderer remain type-generic.

### Medium: type-erased editor bindings rely on force casts

`SBJAnyBinding` and several editor dispatch paths use `as!` after type erasure. The generated/internal call paths appear to establish the required type invariants, but `SBJAnyBinding` is public because it participates in public editor protocols. Manual/custom conformers can therefore trigger runtime traps if they violate those assumptions.

This is worth revisiting when the editor protocol surface next changes. Options include typed wrapper methods, checked casts with explicit precondition messages, or reducing which erased operations are public.

### Medium: UI behavior is still mostly untested

The structural logic has reasonable unit coverage, but the exact regressions that prompted the recent work—double TextField borders, focus geometry, active-search decoration, accessibility application, URL-button behavior—are SwiftUI behavior and are not covered by the current unit suite.

A small host-app/XCUITest visual regression suite would provide more value here than trying to introspect SwiftUI's private view tree in ordinary unit tests. At minimum, keep one editor fixture screen containing every built-in control type so border/focus/accessibility changes can be checked together.

### Low: reflection remains part of collection item-title lookup

`SBJCollectionItemIdentification` uses the string `itemTitleKey` plus `Mirror` to read a configured title. It is appropriately outside the editor now, but it is still more fragile than a type-erased getter generated from the original key path would be.

This is acceptable for now, but if collection identity becomes important to exporters/logging as well as UI, consider carrying an accessor in metadata rather than only a property-name string.

### Low: redundant issue filtering is quadratic

`removingRedundantIssues` compares each issue to all other issues. Editor issue lists should normally be small, so clarity currently wins. If this becomes a logging/import validation facility that can produce hundreds or thousands of issues, group by `(kind, typeName, valueDescription)` before doing path ancestry checks.

## Test/build status

- `swiftc -parse`: passes across all `Sources` and `Tests` files.
- `git diff --check`: clean.
- Full `swift test`: not runnable in this environment because the package declares Swift tools 6.4 while the installed compiler is Swift 6.2.1.

The full suite should be run in the normal Swift 6.4/Xcode environment before merging, particularly because parser validation cannot detect unavailable APIs, actor-isolation errors, or generic type-checking failures.
