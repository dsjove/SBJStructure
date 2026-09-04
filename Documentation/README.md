# SBJFoundation Documents

This directory contains design, architecture, regression, and maintenance documentation for
SBJFoundation. The package README is intentionally an overview; durable subsystem decisions
belong here.

## Documents

- [SBJStructure](SBJStructure/README.md) — structured Codable model metadata, annotations,
  validation semantics, SubjectEditor, and source export.
- [SubjectEditor Preview Coverage](SBJStructure/SAMPLE_COVERAGE.md) — the compile/sample
  coverage contract for every SBJStructure annotation and its transitive editor path.
- [Accessibility Regression](SBJStructure/ACCESSIBILITY_REGRESSION.md) — editor accessibility
  review and regression checklist.
- [Localization and Presentation Resources](LOCALIZATION_AND_PRESENTATION_RESOURCES.md) —
  shared text, formatting, units, imagery/symbology, semantic color, accessibility, and
  override/resolution design used by SBJFoundation and consumed by SBJLayout/apps.
- [Units](UNITS.md) — shared `UnitValue`, physical-unit semantics, conversion, editing policy, and localization boundary.
- [Testing](TESTING.md) — test boundaries and refactoring regression coverage.

When a new subsystem accumulates more than a single design note, give it a subdirectory rather
than flattening unrelated documents into this directory.

- [Architecture](ARCHITECTURE.md)
- [Pre-localization audit](PRELOCALIZATION_AUDIT.md)
