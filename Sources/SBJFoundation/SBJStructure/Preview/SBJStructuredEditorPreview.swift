#if DEBUG
import SwiftUI

// This is the living compile/sample fixture for SubjectEditor and SBJStructure.
// Every SBJStructure annotation must be declared somewhere in this file. The
// sample is intentionally allowed to be contrived to keep annotation coverage
// explicit. See Documentation/SBJStructure/SAMPLE_COVERAGE.md for the stricter compile-dependency definition
// used for all other framework files.

private enum RecipeCourse: String, Codable, CaseIterable, Hashable {
    case breakfast
    case lunch
    case dinner
    case dessert
}

private enum IngredientUnit: String, Codable, CaseIterable, Hashable {
    case gram
    case kilogram
    case milliliter
    case liter
    case teaspoon
    case tablespoon
    case cup
    case item
}

@SBJStructure
private enum RecipeHeatSetting: Codable {
    case none
    case oven(celsius: Int, convection: Bool)
    case burner(level: Int)
}

private struct RecipeRating: Codable, Equatable {
    var value: Int
}

@SBJStructure
private struct RecipeNutrition: Codable {
    @SBJInteger(range: 0...2_500)
    var caloriesPerServing: Int

    @SBJNumber(range: 0...200)
    var proteinGrams: Double

    // @SBJDesignatedInit is primarily consumed by Swift-source export, but the
    // SubjectEditor preview intentionally declares every annotation.
    @SBJDesignatedInit
    init(caloriesPerServing: Int = 420, proteinGrams: Double = 14.5) {
        self.caloriesPerServing = caloriesPerServing
        self.proteinGrams = proteinGrams
    }
}

@SBJStructure
private struct RecipeIngredient: Codable, Hashable {
    var id = UUID()

    @SBJString(minLength: 1, maxLength: 60)
    var name = "New ingredient"

    @SBJNumber(range: 0...2_000)
    var quantity: Decimal = 1

    var unit: IngredientUnit = .item

    @SBJString(maxLength: 80)
    var preparation: String? = nil
}

@SBJStructure
private struct RecipeStep: Codable, Hashable {
    var id = UUID()

    @SBJString(minLength: 1, maxLength: 50)
    var title = "New step"

    @SBJString(.multiline, minLength: 1, maxLength: 600)
    var instruction = "Describe what to do."
}

@SBJStructure
private struct MealRecipe: Codable {
    @SBJString(minLength: 1, maxLength: 80)
    var name = "Roasted Vegetable Pasta"

    @SBJString(.multiline, minLength: 1, maxLength: 400)
    var summary = "Roasted peppers, cauliflower, and onion tossed with pasta and a simple olive-oil dressing."

    @SBJInteger(range: 1...24)
    var servings = 4

    @SBJInteger(range: 0...480)
    var preparationMinutes = 20

    @SBJInteger(range: 0...720)
    var cookingMinutes = 35

    var course: RecipeCourse = .dinner
    var vegetarian = true
    var rating = RecipeRating(value: 4)

    // UnitValue is a first-class Codable leaf editor: amount + unit are edited
    // together, and changing the unit preserves the represented quantity.
    var servingVolume = UnitValue<VolumeUnit>(1.5, unit: .cup)
    var packageWeight = UnitValue<MassUnit>(340, unit: .gram)
    var simmerTime = UnitValue<DurationUnit>(45, unit: .minute)
    var panDepth: UnitValue<LengthUnit>? = .init(2, unit: .inch)

    @SBJDate(range: Date(timeIntervalSince1970: 0)...Date(timeIntervalSince1970: 4_102_444_800))
    var lastMade: Date? = Date()

    @SBJOptional(required: true)
    @SBJURL(allowed: [.network])
    var sourceURL: URL? = URL(string: "https://example.com/roasted-vegetable-pasta")

    @SBJData(min: 4, max: 16, modulo: 4)
    var importFingerprint = Data([0x52, 0x43, 0x50, 0x45])

    @SBJColor(alpha: false)
    var recipeCardTint = CodableColor(0.85, 0.35, 0.15, 1.0)

    @SBJPresentation(.fontFamily)
    var recipeCardFontFamily: String? = nil

    var nutrition = RecipeNutrition()
    var heatSetting: RecipeHeatSetting = .oven(celsius: 220, convection: true)

    @SBJArray(
        reorderable: true,
        title: \RecipeIngredient.name,
        minCount: 1,
        maxCount: 30,
        uniqueBy: \RecipeIngredient.id
    )
    var ingredients = [
        RecipeIngredient(name: "Red bell pepper", quantity: 2, unit: .item, preparation: "sliced"),
        RecipeIngredient(name: "Cauliflower", quantity: 500, unit: .gram, preparation: "cut into florets"),
        RecipeIngredient(name: "Yellow onion", quantity: 1, unit: .item, preparation: "sliced"),
        RecipeIngredient(name: "Olive oil", quantity: 2.5, unit: .tablespoon),
        RecipeIngredient(name: "Pasta", quantity: 340, unit: .gram)
    ]

    @SBJArray(
        reorderable: true,
        title: \RecipeStep.title,
        minCount: 1,
        maxCount: 20,
        uniqueBy: \RecipeStep.id
    )
    var steps = [
        RecipeStep(title: "Roast the vegetables", instruction: "Roast the peppers, cauliflower, and onion until browned at the edges and tender."),
        RecipeStep(title: "Cook the pasta", instruction: "Cook the pasta until al dente, reserving a little cooking water."),
        RecipeStep(title: "Combine", instruction: "Toss the pasta and roasted vegetables with olive oil. Add reserved cooking water as needed.")
    ]

