import SwiftUI

/// SwiftUI rendering capability layered on top of the UI-independent
/// ``SBJEditable`` model description.
///
/// `@SBJStructure` synthesizes this conformance together with `SBJEditable`.
public protocol SBJSwiftUIEditable: SBJEditable {
    @MainActor
    static var sbjEditorFields: [SBJEditorField<Self>] { get }
}

public extension SBJSwiftUIEditable {
    /// Type-erased field count used by the recursive SwiftUI editor.
    @MainActor
    internal static var _sbjEditorFieldCount: Int {
        Self.sbjEditorFields.count
    }

    @MainActor
    internal static func _sbjCollectIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry
    ) -> [SBJEditorCapabilityIssue] {
        guard let typed = value as? Self else { return [] }
        return Self.sbjEditorFields.flatMap { field in
            field.issues(root: typed, path: path, registry: registry)
        }
    }

    @MainActor
    internal static func _sbjMakeEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue? = nil,
        registry: SBJEditorRegistry,
        itemActions: SBJEditorItemActions? = nil,
        focusRequest: SBJEditorFocusRequest? = nil,
        titleIsUnknown: Bool = false,
        promotedTitlePropertyName: String? = nil,
        promotedTitlePrefix: String? = nil,
        context: SBJEditTraversalContext = .root
    ) -> AnyView {
        let typedBinding = binding.binding(as: Self.self)

        return AnyView(
            SBJObjectEditor(
                title: label,
                value: typedBinding,
                originalValue: originalValue.map { $0.value(as: Self.self) },
                registry: registry,
                itemActions: itemActions,
                focusRequest: focusRequest,
                titleIsUnknown: titleIsUnknown,
                promotedTitlePropertyName: promotedTitlePropertyName,
                promotedTitlePrefix: promotedTitlePrefix,
                context: context
            )
        )
    }

    @MainActor
    internal static func _sbjMakeEditorContents(
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue? = nil,
        registry: SBJEditorRegistry,
        focusRequest: SBJEditorFocusRequest? = nil,
        context: SBJEditTraversalContext = .root
    ) -> AnyView {
        let typedBinding = binding.binding(as: Self.self)
        let rootValidation = SBJEditorRootValidationResult.computed(
            SBJInvariantCheck.validationError(
                typedBinding.wrappedValue,
                at: SBJValidationKeyPath(\Self.self)
            )
        )
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(Self.sbjEditorFields.enumerated()), id: \.offset) { _, field in
                    field.view(
                        root: typedBinding,
                        originalRoot: originalValue.map { $0.value(as: Self.self) },
                        registry: registry,
                        focusRequest: focusRequest,
                        context: context.descended(),
                        rootValidation: rootValidation
                    )
                }
            }
        )
    }
}
