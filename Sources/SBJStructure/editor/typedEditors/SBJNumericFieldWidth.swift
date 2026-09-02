import Foundation
import SwiftUI

enum SBJNumericFieldWidth {
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

