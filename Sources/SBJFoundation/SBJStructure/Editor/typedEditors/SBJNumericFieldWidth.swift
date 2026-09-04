import Foundation
import SwiftUI

/// Domain-informed sizing for compact scalar controls.
///
/// The numbers here are nominal body-text dimensions, not rigid screen-space
/// widths. ``SBJPreferredFieldWidthModifier`` scales them with Dynamic Type.
/// The finite maximum keeps small-domain controls compact in wide editors,
/// while the scaled range still leaves room for larger fonts and localized
/// punctuation.
struct SBJFieldSizing: Sendable, Equatable {
    let minimum: CGFloat
    let ideal: CGFloat
    let maximum: CGFloat
}

enum SBJNumericFieldWidth {
    static let unboundedInteger = SBJFieldSizing(minimum: 88, ideal: 120, maximum: 168)
    static let unboundedNumber = SBJFieldSizing(minimum: 96, ideal: 140, maximum: 196)

    static func integer(range: ClosedRange<Int>?, locale: Locale) -> SBJFieldSizing {
        guard let range, range.upperBound != Int.max else {
            return unboundedInteger
        }

        let lower = range.lowerBound.formatted(.number.locale(locale))
        let upper = range.upperBound.formatted(.number.locale(locale))
        return boundedSizing(
            characterCount: max(lower.count, upper.count),
            minimum: 64,
            maximum: 176
        )
    }

    static func number(range: ClosedRange<Double>?, locale: Locale) -> SBJFieldSizing {
        guard let range, range.upperBound != Double.greatestFiniteMagnitude else {
            return unboundedNumber
        }

        let lower = range.lowerBound.formatted(.number.locale(locale))
        let upper = range.upperBound.formatted(.number.locale(locale))
        return boundedSizing(
            characterCount: max(lower.count, upper.count),
            minimum: 80,
            maximum: 208
        )
    }

    private static func boundedSizing(
        characterCount: Int,
        minimum: CGFloat,
        maximum: CGFloat
    ) -> SBJFieldSizing {
        // This estimate is only a preference. The actual values are scaled by
        // Dynamic Type and deliberately provide headroom for localized glyphs.
        let ideal = min(maximum, max(minimum, CGFloat(characterCount) * 10 + 28))
        return SBJFieldSizing(
            minimum: max(minimum, ideal * 0.78),
            ideal: ideal,
            maximum: min(maximum, max(ideal, ideal * 1.30))
        )
    }
}

private struct SBJPreferredFieldWidthModifier: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var minimum: CGFloat = 0
    @ScaledMetric(relativeTo: .body) private var ideal: CGFloat = 0
    @ScaledMetric(relativeTo: .body) private var maximum: CGFloat = 0

    init(sizing: SBJFieldSizing) {
        _minimum = ScaledMetric(wrappedValue: sizing.minimum, relativeTo: .body)
        _ideal = ScaledMetric(wrappedValue: sizing.ideal, relativeTo: .body)
        _maximum = ScaledMetric(wrappedValue: sizing.maximum, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content.frame(
            minWidth: minimum,
            idealWidth: ideal,
            maxWidth: maximum,
            alignment: .leading
        )
    }
}

extension View {
    /// Keeps a domain-constrained editor compact without freezing it to one
    /// point size. The nominal sizing scales with Dynamic Type.
    func sbjPreferredFieldWidth(_ sizing: SBJFieldSizing) -> some View {
        modifier(SBJPreferredFieldWidthModifier(sizing: sizing))
    }
}

enum SBJTextFieldWidth {
    /// Single-line text constraints are useful layout information, but maximum
    /// character count is not a literal pixel width. Use broad tiers so short
    /// domain values stay compact while ordinary prose remains flexible.
    static func singleLine(maximumLength: Int?) -> SBJFieldSizing? {
        guard let maximumLength else { return nil }
        switch maximumLength {
        case ...12:
            return SBJFieldSizing(minimum: 88, ideal: 120, maximum: 176)
        case 13...24:
            return SBJFieldSizing(minimum: 120, ideal: 180, maximum: 248)
        case 25...48:
            return SBJFieldSizing(minimum: 160, ideal: 240, maximum: 336)
        case 49...96:
            return SBJFieldSizing(minimum: 200, ideal: 320, maximum: 448)
        default:
            return nil
        }
    }
}
