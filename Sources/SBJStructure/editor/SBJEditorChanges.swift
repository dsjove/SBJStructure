import SwiftUI

private struct SBJEditorShowChangedOnlyKey: EnvironmentKey {
    static let defaultValue = false
}

private struct SBJEditorIsChangedKey: EnvironmentKey {
    static let defaultValue = false
}

private struct SBJEditorShowEmptyContentOnlyKey: EnvironmentKey {
    static let defaultValue = false
}

private struct SBJEditorHasContentKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

private struct SBJEditorIsInvalidKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var sbjEditorShowChangedOnly: Bool {
        get { self[SBJEditorShowChangedOnlyKey.self] }
        set { self[SBJEditorShowChangedOnlyKey.self] = newValue }
    }

    var sbjEditorShowEmptyContentOnly: Bool {
        get { self[SBJEditorShowEmptyContentOnlyKey.self] }
        set { self[SBJEditorShowEmptyContentOnlyKey.self] = newValue }
    }

    var sbjEditorIsChanged: Bool {
        get { self[SBJEditorIsChangedKey.self] }
        set { self[SBJEditorIsChangedKey.self] = newValue }
    }

    var sbjEditorHasContent: Bool? {
        get { self[SBJEditorHasContentKey.self] }
        set { self[SBJEditorHasContentKey.self] = newValue }
    }

    var sbjEditorIsInvalid: Bool {
        get { self[SBJEditorIsInvalidKey.self] }
        set { self[SBJEditorIsInvalidKey.self] = newValue }
    }
}


struct SBJEditorOriginalValue {
    let storage: Any

    init<Value>(_ value: Value) {
        self.storage = value as Any
    }

    func value<Value>(as type: Value.Type = Value.self) -> Value {
        storage as! Value
    }
}


struct SBJEditorChangeIndicator: View {
    @Environment(\.sbjEditorIsChanged) private var isChanged

    var body: some View {
        if isChanged {
            Circle()
                .fill(Color.accentColor)
                .frame(width: 7, height: 7)
                .accessibilityHidden(true)
        }
    }
}

/// Subtle marker for editor values whose domain-level `hasContent` is false.
/// Values that do not implement `HasContentCheckable` have no marker.
struct SBJEditorEmptyContentIndicator: View {
    @Environment(\.sbjEditorHasContent) private var hasContent

    var body: some View {
        if hasContent == false {
            Circle()
                .stroke(.secondary, lineWidth: 1)
                .frame(width: 7, height: 7)
                .accessibilityLabel("No content")
        }
    }
}

private struct SBJEditorValidationLineBackground: ViewModifier {
    let isInvalid: Bool

    func body(content: Content) -> some View {
        content.background(alignment: .top) {
            if isInvalid {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.red.opacity(0.10))
                    .frame(height: 34)
                    .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func sbjEditorValidationLineBackground(_ isInvalid: Bool) -> some View {
        modifier(SBJEditorValidationLineBackground(isInvalid: isInvalid))
    }
}
