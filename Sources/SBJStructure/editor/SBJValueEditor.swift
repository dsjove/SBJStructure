import Foundation
import SwiftUI
import UIKit

@MainActor
struct SBJEditorItemActions {
    let remove: () -> Void
    let moveUp: (() -> Void)?
    let moveDown: (() -> Void)?

    var leadingView: AnyView {
        AnyView(
            Button(action: remove) {
                Image(systemName: "minus.circle")
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Remove item")
        )
    }

    var trailingView: AnyView {
        guard moveUp != nil || moveDown != nil else {
            return AnyView(EmptyView())
        }
        return AnyView(
            HStack(spacing: 6) {
                Button {
                    moveUp?()
                } label: {
                    Image(systemName: "arrow.up.circle")
                }
                .buttonStyle(.borderless)
                .disabled(moveUp == nil)
                .accessibilityLabel("Move item up")

                Button {
                    moveDown?()
                } label: {
                    Image(systemName: "arrow.down.circle")
                }
                .buttonStyle(.borderless)
                .disabled(moveDown == nil)
                .accessibilityLabel("Move item down")
            }
        )
    }
}

@MainActor
final class SBJEditorFocusRequest {
    private var claimed = false

    func claim() -> Bool {
        guard !claimed else { return false }
        claimed = true
        return true
    }
}

private protocol _SBJOptionalValue {
    @MainActor
    static func _sbjOptionalEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue?,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        dateRange: ClosedRange<Date>?,
        colorSupportsAlpha: Bool,
        collectionReorderable: Bool,
        collectionItemTitleKey: String?,
        itemActions: SBJEditorItemActions?,
        focusRequest: SBJEditorFocusRequest?
    ) -> AnyView
}

private protocol _SBJCollectionValue {
    @MainActor
    static func _sbjCollectionEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue?,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        reorderable: Bool,
        itemTitleKey: String?,
        itemActions: SBJEditorItemActions?,
        focusRequest: SBJEditorFocusRequest?
    ) -> AnyView
}

private protocol _SBJOptionalIssueValue {
    @MainActor
    static func _sbjCollectEditorIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry,
        collectionItemTitleKey: String?
    ) -> [SBJEditorIssue]
}

private protocol _SBJCollectionIssueValue {
    @MainActor
    static func _sbjCollectEditorIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry,
        itemTitleKey: String?
    ) -> [SBJEditorIssue]
}

private protocol _SBJOptionalContentValue {
    @MainActor
    static func _sbjContainsEmptyContent(
        value: Any,
        registry: SBJEditorRegistry
    ) -> Bool
}

private protocol _SBJCollectionContentValue {
    @MainActor
    static func _sbjContainsEmptyContent(
        value: Any,
        registry: SBJEditorRegistry
    ) -> Bool
}

extension Optional: _SBJOptionalContentValue {
    @MainActor
    static func _sbjContainsEmptyContent(
        value: Any,
        registry: SBJEditorRegistry
    ) -> Bool {
        guard let optional = value as? Wrapped?, let wrapped = optional else { return true }
        return SBJValueEditor.containsEmptyContent(value: wrapped, registry: registry)
    }
}

extension Array: _SBJCollectionContentValue {
    @MainActor
    static func _sbjContainsEmptyContent(
        value: Any,
        registry: SBJEditorRegistry
    ) -> Bool {
        guard let values = value as? [Element] else { return false }
        return values.contains { element in
            SBJValueEditor.containsEmptyContent(value: element, registry: registry)
        }
    }
}


extension Set: _SBJCollectionContentValue {
    @MainActor
    static func _sbjContainsEmptyContent(
        value: Any,
        registry: SBJEditorRegistry
    ) -> Bool {
        guard let values = value as? Set<Element> else { return false }
        return values.contains { element in
            SBJValueEditor.containsEmptyContent(value: element, registry: registry)
        }
    }
}

extension Dictionary: _SBJCollectionContentValue {
    @MainActor
    static func _sbjContainsEmptyContent(
        value: Any,
        registry: SBJEditorRegistry
    ) -> Bool {
        guard let values = value as? [Key: Value] else { return false }
        return values.values.contains { element in
            SBJValueEditor.containsEmptyContent(value: element, registry: registry)
        }
    }
}

extension Optional: _SBJOptionalIssueValue {
    @MainActor
    static func _sbjCollectEditorIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry,
        collectionItemTitleKey: String?
    ) -> [SBJEditorIssue] {
        guard let optional = value as? Wrapped?, let wrapped = optional else { return [] }
        return SBJValueEditor.collectIssues(
            value: wrapped,
            path: path,
            registry: registry,
            collectionItemTitleKey: collectionItemTitleKey
        )
    }
}

extension Array: _SBJCollectionIssueValue {
    @MainActor
    static func _sbjCollectEditorIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry,
        itemTitleKey: String?
    ) -> [SBJEditorIssue] {
        guard let values = value as? [Element] else { return [] }
        return values.enumerated().flatMap { offset, element in
            let title = SBJValueEditor.arrayItemTitle(
                element: element,
                index: offset,
                key: itemTitleKey
            )
            return SBJValueEditor.collectIssues(
                value: element,
                path: path + [title],
                registry: registry
            )
        }
    }
}


extension Set: _SBJCollectionIssueValue {
    @MainActor
    static func _sbjCollectEditorIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry,
        itemTitleKey: String?
    ) -> [SBJEditorIssue] {
        guard let values = value as? Set<Element> else { return [] }
        return SBJValueEditor.deterministicallySorted(values).flatMap { element in
            let title = SBJValueEditor.collectionItemTitle(element: element, key: itemTitleKey)
            return SBJValueEditor.collectIssues(
                value: element,
                path: path + [title],
                registry: registry
            )
        }
    }
}

extension Dictionary: _SBJCollectionIssueValue {
    @MainActor
    static func _sbjCollectEditorIssues(
        value: Any,
        path: [String],
        registry: SBJEditorRegistry,
        itemTitleKey: String?
    ) -> [SBJEditorIssue] {
        guard let values = value as? [Key: Value] else { return [] }
        return SBJValueEditor.deterministicallySortedDictionary(values).flatMap { key, element in
            SBJValueEditor.collectIssues(
                value: element,
                path: path + ["[\(String(describing: key))]"],
                registry: registry
            )
        }
    }
}

extension Optional: _SBJOptionalValue where Wrapped: Codable {
    @MainActor
    static func _sbjOptionalEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue?,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        dateRange: ClosedRange<Date>?,
        colorSupportsAlpha: Bool,
        collectionReorderable: Bool,
        collectionItemTitleKey: String?,
        itemActions: SBJEditorItemActions?,
        focusRequest: SBJEditorFocusRequest?
    ) -> AnyView {
        let typed = Binding<Wrapped?>(
            get: { binding.get() as! Wrapped? },
            set: { binding.set($0 as Any) }
        )
        return AnyView(
            SBJOptionalEditor(
                label: label,
                value: typed,
                originalValue: originalValue.map { $0.value(as: Wrapped?.self) },
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange,
                dateRange: dateRange,
                colorSupportsAlpha: colorSupportsAlpha,
                collectionReorderable: collectionReorderable,
                collectionItemTitleKey: collectionItemTitleKey,
                itemActions: itemActions,
                focusRequest: focusRequest
            )
        )
    }
}

