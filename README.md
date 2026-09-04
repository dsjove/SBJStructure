# SBJFoundation

`SBJFoundation` is the low-level shared framework for SBJ applications. Its purpose is to
**extend Apple's platform frameworks with reusable application primitives**, not to replace
or wrap only `Foundation`.

The module contains code that naturally sits beside Foundation, SwiftUI, UIKit, Observation,
and related system frameworks: Codable support, platform extensions, presentation vocabulary,
observation helpers, and the SBJStructure structured-model/editor subsystem.

The name describes the framework's role in the application stack. Individual subsystems keep
their own stronger identities; most importantly, **SBJStructure remains SBJStructure** inside
this package.

```swift
import SBJFoundation

@SBJStructure
struct Recipe: Codable {
    @SBJText(maxLength: 80)
    var name: String

    @SBJInteger(range: 1...24)
    var servings: Int
}
```

## Package boundaries

The intended SBJ layering is:

```text
Apple platform frameworks
        ↓
SBJFoundation
  ├─ platform extensions / Codable / Observation
  ├─ UIVocabulary and presentation resources
  └─ SBJStructure + SubjectEditor
        ↓
SBJLayout                 SBJKit
newspaper/print PDF       higher-level app abstractions
layout                    (tags, attachments, persistence,
                          photo/share workflows, etc.)
        ↓                    ↓
             applications
```

`SBJFoundation` should contain primitives that are broadly reusable and close to the system
frameworks they extend. Higher-level workflows and application concepts belong in `SBJKit`.
Paginated newspaper/print-style PDF composition belongs in `SBJLayout`.

## Source organization

- `Sources/SBJFoundation/SBJStructure/` — structural model metadata, annotations,
  SubjectEditor, source export, and the living preview fixture.
- `Sources/SBJFoundation/UIVocabulary/` — reusable SwiftUI presentation vocabulary and
  presentation-resource building blocks such as `ImageName`, semantic appearance, shared
  field chrome, alerts, and compact controls.
- `Sources/SBJFoundation/Codables/` — reusable Codable representations for platform values.
- `Sources/SBJFoundation/PlatformExtensions/Foundation/` — extensions/helpers centered on
  Foundation types and services.
- `Sources/SBJFoundation/PlatformExtensions/UIKit/` — UIKit-specific platform bridges.
- `Sources/SBJFoundation/Observation/` — Observation/lifetime helpers.
- `Sources/SBJFoundation/Search/` — general search protocol support.
- `Sources/SBJFoundationMacros/` — macro implementations used by SBJStructure annotations.

Directory placement communicates ownership; it does not create separate modules.

## SBJStructure and SubjectEditor

SBJStructure is a major subsystem, not the name of the containing framework. It describes the
structure of Codable models independently from business semantics and generates metadata used
for validation, comparison, content inspection, diagnostics, source export, accessibility, and
SubjectEditor.

`SBJStructuredEditorPreview` is intentionally a kitchen-sink compile/sample fixture. Every
SBJStructure annotation must be declared there. See:

- [SBJStructure design and rationale](Documentation/SBJStructure/README.md)
- [SubjectEditor preview coverage](Documentation/SBJStructure/SAMPLE_COVERAGE.md)
- [Accessibility regression checklist](Documentation/SBJStructure/ACCESSIBILITY_REGRESSION.md)

## Localization and presentation resources

Localization is being designed as a broader presentation-resource problem spanning text,
formatting/units, imagery/symbology, semantic color, accessibility, vendor/document/server
policy, and renderer fitting. The shared design lives in:

- [Localization and Presentation Resources](Documentation/LOCALIZATION_AND_PRESENTATION_RESOURCES.md)

`SBJFoundation` owns the shared semantic/resource contracts. `SBJLayout` owns geometric
selection and print/PDF rendering. Applications own domain vocabulary and application policy.

## Documentation convention

Design and architecture documents live in `Documentation/` in SBJ projects. The root README is
an entry point and boundary statement; detailed subsystem design belongs under `Documentation/`.

See [Documentation/README.md](Documentation/README.md) for the documentation index.

## Testing

SBJFoundation is low-level enough that refactoring should be protected by focused tests.
SubjectEditor Preview compile coverage complements, but does not replace, behavior tests.
Recent consolidation specifically protects observation re-arming/cancellation, presentation
resource sendability, and free-form editor width policy in addition to the existing structural,
macro, accessibility/localization, Codable, and editor tests.

See [Testing](Documentation/TESTING.md).


## Units

Reusable measurement semantics, `UnitValue`, and editor integration are documented in [Documentation/UNITS.md](Documentation/UNITS.md).
