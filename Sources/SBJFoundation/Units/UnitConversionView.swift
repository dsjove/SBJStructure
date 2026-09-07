import SwiftUI

@MainActor
public struct UnitConversionView<Unit: UnitType>: View {
    @Bindable private var model: UnitConversionModel<Unit>
    private let units: [Unit]
    private let editingPolicy: UnitEditingPolicy<Unit>?

    public init(
        model: UnitConversionModel<Unit>,
        units: [Unit] = Array(Unit.allCases),
        editingPolicy: UnitEditingPolicy<Unit>? = nil
    ) {
        self.model = model
        self.units = units
        self.editingPolicy = editingPolicy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                UnitValueControl(value: $model.source, units: units, accessibilityLabel: "From")

                if let editingPolicy {
                    Stepper(
                        onIncrement: { model.step(using: editingPolicy, increasing: true) },
                        onDecrement: { model.step(using: editingPolicy, increasing: false) }
                    ) { EmptyView() }
                    .labelsHidden()
                }

                Button {
                    model.reset()
                } label: {
                    Image(.system("1.square"))
                }
                .accessibilityLabel("Reset value")
            }

            HStack(spacing: 10) {
                Text(model.source.unit.displayName)
                    .foregroundStyle(.secondary)

                Button {
                    model.swap()
                } label: {
                    Image(.system("arrow.left.arrow.right"))
                }
                .accessibilityLabel("Swap units")

                Menu {
                    ForEach(units) { unit in
                        Button(unit.displayName) {
                            model.destinationUnit = unit
                        }
                    }
                } label: {
                    SBJCompactMenuLabel(text: model.destinationUnit.symbol)
                }
                .accessibilityLabel("To unit")
                .accessibilityValue(model.destinationUnit.displayName)
            }

            LabeledContent("Result") {
                HStack(spacing: 4) {
                    Text(model.result.value.formatted(.number))
                        .contentTransition(.numericText())
                    Text(model.result.unit.symbol)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

/// Ready-made multi-dimension conversion tool suitable for an app utility
/// screen. Domain apps can instead host `UnitConversionView` directly with
/// narrower allowed units and their own editing policy.
@MainActor
public struct UnitConversionToolView: View {
    @State private var category: UnitCategory
    @State private var length = UnitConversionModel(
        source: UnitValue<LengthUnit>(1, unit: .inch),
        destinationUnit: .centimeter
    )
    @State private var mass = UnitConversionModel(
        source: UnitValue<MassUnit>(1, unit: .ounce),
        destinationUnit: .gram
    )
    @State private var volume = UnitConversionModel(
        source: UnitValue<VolumeUnit>(1, unit: .tablespoon),
        destinationUnit: .cup
    )
    @State private var duration = UnitConversionModel(
        source: UnitValue<DurationUnit>(1, unit: .hour),
        destinationUnit: .minute
    )

    public init(category: UnitCategory = .volume) {
        _category = State(initialValue: category)
    }

    public var body: some View {
        VStack(spacing: 16) {
            Picker("Category", selection: $category) {
                ForEach(UnitCategory.allCases, id: \.self) { category in
                    Text(categoryTitle(category)).tag(category)
                }
            }
            .pickerStyle(.segmented)

            switch category {
            case .length:
                UnitConversionView(model: length)
            case .mass:
                UnitConversionView(model: mass)
            case .volume:
                UnitConversionView(model: volume)
            case .duration:
                UnitConversionView(model: duration)
            }
        }
    }

    private func categoryTitle(_ category: UnitCategory) -> String {
        switch category {
        case .length: "Length"
        case .mass: "Weight"
        case .duration: "Time"
        case .volume: "Volume"
        }
    }
}