extension Array: _SBJCollectionValue where Element: Codable {
    @MainActor
    static func _sbjCollectionEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue?,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        reorderable: Bool,
        itemTitleKey: String?,
        itemActions: SBJEditorItemActions?,
        focusRequest: SBJEditorFocusRequest?
    ) -> AnyView {
        let typed = Binding<[Element]>(
            get: { binding.get() as! [Element] },
            set: { binding.set($0) }
        )
        return AnyView(
            SBJArrayEditor(
                label: label,
                value: typed,
                originalValue: originalValue.map { $0.value(as: [Element].self) },
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange,
                reorderable: reorderable,
                itemTitleKey: itemTitleKey,
                itemActions: itemActions,
                focusRequest: focusRequest
            )
        )
    }
}


extension Set: _SBJCollectionValue where Element: Codable {
    @MainActor
    static func _sbjCollectionEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue?,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        reorderable: Bool,
        itemTitleKey: String?,
        itemActions: SBJEditorItemActions?,
        focusRequest: SBJEditorFocusRequest?
    ) -> AnyView {
        let typed = Binding<Set<Element>>(
            get: { binding.get() as! Set<Element> },
            set: { binding.set($0) }
        )
        return AnyView(
            SBJSetEditor(
                label: label,
                value: typed,
                originalValue: originalValue.map { $0.value(as: Set<Element>.self) },
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange,
                itemTitleKey: itemTitleKey,
                itemActions: itemActions,
                focusRequest: focusRequest
            )
        )
    }
}

extension Dictionary: _SBJCollectionValue where Key: Codable, Value: Codable {
    @MainActor
    static func _sbjCollectionEditor(
        label: String,
        binding: SBJAnyBinding,
        originalValue: SBJEditorOriginalValue?,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        reorderable: Bool,
        itemTitleKey: String?,
        itemActions: SBJEditorItemActions?,
        focusRequest: SBJEditorFocusRequest?
    ) -> AnyView {
        let typed = Binding<[Key: Value]>(
            get: { binding.get() as! [Key: Value] },
            set: { binding.set($0) }
        )
        return AnyView(
            SBJDictionaryEditor(
                label: label,
                value: typed,
                originalValue: originalValue.map { $0.value(as: [Key: Value].self) },
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange,
                itemActions: itemActions,
                focusRequest: focusRequest
            )
        )
    }
}

