# Pre-Localization Audit

> **Non-normative inventory/checklist.** Canonical localization and presentation-resource design lives in `SBJFoundation/Documentation/LOCALIZATION_AND_PRESENTATION_RESOURCES.md`.

Status: complete for the pre-localization cleanup pass. This document records findings that should inform localization rather than pre-deciding the localization API.

## Formatting and locale

The strongest existing pattern is good: SwiftUI editors generally read the environment locale rather than `Locale.current`. `NumberTextField`, numeric width estimation, color accessibility values, and data-size accessibility values already use explicit/effective locale.

Remaining formatting seams:

- `SBJDecimalEditor` and `SBJLosslessNumericEditor` still construct `NumberFormatter`; retain behavior but migrate behind the eventual formatting resource/context rather than proliferating formatters.
- `SBJStructuredEditorPreview` contains direct `.formatted()` output intentionally as fixture/sample code.
- `Data+Hex` uses `String(format:)` for hexadecimal serialization/display; this is invariant technical formatting, not localization.
- Unit names/abbreviations and compound/fractional formatting remain intentionally unresolved until presentation resources are designed.

## Images and colors

`ImageName` is the intended SwiftUI image seam. Direct `Image(systemName:)` calls should exist only inside its implementation. `ColorVariants` is concrete color-source vocabulary; `SBJUIAppearance` is the semantic UI-role boundary.

No additional semantic-color migration was identified in SBJFoundation during this audit.

## Alerts, validation and accessibility

`PendingAlert`, `SBJIssue`, `Accessible`/`AccessibleImage`, property metadata, and editor accessibility strings are major localization clients. `PendingAlert` still has the known empty-primary-title sentinel and framework-owned `OK` vocabulary; do not expand that design before the resource model is finalized.

## Public API review

The package has a deliberately broad public surface because SBJStructure exposes generated metadata/editor types. No access-level changes were made mechanically. The main candidates for a later API-hardening pass are low-level editor plumbing (`SBJAnyBinding`, `SBJEditorRegistry`, `SBJEditorField`, Swift-encoder argument helper types) if no external client needs them. They should not block localization.

`UnitType`, `UnitValue`, common units, `UnitEditingPolicy`, `ImageName`, `SBJUIAppearance`, and the primary SBJStructure protocols are intentional public API.

## Dependency and platform boundaries

Package manifests conform to the canonical dependency direction in `ARCHITECTURE.md`. UIKit use is concentrated in Codable/image/font bridges and SwiftUI controls that require UIKit capabilities. No higher framework dependency was found.

## Dead/duplicate code

No duplicate active Foundation abstractions were identified. Deprecated SBJStructure compatibility members are explicit and can remain until a separately planned source-breaking cleanup.

## Test-gap review

Existing tests already cover the high-risk localization seams: effective locale behavior, numeric width, accessibility, `ImageName`, units/Codable compatibility, editor discovery, structural metadata, and sample coverage. No new speculative snapshot tests are recommended before localization.
