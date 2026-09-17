#if !os(watchOS) && !os(tvOS) && canImport(UIKit)
import Foundation
import Testing
@testable import SBJFoundation

@Suite("Photo edit behavior")
struct PhotoEditBehaviorTests {
    @Test func ratioCropCanTransposeDimensions() {
        let option = PhotoCropOption.ratio(width: 4, height: 3)
        let source = CGSize(width: 400, height: 300)

		#expect(abs(option.aspectRatio(
			sourceSize: source,
			freeAspectRatio: 1,
			swappingDimensions: false
		) - (4.0 / 3.0)) < 0.000_001)

		#expect(abs(option.aspectRatio(
			sourceSize: source,
			freeAspectRatio: 1,
			swappingDimensions: true
		) - (3.0 / 4.0)) < 0.000_001)
    }

    @Test func photoEditorOptionsRoundTripThroughCodable() throws {
        let original = PhotoEditorOptions(
            cropOptions: [.none, .square, .ratio(width: 5, height: 7)],
            allowsQuarterTurnRotation: false,
            allowsFreeRotation: true,
            allowsMirror: false,
            framingConstraint: .cover,
            allowsNoneFraming: false,
            maximumMagnification: 5,
            renderCropGhost: -1,
            allowsMarkup: false,
            allowsShare: false
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(PhotoEditorOptions.self, from: data)
        #expect(decoded == original)
    }

    @Test func olderCropStateWithoutSwapFlagDecodesUnswapped() throws {
        let current = PhotoCropState(
            option: .ratio(width: 4, height: 3),
            sourceSize: CGSize(width: 400, height: 300),
            swapsDimensions: true
        )
        let encoded = try JSONEncoder().encode(current)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "swapsDimensions")
        let oldData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(PhotoCropState.self, from: oldData)
        #expect(decoded.swapsDimensions == false)
    }
}
#endif
