import Testing
import UIKit
@testable import SBJStructure

struct CodableFontTests {
    @Test func systemFontSortsBeforeNamedFontsWithoutCrashing() {
        let system = CodableFont(nil, ofSize: 12)
        let named = CodableFont("Helvetica", ofSize: 12)

        #expect(system < named)
        #expect(!(named < system))
    }

    @Test func comparableUsesAllFontTraits() {
        let regular = CodableFont("Helvetica", ofSize: 12)
        let bold = CodableFont("Helvetica", ofSize: 12, bold: true)
        let italic = CodableFont("Helvetica", ofSize: 12, bold: true, italic: true)

        #expect(regular < bold)
        #expect(bold < italic)
        #expect(!(italic < italic))
    }

    @Test func uncachedFontConvenienceSupportsScale() {
        let specification = CodableFont(nil, ofSize: 10)

        #expect(specification.font.pointSize == 10)
        #expect(specification.font(scale: 1.25).pointSize == 12.5)
    }

    @Test func cacheReusesFontsForIdenticalKeys() {
        let cache = CodableFontCache()
        let specification = CodableFont(nil, ofSize: 10, bold: true)

        let first = cache.font(for: specification, scale: 1.2)
        let second = cache.font(for: specification, scale: 1.2)

        #expect(first === second)
        #expect(first.pointSize == 12)
    }
}
