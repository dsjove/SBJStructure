# Localization / Presentation-Resource Design Finalization Report

Date: 2026-09-05

## Scope

This pass treated SBJFoundation, SBJLayout, SBJKit, and Jove's Characters as one architecture. It completed the remaining pre-localization source audits, resolved the non-Xcode design spikes, consolidated durable findings into authoritative documents, and removed historical/pointer documentation that no longer has an independent purpose.

No production localization API was implemented in this pass. Source changes are documentation-only.

## Spike conclusions

### 1. Source-string and String Catalog API shape

Preferred source shape:

```swift
public init(_ resource: LocalizedStringResource)

SBJTextResource("Armor Class")
```

Do not initially make `SBJTextResource` itself `ExpressibleByStringLiteral`. The initializer parameter should be Apple's localization resource so the literal is inferred as `LocalizedStringResource` at the call site.

Apple's current localization documentation says Xcode extracts user-facing strings passed through localizable APIs, documents `LocalizedStringResource` as a deferred localization reference, and documents it as supporting string literals/interpolation. Apple engineering guidance also describes string literals resolving to `LocalizedStringResource` as localizable during extraction.

The available toolchain is Linux Swift 6.2.1 and does not contain Apple Foundation's `LocalizedStringResource`; Xcode/xcodebuild is unavailable. Therefore the final Product > Build / `.xcstrings` extraction check cannot be executed in this environment. That remaining check is mechanical, not an unresolved architecture question.

### 2. Resource identity

Default localizable identity should come from the localization resource (bundle/table/key). Do not introduce a global enum of localization keys.

Support an optional explicit semantic identity for the minority of concepts that must survive source-wording/catalog-key changes or participate in vendor/document/server overrides independently of catalog organization.

Overrides operate on identity/resources before resolved prose, never substring replacement.

### 3. Typed interpolation / formatting

Keep typed values typed until resolution. `LocalizedStringResource`/`String.LocalizationValue` supports typed interpolation; SBJ formatting resources may extend that model for domain values that Foundation cannot format directly.

User/runtime text embedded in localized grammar is verbatim data, not a newly localizable string.

### 4. Candidate model

Start with three authored roles only:

- standard
- compact
- abbreviated

Each is independently localizable. Wrapping/truncation/hyphenation are layout behaviors; a multiline candidate is distinct only when wording or authored break semantics are genuinely distinct.

### 5. Resolver/context model

Use one shared value context with an ordered sparse provider chain configured by the host. Do not hard-code universal precedence between vendor, document, user-setting, or server policy.

Locale, terminology, vendor, accessibility, preferred units, and document policy are independent axes.

### 6. Image/color audit

Do not generalize concrete and semantic types prematurely.

- `ImageName` remains a concrete SwiftUI image candidate boundary.
- Semantic image identity is a separate future resource resolved to `ImageName`.
- `CodableColor` remains persisted/concrete data.
- `ColorVariants` remains a concrete color-source helper.
- `SBJUIAppearance` remains the current semantic UI-role boundary and the seed for future semantic color resolution.

## Source audit baseline

The scan intentionally records migration seams rather than asking that every literal be localized mechanically.

### SBJFoundation

- 11 `StringPresentable` references across 3 files.
- 3 `Jargon` references in the legacy localization implementation.
- One active `Locale.current` seam in `NumberTextField`; numeric editors also construct `NumberFormatter` instances.
- Primary human-facing migration clients: `PendingAlert`, `SBJIssue`, accessibility types, SBJPropertyInfo/editor copy, and unit presentation.
- `Data+Hex` invariant hexadecimal formatting is not a localization target.

### SBJLayout

- 15 `Jargon` references across active source/tests; it is migration code, not dead code.
- No active locale-driven date/number formatting policy was found.
- Page-management accessibility labels are framework vocabulary and should use the shared resource system.
- Candidate-selection work must persist the measured candidate through draw/pagination.

### SBJKit

- Reusable UI contains ordinary labels/alerts/accessibility copy but no reason for a separate localization architecture.
- Unit conversion formatting remains a temporary direct formatting seam.
- `oldPDF (useSBJLayout)` remains migration debt and should receive no new presentation architecture.
- `View+navigationTitle.swift` remains a deletion candidate after downstream-use verification.

### Jove's Characters

- 102 `StringPresentable` references across 37 files.
- 44 `abbreviation` references across 19 files.
- 4 `multiLineDescription` references across 4 files.
- CharacterSheet still consumes legacy candidates before SBJLayout has final geometry in several high-value sections.
- App UI contains remaining framework/app literals, alerts and accessibility strings that are now inventoried inside the canonical localization design.

## Documentation consolidation

### Removed: pointer-only indexes

- `SBJFoundation/Documentation/README.md`
- `SBJLayout/Documentation/README.md`
- `SBJKit/Documentation/README.md`
- `Jove-s-Characters/Character/Documentation/README.md`
- `Jove-s-Characters/CharacterSheet/Documentation/README.md`
- `Jove-s-Characters/Jove's Characters/Documentation/README.md`
- `Jove-s-Characters/Jove's Characters/README.md` (four-line pointer only)

Substantive root READMEs now link directly to authoritative documents where useful.

### Removed: completed audit/history documents

- `SBJFoundation/Documentation/PRELOCALIZATION_AUDIT.md`
- `SBJLayout/Documentation/PRELOCALIZATION_AUDIT.md`
- `SBJKit/Documentation/PRELOCALIZATION_AUDIT.md`
- `Jove-s-Characters/Jove's Characters/Documentation/PreLocalizationAudit.md`
- `Jove-s-Characters/Jove's Characters/Documentation/UIStringAudit.md`
- `Jove-s-Characters/Character/Documentation/StringPresentableAudit.md`

Their durable findings were merged into the appropriate canonical design/README. Jove's exhaustive migration inventories were retained inside `Jove's Characters/Documentation/Localization.md`, so detail was consolidated rather than discarded.

## Canonical localization/presentation documents after cleanup

- SBJFoundation: `Documentation/LOCALIZATION_AND_PRESENTATION_RESOURCES.md`
- SBJLayout: `Documentation/LOCALIZATION_DESIGN.md`
- SBJKit: root `README.md` only; it consumes the Foundation architecture and has no independent localization subsystem.
- Jove's Characters: `Jove's Characters/Documentation/Localization.md`

Other subsystem documents remain only where they describe an independent durable contract (SBJStructure, units, testing, PDF hosting, character model, CharacterSheet presentation, document storage, wizard/editor designs, etc.).

## Validation performed

- Checked every Markdown link in the finalized trees: 0 broken local links.
- Checked removed-document names for stale Markdown references: none remain except an intentional historical sentence in SBJKit's README noting that the audit was folded in.
- `swift package dump-package` succeeds for SBJKit with the available Swift 6.2.1 toolchain.
- SBJFoundation, SBJLayout, and Character require Swift tools 6.4, so their manifests cannot be validated with this older installed toolchain.
- Attempted a `LocalizedStringResource` compiler fixture; Apple-only Foundation API is absent from the Linux toolchain, confirming that the Xcode extraction spike cannot be executed here.

## Next implementation step

There should be no additional audit/consolidation phase before implementation. The next code change can start directly in SBJFoundation with the text-resource kernel using the finalized constraints above, with a single Xcode `.xcstrings` extraction fixture run before broad call-site migration.