    @SBJSet(minCount: 1, maxCount: 12)
    var tags: Set<String> = ["Weeknight", "Vegetarian", "Roasted"]

    @SBJDictionary(maxCount: 12)
    var substitutions: [String: String] = [
        "Red bell pepper": "Orange bell pepper",
        "Pasta": "Whole-wheat pasta"
    ]

    @SBJString(.sheetEdit, maxLength: 1_000)
    var notes: String? = "Add red-pepper flakes at the table for anyone who wants more heat."

    // Editor-only computed adapter: deliberately redundant with the stored name
    // so the preview compiles through the @SBJEditorProperty code path.
    @SBJEditorProperty
    var editorDisplayName: String {
        get { name }
        set { name = newValue }
    }

    @SBJUUID(nonzero: true)
    var identifier = UUID()

    @SBJNotEditable
    var importSource = "Preview fixture"

    static func propertyInfo<Value>(for keyPath: KeyPath<Self, Value>) -> SBJPropertyInfo? {
        switch keyPath as AnyKeyPath {
        case \Self.servings:
            return SBJPropertyInfo(
                title: "Servings",
                summary: "The number of portions the recipe is intended to make.",
                details: "The structural constraint is 1 through 24. The editor uses that domain knowledge to keep this numeric field compact without fixing it to one point size.",
                accessibilityLabel: "Recipe servings",
                accessibilityHint: "Enter the number of portions this recipe makes"
            )
        case \Self.lastMade:
            return SBJPropertyInfo(
                summary: "Optional date of the most recent preparation.",
                details: "The system date editor follows the user's locale and calendar preferences."
            )
        default:
            return nil
        }
    }
}

@MainActor
private struct SBJStructuredEditorPreviewHost: View {
    @State private var value: MealRecipe
    @State private var editorState = SBJEditorViewState()
    @State private var hasAppliedRegressionMutation = false
    private let regressionMutation: ((inout MealRecipe) -> Void)?

    init(
        value: MealRecipe = MealRecipe(),
        regressionMutation: ((inout MealRecipe) -> Void)? = nil
    ) {
        _value = State(initialValue: value)
        self.regressionMutation = regressionMutation
    }

    private var registry: SBJEditorRegistry {
        var registry = SBJEditorRegistry()
        registry.register(RecipeRating.self) { label, binding, _ in
            HStack(spacing: 8) {
                Text(label)
                Stepper(value: Binding(
                    get: { binding.wrappedValue.value },
                    set: { binding.wrappedValue.value = min(5, max(0, $0)) }
                ), in: 0...5) {
                    Text(binding.wrappedValue.value.formatted())
                }
            }
        }
        return registry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Meal Recipe Editor")
                    .font(.headline)
                Text("A living structural editor example used by both the preview and README. Try larger Dynamic Type, another locale, and right-to-left layout while editing the same model.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            SBJEditorSearchView(value: value, state: $editorState, registry: registry)

            ScrollView {
                SBJEditorView(value: $value, state: $editorState, registry: registry)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
        .onAppear {
            guard !hasAppliedRegressionMutation, let regressionMutation else { return }
            hasAppliedRegressionMutation = true
            regressionMutation(&value)
        }
    }
}

#Preview("Meal Recipe — Default") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .frame(minWidth: 760, minHeight: 1_000)
}

#Preview("Meal Recipe — Large Type") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .environment(\.dynamicTypeSize, .accessibility3)
        .frame(minWidth: 760, minHeight: 1_000)
}

#Preview("Meal Recipe — French") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .environment(\.locale, Locale(identifier: "fr_FR"))
        .frame(minWidth: 760, minHeight: 1_000)
}

#Preview("Meal Recipe — Right to Left") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .environment(\.layoutDirection, .rightToLeft)
        .frame(minWidth: 760, minHeight: 1_000)
}
// Increased Contrast, Differentiate Without Color, and Reduce Transparency
// are read-only environment values on this target. Exercise those variants with
// Xcode's Environment Overrides / Accessibility Inspector rather than attempting
// to inject them with `.environment(...)`.

#Preview("Meal Recipe — Dark") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .preferredColorScheme(.dark)
        .frame(minWidth: 760, minHeight: 1_000)
}

#Preview("Regression — Narrow + AX5") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .environment(\.dynamicTypeSize, .accessibility5)
        .frame(width: 390)
        .frame(minHeight: 1_000)
}

#Preview("Regression — German") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .environment(\.locale, Locale(identifier: "de_DE"))
        .frame(minWidth: 760, minHeight: 1_000)
}

#Preview("Regression — Arabic RTL") {
    SBJStructuredEditorPreviewHost()
        .padding()
        .environment(\.locale, Locale(identifier: "ar_SA"))
        .environment(\.layoutDirection, .rightToLeft)
        .frame(minWidth: 760, minHeight: 1_000)
}

#Preview("Regression — Changed Empty Invalid") {
    SBJStructuredEditorPreviewHost(regressionMutation: { recipe in
        recipe.servings = 0
        recipe.notes = nil
        recipe.summary = ""
        recipe.ingredients[0].quantity = 2.75
        recipe.ingredients[0].preparation = nil
    })
    .padding()
    .frame(minWidth: 760, minHeight: 1_000)
}

#endif
