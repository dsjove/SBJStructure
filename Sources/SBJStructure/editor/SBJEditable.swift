import SwiftUI

/// A value whose stored properties can be presented by ``SBJCodableEditor``.
///
/// Normally this conformance is synthesized by ``SBJStructure()``.
public protocol SBJEditable: SBJStructured {

    @MainActor
    static var sbjEditorFields: [SBJEditorField<Self>] { get }
}

public extension SBJEditable {
    /// Type-erased field count used by the recursive editor when it only has
    /// an `any SBJEditable.Type`. Unlike `sbjEditorFields`, this does not expose
    /// `Self` in its result type, so it is safe to call through the existential.
    @MainActor
    internal static var _sbjEditorFieldCount: Int {
        Self.sbjEditorFields.count
    }

    @MainActor
    internal static func _sbjCollectIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry
    ) -> [SBJEditorIssue] {
        guard let typed = value as? Self else { return [] }
        return Self.sbjEditorFields.flatMap { field in
            field.issues(root: typed, path: path, registry: registry)
        }
    }

    /// Human-readable default name used for nested disclosure groups.
    static var sbjEditorTypeName: String {
        String(describing: Self.self).uncamelCased
    }

    @MainActor
    internal static func _sbjMakeEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue? = nil,
        registry: SBJEditorRegistry,
        itemActions: SBJEditorItemActions? = nil,
        focusRequest: SBJEditorFocusRequest? = nil,
        titleIsUnknown: Bool = false
    ) -> AnyView {
        let typedBinding = Binding<Self>(
            get: { binding.get() as! Self },
            set: { binding.set($0) }
        )

        return AnyView(
            SBJObjectEditor(
                title: label,
                value: typedBinding,
                originalValue: originalValue.map { $0.value(as: Self.self) },
                registry: registry,
                itemActions: itemActions,
                focusRequest: focusRequest,
                titleIsUnknown: titleIsUnknown
            )
        )
    }
    @MainActor
    internal static func _sbjMakeEditorContents(
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue? = nil,
        registry: SBJEditorRegistry,
        focusRequest: SBJEditorFocusRequest? = nil
    ) -> AnyView {
        let typedBinding = Binding<Self>(
            get: { binding.get() as! Self },
            set: { binding.set($0) }
        )
        return AnyView(
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(Self.sbjEditorFields.enumerated()), id: \.offset) { _, field in
                    field.view(root: typedBinding, originalRoot: originalValue.map { $0.value(as: Self.self) }, registry: registry, focusRequest: focusRequest)
                }
            }
        )
    }

}
