/// A key-path-based validation location. Property components are real Swift
/// key paths; collection locations retain enough information to identify the
/// element that failed validation without turning model properties into strings.
public struct SBJValidationKeyPath: @unchecked Sendable, CustomStringConvertible {
    fileprivate enum Component {
        case property(AnyKeyPath)
        case index(Int)
        case key(String)
        case element(String)
    }

    fileprivate var components: [Component]

    public init<Root, Value>(_ keyPath: KeyPath<Root, Value>) {
        self.components = [.property(keyPath)]
    }

    fileprivate init(components: [Component]) {
        self.components = components
    }

    public func appending<Root, Value>(_ keyPath: KeyPath<Root, Value>) -> Self {
        .init(components: components + [.property(keyPath)])
    }

    public func appending(index: Int) -> Self {
        .init(components: components + [.index(index)])
    }

    /// Appends a dictionary key. The key is retained as a display description;
    /// the owning model property remains represented by its real Swift key path.
    public func appending<Key>(key: Key) -> Self {
        .init(components: components + [.key(String(describing: key))])
    }

    /// Appends a set member description. Sets have no stable numeric index, so
    /// validation identifies the member rather than manufacturing an ordering.
    public func appending<Element>(element: Element) -> Self {
        .init(components: components + [.element(String(describing: element))])
    }

    public func contains(property keyPath: AnyKeyPath) -> Bool {
        components.contains { component in
            if case .property(let candidate) = component { return candidate == keyPath }
            return false
        }
    }

    public var description: String {
        var result = ""
        for component in components {
            switch component {
            case .property(let keyPath):
                if !result.isEmpty { result += "." }
                result += String(describing: keyPath)
            case .index(let index):
                result += "[\(index)]"
            case .key(let key):
                result += "[\(String(reflecting: key))]"
            case .element(let element):
                result += "{\(element)}"
            }
        }
        return result
    }
}
