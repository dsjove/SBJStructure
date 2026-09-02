import Foundation
import SwiftUI

struct SBJCaseIterableEditor<Value>: View {
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

func caseIterableOptions<Value>(for type: Value.Type) -> [Value]? {
    guard type is any Hashable.Type,
          let caseIterable = type as? any CaseIterable.Type else { return nil }
    let values = caseIterable.allCases.compactMap { $0 as? Value }
    return values.isEmpty ? nil : values
}

