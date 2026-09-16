# Framework Ownership and Dependency Boundaries

This is the canonical ownership statement for the SBJ frameworks. It is intentionally short; subsystem design documents may add detail but should not contradict these boundaries.

## Dependency direction

```text
Apple platform frameworks
        ↓
   SBJFoundation
      ↓       ↘
 shared       SBJLayout
 packages        ↓
      \        /
       Applications
```

- **SBJFoundation** extends Apple platform frameworks with reusable value types, presentation vocabulary, application help, observation helpers, Codable bridges, unit semantics, shared workflows, and the SBJStructure model/editor subsystem. It must not depend on SBJLayout or application/domain modules.
- **SBJLayout** is the newspaper/print-style paginated layout and PDF framework. It owns geometry, measurement, fitting, pagination, PDF generation and the narrow PDFKit hosting bridge. It may depend on SBJFoundation. It does not own domain vocabulary or localization policy.
- **Other shared packages** may depend on SBJFoundation for common contracts. Their domain-specific behavior remains outside SBJFoundation unless it is deliberately consolidated into the low-level shared layer.
- **Applications/domain packages** own domain vocabulary, business rules, allowed-unit policies, document policy, vendor/server policy, and final presentation choices.

## Presentation-resource ownership

Before localization is implemented, the intended split is:

- SBJFoundation: semantic presentation resources and resolution contracts; shared imagery/color/accessibility/unit vocabulary; application help resources and presentation.
- SBJLayout: geometric selection among already-valid presentation candidates and measure/render consistency.
- Shared workflows: live in their owning framework/package and consume SBJFoundation resources directly.
- Apps: domain meaning and policy.

## Platform-specific code

Platform-specific APIs are allowed when they are the platform capability being wrapped. They should remain behind narrow boundaries instead of leaking raw UIKit/AppKit/PDFKit objects through higher-level APIs. The PDF host is the reference example.
