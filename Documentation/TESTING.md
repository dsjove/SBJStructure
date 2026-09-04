# SBJFoundation Testing

SBJFoundation is a low-level dependency for multiple applications, so its tests should protect
stable semantics and regression-prone infrastructure rather than duplicate SwiftUI implementation
details.

## Two complementary coverage mechanisms

### SubjectEditor Preview compile coverage

`SBJStructuredEditorPreview` declares every SBJStructure annotation and intentionally pulls the
editor dependency graph into one living sample. Its contract is documented in
[SBJStructure/SAMPLE_COVERAGE.md](SBJStructure/SAMPLE_COVERAGE.md).

This is compile dependency coverage: if a type on that path is removed, the Preview should no
longer build. It is not runtime branch coverage.

### Focused tests

Focused tests protect behavior that a compile fixture cannot:

- macro expansion and structural metadata;
- structural equality/content/default/validation semantics;
- collection mutation and editor traversal/identity;
- Swift source encoding;
- Codable platform-value bridges;
- accessibility/localization invariants;
- reusable UI API surfaces and pure presentation policies.

## Refactoring gaps reviewed during the SBJFoundation rename

The recent consolidation introduced several behaviors that deserved explicit regression tests:

1. **Observation without a context object** — the original helper once failed to re-arm this
   path after a change. `ObservationTests` now verifies repeated context-free delivery and
   synchronous cancellation.
2. **Free-form one-line editor width** — unconstrained String fields should fill the available
   horizontal space, while constrained strings remain intrinsic. `SBJFieldWidthPolicyTests`
   protects that policy without snapshot-testing SwiftUI layout.
3. **Presentation-resource concurrency** — `ImageName` and `BundleReference` are immutable
   resource descriptions and must remain `Sendable`. `ImageNameTests` now enforces that at
   compile time.

Existing tests already cover the major structural/editor/codable behaviors touched by the recent
moves. No additional snapshot/UI-rendering suite is recommended merely for directory or module
renames.

## What not to test here

- Apple framework behavior already guaranteed by SwiftUI/UIKit/Foundation.
- Pixel-perfect editor rendering; use previews and accessibility/manual regression checks.
- Every annotation parameter or enum case solely for coverage metrics.
- SBJKit higher-level workflows from this package.

When localization/presentation-resource resolution becomes implemented, add resolver tests at the
semantic boundary and measurement/fit tests in SBJLayout rather than forcing those into view
snapshots.
