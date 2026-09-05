import SwiftUI

/// Compact reusable control for a numeric value paired with a unit.
///
/// Choosing another unit preserves the represented physical quantity by
/// converting the numeric value. Reinterpreting the same number in a different
/// unit is intentionally not the behavior of this control.
@MainActor
public struct UnitValueControl<Unit: UnitType>: View {
    @Binding private var value: UnitValue<Unit>
    private let units: [Unit]
    private let accessibilityLabel: String?
    @FocusState private var isFocused: Bool

    public init(
        value: Binding<UnitValue<Unit>>,
        units: [Unit] = Array(Unit.allCases),
        accessibilityLabel: String? = nil
    ) {
        _value = value
        self.units = units
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        HStack(spacing: 6) {
            TextField("", value: $value.value, format: .number)
                .oneLiner(isFocused: $isFocused)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 72, idealWidth: 96, maxWidth: 132)
#if os(iOS)
                .keyboardType(.decimalPad)
#endif
                .accessibilityLabel(accessibilityLabel ?? "Value")

            unitControl
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var unitControl: some View {
        if units.count <= 1 {
            Text(value.unit.symbol)
                .foregroundStyle(.secondary)
                .fixedSize()
                .accessibilityLabel("Unit")
                .accessibilityValue(value.unit.displayName)
        } else {
            Menu {
                ForEach(units) { option in
                    Button {
                        value = value.converted(to: option)
                    } label: {
                        if option == value.unit {
                            Label(option.displayName, image: .system("checkmark"))
                        } else {
                            Text(option.displayName)
                        }
                    }
                }
            } label: {
                SBJCompactMenuLabel(text: value.unit.symbol)
            }
            .controlSize(.mini)
            .fixedSize()
            .sbjActiveControl(horizontalPadding: 4, verticalPadding: 0)
            .accessibilityLabel("Unit")
            .accessibilityValue(value.unit.displayName)
        }
    }
}
