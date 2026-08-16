import SwiftUI

/// Application-supplied custom editors and value factories.
///
/// The registry intentionally matches exact Swift types. SBJStructure's built-in
/// renderer handles its generic categories first-class; applications use this
/// registry for domain values such as dice expressions, money, coordinates, or
/// application-specific identifiers.
public struct SBJEditorRegistry {
    private var editors: [ObjectIdentifier: Any] = [:]
    private var lineItems: [SBJEditorLineItemKey: Any] = [:]
    private var creators: [ObjectIdentifier: Any] = [:]

    public init() {}

    /// Registers a custom SwiftUI editor for one exact value type.
    ///
    /// A custom editor takes precedence over SBJStructure's built-in rendering.
    @MainActor
    public mutating func register<Value, Content: View>(
        _ type: Value.Type,
        @ViewBuilder editor: @escaping @MainActor (
            _ label: String,
            _ value: Binding<Value>,
            _ registry: SBJEditorRegistry
        ) -> Content
    ) {
        editors[ObjectIdentifier(type)] = SBJEditorRegistration<Value> { label, binding, registry in
            AnyView(editor(label, binding, registry))
        }
    }

    /// Registers an application-specific presentation override for one exact property.
    ///
    /// The callback receives SBJStructure's normal rendered line so applications can
    /// decorate it without reimplementing the property's built-in editor.
    @MainActor
    public mutating func registerLineItem<Root, Value, Content: View>(
        _ keyPath: WritableKeyPath<Root, Value>,
        @ViewBuilder lineItem: @escaping @MainActor (
            _ label: String,
            _ value: Binding<Value>,
            _ defaultContent: AnyView,
            _ registry: SBJEditorRegistry
        ) -> Content
    ) {
        let key = SBJEditorLineItemKey(root: Root.self, keyPath: keyPath)
        lineItems[key] = SBJEditorLineItemRegistration<Root, Value> { label, binding, defaultContent, registry in
            AnyView(lineItem(label, binding, defaultContent, registry))
        }
    }

    /// Registers a factory used by collection `+` controls and nil optionals.
    public mutating func registerCreator<Value>(
        _ type: Value.Type,
        create: @escaping () -> Value
    ) {
        creators[ObjectIdentifier(type)] = SBJCreatorRegistration<Value>(create: create)
    }

    func hasCustomEditor<Value>(_ type: Value.Type) -> Bool {
        editors[ObjectIdentifier(type)] != nil
    }

    @MainActor
    func customEditor<Value>(
        label: String,
        binding: Binding<Value>
    ) -> AnyView? {
        guard let registration = editors[ObjectIdentifier(Value.self)] as? SBJEditorRegistration<Value> else {
            return nil
        }
        return registration.makeView(label, binding, self)
    }

    @MainActor
    func customLineItem<Root, Value>(
        keyPath: WritableKeyPath<Root, Value>,
        label: String,
        binding: Binding<Value>,
        defaultContent: AnyView
    ) -> AnyView? {
        let key = SBJEditorLineItemKey(root: Root.self, keyPath: keyPath)
        guard let registration = lineItems[key] as? SBJEditorLineItemRegistration<Root, Value> else {
            return nil
        }
        return registration.makeView(label, binding, defaultContent, self)
    }

    func createArrayElement<Value>(_ type: Value.Type, existing: [Value]) -> Value? {
        if let arrayCreatableType = type as? any SBJEditorArrayCreatable.Type,
           let value = arrayCreatableType._sbjCreateEditorValue(existing: existing) as? Value {
            return value
        }
        return create(type)
    }

    func create<Value>(_ type: Value.Type) -> Value? {
        if let registration = creators[ObjectIdentifier(type)] as? SBJCreatorRegistration<Value> {
            return registration.create()
        }
        return SBJEditorDefaultValue.value(for: type)
    }
}

private struct SBJEditorRegistration<Value> {
    let makeView: @MainActor (String, Binding<Value>, SBJEditorRegistry) -> AnyView
}

private struct SBJEditorLineItemKey: Hashable {
    let root: ObjectIdentifier
    let keyPath: AnyKeyPath

    init<Root, Value>(root: Root.Type, keyPath: WritableKeyPath<Root, Value>) {
        self.root = ObjectIdentifier(root)
        self.keyPath = keyPath
    }
}

private struct SBJEditorLineItemRegistration<Root, Value> {
    let makeView: @MainActor (String, Binding<Value>, AnyView, SBJEditorRegistry) -> AnyView
}

private struct SBJCreatorRegistration<Value> {
    let create: () -> Value
}


