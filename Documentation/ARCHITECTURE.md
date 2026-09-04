# Framework Ownership and Dependency Boundaries

This is the canonical ownership statement for the SBJ frameworks. It is intentionally short; subsystem design documents may add detail but should not contradict these boundaries.

## Dependency direction

```text
Apple platform frameworks
        ↓
   SBJFoundation
     ↙       ↘
SBJKit      SBJLayout
     \       /
      Applications
```

- **SBJFoundation** extends Apple platform frameworks with reusable value types, presentation vocabulary, observation helpers, Codable bridges, unit semantics, and the SBJStructure model/editor subsystem. It must not depend on SBJKit, SBJLayout, or application/domain modules.
- **SBJKit** contains higher-level reusable application workflows assembled from Foundation/platform primitives: attachments, tags/persistence workflows, photo workflows, sharing, help, and generic unit-conversion UI. It may depend on SBJFoundation.
- **SBJLayout** is the newspaper/print-style paginated layout and PDF framework. It owns geometry, measurement, fitting, pagination, PDF generation and the narrow PDFKit hosting bridge. It may depend on SBJFoundation. It does not own domain vocabulary or localization policy.
- **Applications/domain packages** own domain vocabulary, business rules, allowed-unit policies, document policy, vendor/server policy, and final presentation choices.

## Presentation-resource ownership

Before localization is implemented, the intended split is:

- SBJFoundation: semantic presentation resources and resolution contracts; shared imagery/color/accessibility/unit vocabulary.
- SBJLayout: geometric selection among already-valid presentation candidates and measure/render consistency.
- SBJKit: reusable workflows that consume those resources.
- Apps: domain meaning and policy.

## Platform-specific code

Platform-specific APIs are allowed when they are the platform capability being wrapped. They should remain behind narrow boundaries instead of leaking raw UIKit/AppKit/PDFKit objects through higher-level APIs. The PDF host is the reference example.