enum SBJValueEditor {
    @MainActor
    static func makeView<Value>(
        label: String,
        value: Binding<Value>,
        originalValue: SBJEditorOriginalValue? = nil,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle? = nil,
        integerRange: ClosedRange<Int>? = nil,
        numberRange: ClosedRange<Double>? = nil,
        dateRange: ClosedRange<Date>? = nil,
        colorSupportsAlpha: Bool = true,
        collectionReorderable: Bool = true,
        collectionItemTitleKey: String? = nil,
        itemActions: SBJEditorItemActions? = nil,
        focusRequest: SBJEditorFocusRequest? = nil,
        labelIsUnknown: Bool = false
    ) -> AnyView {
        if let custom = registry.customEditor(label: label, binding: value) {
            return wrapLeaf(custom, itemActions: itemActions)
        }

        if Value.self == String.self {
            let binding = castBinding(value, to: String.self)
            switch textStyle ?? .singleLine {
            case .singleLine:
                return wrapLeaf(AnyView(SBJSingleLineTextEditor(label: label, value: binding, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
            case .multiline:
                return wrapLeaf(AnyView(SBJMultilineTextEditor(label: label, value: binding, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
            }
        }
        if Value.self == Bool.self {
            let binding = castBinding(value, to: Bool.self)
            return wrapLeaf(AnyView(SBJBooleanEditor(label: label, value: binding, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == Int.self {
            return wrapLeaf(
                AnyView(SBJIntegerEditor(label: label, value: castBinding(value, to: Int.self), range: integerRange, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)),
                itemActions: itemActions
            )
        }
        if Value.self == Double.self {
            return wrapLeaf(
                AnyView(SBJDoubleEditor(label: label, value: castBinding(value, to: Double.self), range: numberRange, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)),
                itemActions: itemActions
            )
        }
        if Value.self == Float.self {
            let double = Binding<Double>(
                get: { Double(castBinding(value, to: Float.self).wrappedValue) },
                set: { castBinding(value, to: Float.self).wrappedValue = Float($0) }
            )
            return wrapLeaf(AnyView(SBJDoubleEditor(label: label, value: double, range: numberRange, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == CGFloat.self {
            let double = Binding<Double>(
                get: { Double(castBinding(value, to: CGFloat.self).wrappedValue) },
                set: { castBinding(value, to: CGFloat.self).wrappedValue = CGFloat($0) }
            )
            return wrapLeaf(AnyView(SBJDoubleEditor(label: label, value: double, range: numberRange, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == Decimal.self {
            return wrapLeaf(AnyView(SBJDecimalEditor(label: label, value: castBinding(value, to: Decimal.self), range: numberRange, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == Int8.self { return numericTextView(label: label, value: castBinding(value, to: Int8.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == Int16.self { return numericTextView(label: label, value: castBinding(value, to: Int16.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == Int32.self { return numericTextView(label: label, value: castBinding(value, to: Int32.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == Int64.self { return numericTextView(label: label, value: castBinding(value, to: Int64.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == UInt.self { return numericTextView(label: label, value: castBinding(value, to: UInt.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == UInt8.self { return numericTextView(label: label, value: castBinding(value, to: UInt8.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == UInt16.self { return numericTextView(label: label, value: castBinding(value, to: UInt16.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == UInt32.self { return numericTextView(label: label, value: castBinding(value, to: UInt32.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == UInt64.self { return numericTextView(label: label, value: castBinding(value, to: UInt64.self), itemActions: itemActions, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown) }
        if Value.self == Date.self {
            return wrapLeaf(AnyView(SBJDateEditor(label: label, value: castBinding(value, to: Date.self), range: dateRange, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == URL.self {
            return wrapLeaf(AnyView(SBJURLEditor(label: label, value: castBinding(value, to: URL.self), focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == UUID.self {
            return wrapLeaf(AnyView(SBJUUIDEditor(label: label, value: castBinding(value, to: UUID.self), focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == Data.self {
            return wrapLeaf(AnyView(SBJDataEditor(label: label, value: castBinding(value, to: Data.self), focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        if Value.self == CodableColor.self {
            return wrapLeaf(AnyView(SBJColorEditor(label: label, value: castBinding(value, to: CodableColor.self), supportsAlpha: colorSupportsAlpha, labelIsUnknown: labelIsUnknown)), itemActions: itemActions)
        }
        let erased = SBJAnyBinding(value)

        if let optional = Value.self as? any _SBJOptionalValue.Type {
            return optional._sbjOptionalEditor(
                label: label,
                binding: erased,
                originalValue: originalValue,
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange,
                dateRange: dateRange,
                colorSupportsAlpha: colorSupportsAlpha,
                collectionReorderable: collectionReorderable,
                collectionItemTitleKey: collectionItemTitleKey,
                itemActions: itemActions,
                focusRequest: focusRequest
            )
        }
        if let collection = Value.self as? any _SBJCollectionValue.Type {
            return collection._sbjCollectionEditor(
                label: label,
                binding: erased,
                originalValue: originalValue,
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange,
                reorderable: collectionReorderable,
                itemTitleKey: collectionItemTitleKey,
                itemActions: itemActions,
                focusRequest: focusRequest
            )
        }
        if let associatedEnum = Value.self as? any SBJEditableAssociatedEnum.Type {
            return wrapLeaf(
                associatedEnum._sbjMakeAssociatedEnumEditor(
                    label: label,
                    binding: erased,
                    originalValue: originalValue,
                    registry: registry,
                    focusRequest: focusRequest,
                    labelIsUnknown: labelIsUnknown
                ),
                itemActions: itemActions
            )
        }
        if let editable = Value.self as? any SBJEditable.Type {
            return editable._sbjMakeEditor(
                label: label,
                binding: erased,
                originalValue: originalValue,
                registry: registry,
                itemActions: itemActions,
                focusRequest: focusRequest,
                titleIsUnknown: labelIsUnknown
            )
        }
        if let options = caseIterableOptions(for: Value.self) {
            return wrapLeaf(
                AnyView(SBJCaseIterableEditor(label: label, value: value, options: options, labelIsUnknown: labelIsUnknown)),
                itemActions: itemActions
            )
        }

        // Unknown Codable values remain visible as unsupported rather than being
        // silently omitted. Applications can register a custom exact-type editor.
        return wrapLeaf(
            AnyView(SBJUnsupportedEditor(label: label, type: Value.self, value: value.wrappedValue, labelIsUnknown: labelIsUnknown)),
            itemActions: itemActions
        )
    }

    @MainActor
    static func makeFontFamilyView(
        label: String,
        value: Binding<String?>,
        labelIsUnknown: Bool
    ) -> AnyView {
        AnyView(SBJFontFamilyEditor(label: label, value: value, labelIsUnknown: labelIsUnknown))
    }

    @MainActor
    static func collectIssues<Value>(
        value: Value,
        path: [String],
        registry: SBJEditorRegistry,
        collectionItemTitleKey: String? = nil
    ) -> [SBJEditorIssue] {
        if registry.hasCustomEditor(Value.self) { return [] }
        if Value.self == String.self || Value.self == Bool.self || Value.self == Int.self ||
            Value.self == Int8.self || Value.self == Int16.self || Value.self == Int32.self || Value.self == Int64.self ||
            Value.self == UInt.self || Value.self == UInt8.self || Value.self == UInt16.self || Value.self == UInt32.self || Value.self == UInt64.self ||
            Value.self == Double.self || Value.self == Float.self || Value.self == CGFloat.self || Value.self == Decimal.self ||
            Value.self == Date.self || Value.self == URL.self || Value.self == UUID.self || Value.self == Data.self ||
            Value.self == CodableColor.self { return [] }

        if let optional = Value.self as? any _SBJOptionalIssueValue.Type {
            return optional._sbjCollectEditorIssues(
                value: value,
                path: path,
                registry: registry,
                collectionItemTitleKey: collectionItemTitleKey
            )
        }
        if let collection = Value.self as? any _SBJCollectionIssueValue.Type {
            return collection._sbjCollectEditorIssues(
                value: value,
                path: path,
                registry: registry,
                itemTitleKey: collectionItemTitleKey
            )
        }
        if let associatedEnum = Value.self as? any SBJEditableAssociatedEnum.Type {
            return associatedEnum._sbjCollectAssociatedEnumIssues(value: value, path: path, registry: registry)
        }
        if let editable = Value.self as? any SBJEditable.Type {
            return editable._sbjCollectIssues(value: value, path: path, registry: registry)
        }
        if caseIterableOptions(for: Value.self) != nil { return [] }

        return [
            SBJEditorIssue(
                path: path.joined(separator: " • "),
                typeName: String(describing: Value.self),
                valueDescription: SBJEditorValueDescription.describe(value)
            )
        ]
    }

    @MainActor
    static func containsEmptyContent<Value>(
        value: Value,
        registry: SBJEditorRegistry
    ) -> Bool {
        if let checkable = value as? any HasContentCheckable, !checkable.hasContent {
            return true
        }

        if registry.hasCustomEditor(Value.self) { return false }

        if let optional = Value.self as? any _SBJOptionalContentValue.Type {
            return optional._sbjContainsEmptyContent(value: value, registry: registry)
        }
        if let collection = Value.self as? any _SBJCollectionContentValue.Type {
            return collection._sbjContainsEmptyContent(value: value, registry: registry)
        }
        if let associatedEnum = Value.self as? any SBJEditableAssociatedEnum.Type {
            return associatedEnum._sbjContainsEmptyContent(value: value, registry: registry)
        }
        if let editable = Value.self as? any SBJEditable.Type {
            return editable._sbjContainsEmptyContent(value: value, registry: registry)
        }

        return false
    }

    static func matchesSearch<Value>(
        label: String,
        value: Value,
        query: String,
        registry: SBJEditorRegistry,
        collectionItemTitleKey: String? = nil
    ) -> Bool {
        let needle = normalizedSearchText(query)
        guard !needle.isEmpty else { return true }

        if normalizedSearchText(label).contains(needle) { return true }
        if let description = SBJEditorValueDescription.describe(value),
           normalizedSearchText(description).contains(needle) { return true }
        if normalizedSearchText(String(describing: value)).contains(needle) { return true }

        return false
    }

    static func titleMatchesSearch(_ title: String, query: String) -> Bool {
        let needle = normalizedSearchText(query)
        guard !needle.isEmpty else { return false }
        return normalizedSearchText(title).contains(needle)
    }

    private static func normalizedSearchText(_ value: String) -> String {
        value.lowercased().filter { $0.isLetter || $0.isNumber }
    }

    static func arrayItemTitle<Element>(
        element: Element,
        index: Int,
        key: String?
    ) -> String {
        guard let key,
              let raw = propertyValue(named: key, in: element),
              let title = displayTitle(raw),
              !title.isEmpty else {
            return "[\(index)]"
        }
        return title
    }


    static func collectionItemTitle<Element>(element: Element, key: String?) -> String {
        if let key,
           let raw = propertyValue(named: key, in: element),
           let title = displayTitle(raw),
           !title.isEmpty {
            return title
        }
        return displayTitle(element) ?? String(describing: element)
    }

    static func deterministicallySorted<Element>(_ values: Set<Element>) -> [Element] {
        values.sorted { lhs, rhs in
            compareForDisplay(lhs, rhs)
        }
    }

    static func deterministicallySortedDictionary<Key, Value>(_ values: [Key: Value]) -> [(Key, Value)] {
        values.sorted { lhs, rhs in
            compareForDisplay(lhs.key, rhs.key)
        }
    }

    private static func compareForDisplay<T>(_ lhs: T, _ rhs: T) -> Bool {
        switch (lhs, rhs) {
        case let (lhs as String, rhs as String): return lhs.localizedStandardCompare(rhs) == .orderedAscending
        case let (lhs as Int, rhs as Int): return lhs < rhs
        case let (lhs as Int8, rhs as Int8): return lhs < rhs
        case let (lhs as Int16, rhs as Int16): return lhs < rhs
        case let (lhs as Int32, rhs as Int32): return lhs < rhs
        case let (lhs as Int64, rhs as Int64): return lhs < rhs
        case let (lhs as UInt, rhs as UInt): return lhs < rhs
        case let (lhs as UInt8, rhs as UInt8): return lhs < rhs
        case let (lhs as UInt16, rhs as UInt16): return lhs < rhs
        case let (lhs as UInt32, rhs as UInt32): return lhs < rhs
        case let (lhs as UInt64, rhs as UInt64): return lhs < rhs
        case let (lhs as Double, rhs as Double): return lhs < rhs
        case let (lhs as Float, rhs as Float): return lhs < rhs
        default:
            let left = collectionItemTitle(element: lhs, key: nil)
            let right = collectionItemTitle(element: rhs, key: nil)
            let result = left.localizedStandardCompare(right)
            if result != .orderedSame { return result == .orderedAscending }
            return String(reflecting: lhs) < String(reflecting: rhs)
        }
    }

    private static func propertyValue(named key: String, in value: Any) -> Any? {
        var mirror: Mirror? = Mirror(reflecting: value)
        while let current = mirror {
            for child in current.children where child.label == key {
                return child.value
            }
            mirror = current.superclassMirror
        }
        return nil
    }

    private static func displayTitle(_ value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            guard let child = mirror.children.first else { return nil }
            return displayTitle(child.value)
        }
        if let string = value as? String { return string }
        return String(describing: value).uncamelCased
    }

    @MainActor
    private static func numericTextView<T: LosslessStringConvertible>(
        label: String,
        value: Binding<T>,
        itemActions: SBJEditorItemActions?,
        focusRequest: SBJEditorFocusRequest?,
        labelIsUnknown: Bool
    ) -> AnyView {
        wrapLeaf(
            AnyView(SBJLosslessNumericEditor(label: label, value: value, focusRequest: focusRequest, labelIsUnknown: labelIsUnknown)),
            itemActions: itemActions
        )
    }

    @MainActor
    private static func wrapLeaf(_ view: AnyView, itemActions: SBJEditorItemActions?) -> AnyView {
        guard let itemActions else { return view }
        return AnyView(
            HStack(alignment: .center, spacing: 8) {
                itemActions.leadingView
                view
                itemActions.trailingView
            }
        )
    }

    @MainActor
    private static func castBinding<From, To>(
        _ binding: Binding<From>,
        to: To.Type
    ) -> Binding<To> {
        Binding<To>(
            get: { binding.wrappedValue as! To },
            set: { binding.wrappedValue = $0 as! From }
        )
    }
}

private struct SBJEditorFieldName: View {
    let text: String
    let isUnknown: Bool

    var body: some View {
        HStack(spacing: 5) {
            SBJEditorChangeIndicator()
            SBJEditorEmptyContentIndicator()
            if isUnknown {
                Text(text)
                    .fontWeight(.semibold)
                    .italic()
            } else {
                Text(text)
            }
        }
    }
}

private struct SBJSingleLineTextEditor: View {
    let label: String
    @Binding var value: String
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", text: $value)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

private struct SBJMultilineTextEditor: View {
    let label: String
    @Binding var value: String
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextEditor(text: $value)
                .focused($isFocused)
                .frame(minHeight: 84)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(.secondary.opacity(0.35), lineWidth: 1)
                )
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

private enum SBJNumericFieldWidth {
    static let unboundedInteger: CGFloat = 120
    static let unboundedNumber: CGFloat = 140

    static func integer(range: ClosedRange<Int>?) -> CGFloat {
        guard let range, range.upperBound != Int.max else {
            return unboundedInteger
        }
        let characters = max(String(range.lowerBound).count, String(range.upperBound).count)
        return boundedWidth(characterCount: characters)
    }

    static func number(range: ClosedRange<Double>?) -> CGFloat {
        guard let range, range.upperBound != Double.greatestFiniteMagnitude else {
            return unboundedNumber
        }
        let lower = String(format: "%g", range.lowerBound)
        let upper = String(format: "%g", range.upperBound)
        return boundedWidth(characterCount: max(lower.count, upper.count), minimum: 88, maximum: 180)
    }

    private static func boundedWidth(
        characterCount: Int,
        minimum: CGFloat = 72,
        maximum: CGFloat = 160
    ) -> CGFloat {
        min(maximum, max(minimum, CGFloat(characterCount) * 10 + 28))
    }
}

private struct SBJIntegerEditor: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: SBJNumericFieldWidth.integer(range: range))
                .focused($isFocused)
                .overlay {
                    if let range, !range.contains(value) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.red, lineWidth: 1)
                    }
                }
#if os(iOS)
                .keyboardType(.numbersAndPunctuation)
#endif
            Stepper("", value: $value)
                .labelsHidden()
                .fixedSize()
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

private struct SBJDoubleEditor: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: SBJNumericFieldWidth.number(range: range))
                .focused($isFocused)
                .overlay {
                    if let range, !range.contains(value) {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(.red, lineWidth: 1)
                    }
                }
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
        }
        .onAppear(perform: claimFocus)
    }

    private func claimFocus() {
        if focusRequest?.claim() == true {
            isFocused = true
        }
    }
}

private struct SBJLosslessNumericEditor<Value: LosslessStringConvertible>: View {
    let label: String
    @Binding var value: Value
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text: String = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", text: Binding(
                get: { text.isEmpty && !isFocused ? String(value) : text },
                set: { newValue in
                    text = newValue
                    if let parsed = Value(newValue) {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: SBJNumericFieldWidth.unboundedInteger)
            .focused($isFocused)
            .overlay {
                if !isValid {
                    RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: 1)
                }
            }
#if os(iOS)
            .keyboardType(.numbersAndPunctuation)
#endif
        }
        .onAppear {
            text = String(value)
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = String(value)
                isValid = true
            }
        }
    }
}

private struct SBJDecimalEditor: View {
    let label: String
    @Binding var value: Decimal
    let range: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    if let parsed = Decimal(string: newValue, locale: Locale(identifier: "en_US_POSIX")) {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
            .frame(width: SBJNumericFieldWidth.number(range: range))
            .focused($isFocused)
            .overlay {
                let number = NSDecimalNumber(decimal: value).doubleValue
                if !isValid || (range.map { !$0.contains(number) } ?? false) {
                    RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: 1)
                }
            }
#if os(iOS)
            .keyboardType(.decimalPad)
#endif
        }
        .onAppear {
            text = NSDecimalNumber(decimal: value).stringValue
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = NSDecimalNumber(decimal: value).stringValue
                isValid = true
            }
        }
    }
}

private struct SBJDateEditor: View {
    let label: String
    @Binding var value: Date
    let range: ClosedRange<Date>?
    let labelIsUnknown: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            DatePicker("", selection: $value)
                .labelsHidden()
        }
    }
}

private struct SBJURLEditor: View {
    let label: String
    @Binding var value: URL
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @Environment(\.openURL) private var openURL
    @State private var text = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    private var parsedURL: URL? {
        text.sbjURL
    }

    private var openableURL: URL? {
        guard let parsedURL, parsedURL.scheme != nil else { return nil }
        return parsedURL
    }

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    if let parsed = newValue.sbjURL {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .overlay {
                if !isValid { RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: 1) }
            }
#if os(iOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
#endif
            Button("Open") {
                if let openableURL { openURL(openableURL) }
            }
            .buttonStyle(.borderless)
            .disabled(openableURL == nil)
            .accessibilityLabel("Open \(label)")
        }
        .accessibilityValue(value.absoluteString)
        .onAppear {
            text = value.absoluteString
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = value.absoluteString
                isValid = true
            }
        }
    }
}

private struct SBJUUIDEditor: View {
    let label: String
    @Binding var value: UUID
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text = ""
    @State private var isValid = true
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            TextField("", text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    if let parsed = newValue.sbjUUID {
                        value = parsed
                        isValid = true
                    } else {
                        isValid = false
                    }
                }
            ))
            .textFieldStyle(.roundedBorder)
            .focused($isFocused)
            .overlay {
                if !isValid { RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: 1) }
            }
#if os(iOS)
            .textInputAutocapitalization(.characters)
#endif
            Button {
                value = UUID()
                text = value.uuidString
                isValid = true
            } label: {
                Image(systemName: "arrow.clockwise.circle")
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Generate new \(label)")
        }
        .accessibilityValue(value.uuidString)
        .onAppear {
            text = value.uuidString
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused {
                text = value.uuidString
                isValid = true
            }
        }
    }

}

private struct SBJDataEditor: View {
    let label: String
    @Binding var value: Data
    let focusRequest: SBJEditorFocusRequest?
    let labelIsUnknown: Bool
    @State private var text = ""
    @State private var errorMessage: String?
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
                Spacer()
                Text("\(value.count) byte\(value.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            TextEditor(text: Binding(
                get: { text },
                set: { newValue in
                    text = newValue
                    do {
                        value = try newValue.sbjHexData()
                        errorMessage = nil
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
            ))
            .font(.system(.body, design: .monospaced))
            .focused($isFocused)
            .frame(minHeight: 90)
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(errorMessage == nil ? Color.secondary.opacity(0.35) : Color.red, lineWidth: 1)
            )
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(Color.red)
            }
        }
        .accessibilityValue("\(value.count) byte\(value.count == 1 ? "" : "s")")
        .onAppear {
            text = value.sbjHexFormat()
            if focusRequest?.claim() == true { isFocused = true }
        }
        .onChange(of: isFocused) { _, focused in
            if !focused, errorMessage == nil {
                text = value.sbjHexFormat()
            }
        }
    }
}

private struct SBJColorEditor: View {
    let label: String
    @Binding var value: CodableColor
    let supportsAlpha: Bool
    let labelIsUnknown: Bool
    @Environment(\.self) private var environment

    private var colorBinding: Binding<Color> {
        Binding(
            get: { value.swiftUIColor },
            set: { newColor in
                value = CodableColor(color: newColor.resolve(in: environment))
            }
        )
    }

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            ColorPicker("", selection: colorBinding, supportsOpacity: supportsAlpha)
                .labelsHidden()
            Spacer()
        }
        .accessibilityValue(
            supportsAlpha
                ? "Red \(Int((value.red * 255).rounded())), green \(Int((value.green * 255).rounded())), blue \(Int((value.blue * 255).rounded())), opacity \(Int((value.opacity * 100).rounded())) percent"
                : "Red \(Int((value.red * 255).rounded())), green \(Int((value.green * 255).rounded())), blue \(Int((value.blue * 255).rounded()))"
        )
    }
}

private struct SBJFontFamilyEditor: View {
    let label: String
    @Binding var value: String?
    let labelIsUnknown: Bool

    private var fontFamilies: [String] {
        let available = CodableFontCache.shared.availableFontFamilies
        guard let current = value, !available.contains(current) else {
            return available
        }
        return [current] + available
    }

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            Picker("", selection: $value) {
                Text("System").tag(Optional<String>.none)
                ForEach(fontFamilies, id: \.self) { family in
                    Text(family).tag(Optional(family))
                }
            }
            .labelsHidden()
#if os(iOS)
            .pickerStyle(.menu)
#endif
            Spacer(minLength: 0)
        }
    }
}

private struct SBJOptionalEditor<Wrapped: Codable>: View {
    let label: String
    @Binding var value: Wrapped?
    let originalValue: Wrapped??
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let dateRange: ClosedRange<Date>?
    let colorSupportsAlpha: Bool
    let collectionReorderable: Bool
    let collectionItemTitleKey: String?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    @State private var isExpanded = false
    @State private var pendingFocus: SBJEditorFocusRequest?
    @Environment(\.sbjEditorSearchQuery) private var searchQuery
    @Environment(\.sbjEditorShowChangedOnly) private var showChangedOnly
    @Environment(\.sbjEditorShowEmptyContentOnly) private var showEmptyContentOnly
    @Environment(\.sbjEditorHasContent) private var hasContent

    private var disclosureBinding: Binding<Bool> {
        Binding(
            get: { isExpanded || !searchQuery.isEmpty || showChangedOnly || (showEmptyContentOnly && hasContent != false) },
            set: { newValue in
                if searchQuery.isEmpty && !showChangedOnly && !showEmptyContentOnly {
                    isExpanded = newValue
                }
            }
        )
    }

    var body: some View {
        if showEmptyContentOnly && hasContent == false {
            HStack(alignment: .center, spacing: 8) {
                if let itemActions {
                    itemActions.leadingView
                }
                if value != nil {
                    clearButton
                }
                SBJEditorFieldName(text: label, isUnknown: false)
                    .fontWeight((Wrapped.self as? any SBJEditable.Type) != nil ? .semibold : .regular)
                Spacer(minLength: 0)
                if let itemActions {
                    itemActions.trailingView
                }
            }
        } else if let unwrapped = Binding($value) {
            if let editable = Wrapped.self as? any SBJEditable.Type {
                if editable._sbjEditorFieldCount == 1 {
                    HStack(alignment: .center, spacing: 8) {
                        if let itemActions {
                            itemActions.leadingView
                        }
                        clearButton
                        editable._sbjMakeEditor(
                            label: label,
                            binding: SBJAnyBinding(unwrapped),
                            originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                            registry: registry,
                            focusRequest: pendingFocus ?? focusRequest
                        )
                        if let itemActions {
                            itemActions.trailingView
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        SBJEditorDisclosureHeader(
                            label,
                            isExpanded: disclosureBinding,
                            leadingActions: AnyView(
                                HStack(spacing: 6) {
                                    if let itemActions {
                                        itemActions.leadingView
                                    }
                                    clearButton
                                }
                            ),
                            trailingActions: itemActions?.trailingView ?? AnyView(EmptyView())
                        )

                        if isExpanded || !searchQuery.isEmpty || showChangedOnly || showEmptyContentOnly {
                            let childSearchQuery = SBJValueEditor.titleMatchesSearch(label, query: searchQuery) ? "" : searchQuery
                            editable._sbjMakeEditorContents(
                                binding: SBJAnyBinding(unwrapped),
                                originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                                registry: registry,
                                focusRequest: pendingFocus ?? focusRequest
                            )
                            .environment(\.sbjEditorSearchQuery, childSearchQuery)
                            .padding(.leading, 15).frame(maxWidth: .infinity)

                            Divider()
                        }
                    }
                }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    if let itemActions {
                        itemActions.leadingView
                    }
                    clearButton
                    SBJValueEditor.makeView(
                        label: label,
                        value: unwrapped,
                        originalValue: originalWrapped.map { SBJEditorOriginalValue($0) },
                        registry: registry,
                        textStyle: textStyle,
                        integerRange: integerRange,
                        numberRange: numberRange,
                        dateRange: dateRange,
                        colorSupportsAlpha: colorSupportsAlpha,
                        collectionReorderable: collectionReorderable,
                        collectionItemTitleKey: collectionItemTitleKey,
                        focusRequest: pendingFocus ?? focusRequest
                    )
                    if let itemActions {
                        itemActions.trailingView
                    }
                }
            }
        } else {
            HStack(spacing: 8) {
                if let itemActions {
                    itemActions.leadingView
                }
                if Wrapped.self is any SBJEditable.Type {
                    Color.clear.frame(width: 22, height: 1)
                }
                Button {
                    value = registry.create(Wrapped.self)
                    if value != nil {
                        isExpanded = true
                        pendingFocus = SBJEditorFocusRequest()
                    }
                } label: {
                    Image(systemName: "circle.dashed")
                }
                .buttonStyle(.borderless)
                .disabled(registry.create(Wrapped.self) == nil)
                .accessibilityLabel("Set \(label)")
                SBJEditorFieldName(text: label, isUnknown: false)
                    .fontWeight((Wrapped.self as? any SBJEditable.Type) != nil ? .semibold : .regular)
                Spacer()
                if let itemActions {
                    itemActions.trailingView
                }
            }
        }
    }

    private var originalWrapped: Wrapped? {
        guard let originalValue else { return nil }
        return originalValue
    }

    private var clearButton: some View {
        Button {
            value = nil
            pendingFocus = nil
        } label: {
            Image(systemName: "xmark.circle")
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Clear \(label)")
    }
}

private struct SBJArrayEditor<Element: Codable>: View {
    let label: String
    @Binding var value: [Element]
    let originalValue: [Element]?
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let reorderable: Bool
    let itemTitleKey: String?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    @State private var isExpanded = false
    @State private var focusIndex: Int?
    @State private var pendingFocus: SBJEditorFocusRequest?
    @Environment(\.sbjEditorSearchQuery) private var searchQuery
    @Environment(\.sbjEditorShowChangedOnly) private var showChangedOnly
    @Environment(\.sbjEditorShowEmptyContentOnly) private var showEmptyContentOnly
    @Environment(\.sbjEditorHasContent) private var hasContent

    private var disclosureBinding: Binding<Bool> {
        Binding(
            get: { isExpanded || !searchQuery.isEmpty || showChangedOnly || (showEmptyContentOnly && hasContent != false) },
            set: { newValue in
                if searchQuery.isEmpty && !showChangedOnly && !showEmptyContentOnly {
                    isExpanded = newValue
                }
            }
        )
    }

    private var displayIndices: [Int] {
        Array(value.indices).filter { index in
            if showChangedOnly && !itemHasChanged(at: index) { return false }
            if showEmptyContentOnly && !SBJValueEditor.containsEmptyContent(value: value[index], registry: registry) {
                return false
            }
            guard !searchQuery.isEmpty else { return true }
            if SBJValueEditor.titleMatchesSearch(label, query: searchQuery) { return true }
            let title = itemTitle(for: value[index], index: index).text
            return SBJValueEditor.matchesSearch(
                label: title,
                value: value[index],
                query: searchQuery,
                registry: registry
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SBJEditorDisclosureHeader(
                "\(label) (\(value.count))",
                isExpanded: disclosureBinding,
                leadingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions {
                            itemActions.leadingView
                        }
                        Button {
                            if let newValue = registry.createArrayElement(Element.self, existing: value) {
                                value.append(newValue)
                                focusIndex = value.index(before: value.endIndex)
                                pendingFocus = SBJEditorFocusRequest()
                                isExpanded = true
                            }
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(registry.createArrayElement(Element.self, existing: value) == nil)
                        .accessibilityLabel("Add \(label)")
                    }
                ),
                trailingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions {
                            itemActions.trailingView
                        }
                    }
                )
            )

            if isExpanded || !searchQuery.isEmpty || showChangedOnly || showEmptyContentOnly {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(displayIndices.enumerated()), id: \.element) { displayOffset, index in
                        let itemLabel = itemTitle(for: value[index], index: displayOffset)
                        let itemSearchQuery = SBJValueEditor.titleMatchesSearch(label, query: searchQuery) ? "" : searchQuery
                        let itemInvalid = SBJInvariantCheck.validationError(
                            value[index],
                            at: SBJValidationKeyPath(\Element.self)
                        ) != nil
                        SBJValueEditor.makeView(
                            label: itemLabel.text,
                            value: Binding(
                                get: { value[index] },
                                set: { value[index] = $0 }
                            ),
                            originalValue: originalElement(at: index).map { SBJEditorOriginalValue($0) },
                            registry: registry,
                            textStyle: textStyle,
                            integerRange: integerRange,
                            numberRange: numberRange,
                            itemActions: actions(for: index),
                            focusRequest: index == focusIndex ? pendingFocus : focusRequest,
                            labelIsUnknown: itemLabel.isUnknown
                        )
                        .environment(\.sbjEditorSearchQuery, itemSearchQuery)
                        .environment(\.sbjEditorIsChanged, itemHasChanged(at: index))
                        .environment(\.sbjEditorHasContent, (value[index] as? any HasContentCheckable)?.hasContent)
                        .environment(\.sbjEditorIsInvalid, itemInvalid)
                        .sbjEditorValidationLineBackground(itemInvalid)
                    }
                }
                .padding(.leading, 15).frame(maxWidth: .infinity)
            }
        }
    }

    private func originalElement(at index: Int) -> Element? {
        guard let originalValue, originalValue.indices.contains(index) else { return nil }
        return originalValue[index]
    }

    private func itemHasChanged(at index: Int) -> Bool {
        guard value.indices.contains(index) else { return false }
        guard let original = originalElement(at: index) else { return true }
        return value[index].sbjEncodedIsDifferent(from: original)
    }

    private func itemTitle(for element: Element, index: Int) -> (text: String, isUnknown: Bool) {
        let prefix = "\(index + 1)) "
        guard let itemTitleKey,
              let raw = propertyValue(named: itemTitleKey, in: element),
              let title = displayTitle(raw),
              !title.isEmpty else {
            return (prefix + label, true)
        }
        return (prefix + title, false)
    }

    private func propertyValue(named key: String, in value: Any) -> Any? {
        var mirror: Mirror? = Mirror(reflecting: value)
        while let current = mirror {
            for child in current.children where child.label == key {
                return child.value
            }
            mirror = current.superclassMirror
        }
        return nil
    }

    private func displayTitle(_ value: Any) -> String? {
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            guard let child = mirror.children.first else { return nil }
            return displayTitle(child.value)
        }
        if let string = value as? String {
            return string
        }
        return String(describing: value).uncamelCased
    }

    private func actions(for index: Int) -> SBJEditorItemActions {
        SBJEditorItemActions(
            remove: {
                guard value.indices.contains(index) else { return }
                value.remove(at: index)
                if focusIndex == index {
                    focusIndex = nil
                    pendingFocus = nil
                } else if let focusIndex, focusIndex > index {
                    self.focusIndex = focusIndex - 1
                }
            },
            moveUp: reorderable && index > value.startIndex ? {
                guard value.indices.contains(index), value.indices.contains(index - 1) else { return }
                value.swapAt(index, index - 1)
            } : nil,
            moveDown: reorderable && value.indices.contains(index + 1) ? {
                guard value.indices.contains(index), value.indices.contains(index + 1) else { return }
                value.swapAt(index, index + 1)
            } : nil
        )
    }
}

private struct SBJSetEditor<Element: Codable & Hashable>: View {
    let label: String
    @Binding var value: Set<Element>
    let originalValue: Set<Element>?
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let itemTitleKey: String?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    @State private var isExpanded = false
    @Environment(\.sbjEditorSearchQuery) private var searchQuery
    @Environment(\.sbjEditorShowChangedOnly) private var showChangedOnly
    @Environment(\.sbjEditorShowEmptyContentOnly) private var showEmptyContentOnly
    @Environment(\.sbjEditorHasContent) private var hasContent

    private var disclosureBinding: Binding<Bool> {
        Binding(
            get: { isExpanded || !searchQuery.isEmpty || showChangedOnly || (showEmptyContentOnly && hasContent != false) },
            set: { newValue in
                if searchQuery.isEmpty && !showChangedOnly && !showEmptyContentOnly {
                    isExpanded = newValue
                }
            }
        )
    }

    private var displayElements: [Element] {
        SBJValueEditor.deterministicallySorted(value).filter { element in
            if showChangedOnly, originalValue?.contains(element) == true { return false }
            if showEmptyContentOnly && !SBJValueEditor.containsEmptyContent(value: element, registry: registry) {
                return false
            }
            guard !searchQuery.isEmpty else { return true }
            if SBJValueEditor.titleMatchesSearch(label, query: searchQuery) { return true }
            return SBJValueEditor.matchesSearch(
                label: SBJValueEditor.collectionItemTitle(element: element, key: itemTitleKey),
                value: element,
                query: searchQuery,
                registry: registry
            )
        }
    }

    private var addCandidate: Element? {
        guard let candidate = registry.create(Element.self), !value.contains(candidate) else { return nil }
        return candidate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SBJEditorDisclosureHeader(
                "\(label) (\(value.count))",
                isExpanded: disclosureBinding,
                leadingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.leadingView }
                        Button {
                            guard let candidate = addCandidate else { return }
                            value.insert(candidate)
                            isExpanded = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(addCandidate == nil)
                        .accessibilityLabel("Add \(label)")
                    }
                ),
                trailingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.trailingView }
                    }
                )
            )

            if isExpanded || !searchQuery.isEmpty || showChangedOnly || showEmptyContentOnly {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(displayElements, id: \.self) { element in
                        SBJSetEntryEditor(
                            element: element,
                            title: SBJValueEditor.collectionItemTitle(element: element, key: itemTitleKey),
                            registry: registry,
                            textStyle: textStyle,
                            integerRange: integerRange,
                            numberRange: numberRange,
                            focusRequest: focusRequest,
                            replace: { old, replacement in
                                value.sbjReplace(old, with: replacement)
                            },
                            remove: { value.remove(element) }
                        )
                    }
                }
                .padding(.leading, 15).frame(maxWidth: .infinity)
            }
        }
    }
}

private struct SBJSetEntryEditor<Element: Codable & Hashable>: View {
    let element: Element
    let title: String
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let replace: (Element, Element) -> Bool
    let remove: () -> Void
    @State private var draft: Element
    @State private var collision = false

    init(
        element: Element,
        title: String,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        focusRequest: SBJEditorFocusRequest?,
        replace: @escaping (Element, Element) -> Bool,
        remove: @escaping () -> Void
    ) {
        self.element = element
        self.title = title
        self.registry = registry
        self.textStyle = textStyle
        self.integerRange = integerRange
        self.numberRange = numberRange
        self.focusRequest = focusRequest
        self.replace = replace
        self.remove = remove
        _draft = State(initialValue: element)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 8) {
                Button(action: remove) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove \(title)")

                SBJValueEditor.makeView(
                    label: title,
                    value: $draft,
                    registry: registry,
                    textStyle: textStyle,
                    integerRange: integerRange,
                    numberRange: numberRange,
                    focusRequest: focusRequest
                )

                if draft != element {
                    Button {
                        collision = !replace(element, draft)
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Apply \(title)")
                }
            }
            if collision {
                Text("That value is already in the set.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: element) { _, newValue in
            draft = newValue
            collision = false
        }
        .onChange(of: draft) { _, _ in collision = false }
    }
}

private struct SBJDictionaryEditor<Key: Codable & Hashable, Value: Codable>: View {
    let label: String
    @Binding var value: [Key: Value]
    let originalValue: [Key: Value]?
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let itemActions: SBJEditorItemActions?
    let focusRequest: SBJEditorFocusRequest?
    @State private var isExpanded = false
    @Environment(\.sbjEditorSearchQuery) private var searchQuery
    @Environment(\.sbjEditorShowChangedOnly) private var showChangedOnly
    @Environment(\.sbjEditorShowEmptyContentOnly) private var showEmptyContentOnly
    @Environment(\.sbjEditorHasContent) private var hasContent

    private var disclosureBinding: Binding<Bool> {
        Binding(
            get: { isExpanded || !searchQuery.isEmpty || showChangedOnly || (showEmptyContentOnly && hasContent != false) },
            set: { newValue in
                if searchQuery.isEmpty && !showChangedOnly && !showEmptyContentOnly {
                    isExpanded = newValue
                }
            }
        )
    }

    private var displayEntries: [(Key, Value)] {
        SBJValueEditor.deterministicallySortedDictionary(value).filter { key, entryValue in
            if showChangedOnly {
                guard let old = originalValue?[key] else { return true }
                if !entryValue.sbjEncodedIsDifferent(from: old) { return false }
            }
            if showEmptyContentOnly && !SBJValueEditor.containsEmptyContent(value: entryValue, registry: registry) {
                return false
            }
            guard !searchQuery.isEmpty else { return true }
            if SBJValueEditor.titleMatchesSearch(label, query: searchQuery) { return true }
            return SBJValueEditor.matchesSearch(
                label: String(describing: key),
                value: entryValue,
                query: searchQuery,
                registry: registry
            )
        }
    }

    private var addCandidate: (Key, Value)? {
        guard let key = registry.create(Key.self),
              !value.keys.contains(key),
              let entryValue = registry.create(Value.self) else { return nil }
        return (key, entryValue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SBJEditorDisclosureHeader(
                "\(label) (\(value.count))",
                isExpanded: disclosureBinding,
                leadingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.leadingView }
                        Button {
                            guard let (key, entryValue) = addCandidate else { return }
                            value[key] = entryValue
                            isExpanded = true
                        } label: {
                            Image(systemName: "plus.circle")
                        }
                        .buttonStyle(.borderless)
                        .disabled(addCandidate == nil)
                        .accessibilityLabel("Add \(label)")
                    }
                ),
                trailingActions: AnyView(
                    HStack(spacing: 6) {
                        if let itemActions { itemActions.trailingView }
                    }
                )
            )

            if isExpanded || !searchQuery.isEmpty || showChangedOnly || showEmptyContentOnly {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(displayEntries.indices, id: \.self) { index in
                        let key = displayEntries[index].0
                        let entryValue = displayEntries[index].1
                        SBJDictionaryEntryEditor(
                            key: key,
                            entryValue: Binding(
                                get: { value[key] ?? entryValue },
                                set: { value[key] = $0 }
                            ),
                            originalValue: originalValue?[key],
                            registry: registry,
                            textStyle: textStyle,
                            integerRange: integerRange,
                            numberRange: numberRange,
                            focusRequest: focusRequest,
                            rename: { old, replacement in
                                value.sbjRenameKey(old, to: replacement)
                            },
                            remove: { value.removeValue(forKey: key) }
                        )
                    }
                }
                .padding(.leading, 15).frame(maxWidth: .infinity)
            }
        }
    }
}

private struct SBJDictionaryEntryEditor<Key: Codable & Hashable, Value: Codable>: View {
    let key: Key
    @Binding var entryValue: Value
    let originalValue: Value?
    let registry: SBJEditorRegistry
    let textStyle: SBJTextStyle?
    let integerRange: ClosedRange<Int>?
    let numberRange: ClosedRange<Double>?
    let focusRequest: SBJEditorFocusRequest?
    let rename: (Key, Key) -> Bool
    let remove: () -> Void
    @State private var draftKey: Key
    @State private var collision = false

    init(
        key: Key,
        entryValue: Binding<Value>,
        originalValue: Value?,
        registry: SBJEditorRegistry,
        textStyle: SBJTextStyle?,
        integerRange: ClosedRange<Int>?,
        numberRange: ClosedRange<Double>?,
        focusRequest: SBJEditorFocusRequest?,
        rename: @escaping (Key, Key) -> Bool,
        remove: @escaping () -> Void
    ) {
        self.key = key
        _entryValue = entryValue
        self.originalValue = originalValue
        self.registry = registry
        self.textStyle = textStyle
        self.integerRange = integerRange
        self.numberRange = numberRange
        self.focusRequest = focusRequest
        self.rename = rename
        self.remove = remove
        _draftKey = State(initialValue: key)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .center, spacing: 8) {
                Button(action: remove) {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove dictionary entry")

                SBJValueEditor.makeView(
                    label: "Key",
                    value: $draftKey,
                    registry: registry,
                    focusRequest: focusRequest
                )

                if draftKey != key {
                    Button {
                        collision = !rename(key, draftKey)
                    } label: {
                        Image(systemName: "checkmark.circle")
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Apply dictionary key")
                }
            }

            if collision {
                Text("That key already exists.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SBJValueEditor.makeView(
                label: String(describing: key),
                value: $entryValue,
                originalValue: originalValue.map { SBJEditorOriginalValue($0) },
                registry: registry,
                textStyle: textStyle,
                integerRange: integerRange,
                numberRange: numberRange
            )
            .padding(.leading, 15).frame(maxWidth: .infinity)
        }
        .onChange(of: key) { _, newValue in
            draftKey = newValue
            collision = false
        }
        .onChange(of: draftKey) { _, _ in collision = false }
    }
}

private struct SBJBooleanEditor: View {
    let label: String
    @Binding var value: Bool
    let labelIsUnknown: Bool

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            Toggle("", isOn: $value)
                .labelsHidden()
                .fixedSize()
            Spacer(minLength: 0)
        }
    }
}

private struct SBJCaseIterableEditor<Value>: View {
    let label: String
    @Binding var value: Value
    let options: [Value]
    let labelIsUnknown: Bool

    private var selectedIndex: Int {
        guard let current = value as? AnyHashable else { return 0 }
        return options.firstIndex { ($0 as? AnyHashable) == current } ?? 0
    }

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            Picker(
                "",
                selection: Binding(
                    get: { selectedIndex },
                    set: { index in
                        guard options.indices.contains(index) else { return }
                        value = options[index]
                    }
                )
            ) {
                ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                    Text(String(describing: option).uncamelCased).tag(index)
                }
            }
            .labelsHidden()
#if os(iOS)
            .pickerStyle(.menu)
#endif
            .fixedSize()
            Spacer(minLength: 0)
        }
    }
}

private func caseIterableOptions<Value>(for type: Value.Type) -> [Value]? {
    guard type is any Hashable.Type,
          let caseIterable = type as? any CaseIterable.Type else { return nil }
    let values = caseIterable.allCases.compactMap { $0 as? Value }
    return values.isEmpty ? nil : values
}

private struct SBJUnsupportedEditor<Value>: View {
    let label: String
    let type: Value.Type
    let value: Value
    let labelIsUnknown: Bool
    @Environment(\.sbjEditorShowIssues) private var showIssues

    var body: some View {
        HStack(spacing: 8) {
            SBJEditorFieldName(text: label, isUnknown: labelIsUnknown)
            if let description = SBJEditorValueDescription.describe(value) {
                Text(description)
                    .italic()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Button(action: showIssues) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Show editor issues")
        }
    }
}
