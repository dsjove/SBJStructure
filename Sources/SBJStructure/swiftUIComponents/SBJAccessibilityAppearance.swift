import SwiftUI

/// Small presentation policy used by the generated editor for system
/// accessibility appearance preferences. These values affect only chrome;
/// structural state is still carried by symbols, labels, and validation data.
enum SBJAccessibilityAppearance {
    static func secondaryStrokeOpacity(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 0.90 : 0.65
    }

    static func subtleStrokeOpacity(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 0.80 : 0.55
    }

    static func hierarchyCueOpacity(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 0.55 : 0.28
    }

    static func headerFillOpacity(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 0.16 : 0.08
    }

    static func invalidFillOpacity(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 0.18 : 0.10
    }

    static func borderThickness(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 1.5 : 1.0
    }

    static func focusThickness(_ contrast: ColorSchemeContrast) -> Double {
        contrast == .increased ? 3.0 : 2.0
    }
}
