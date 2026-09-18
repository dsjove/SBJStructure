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
    @Test func olderGeometryDecodesIdentityReservedTransforms() throws {
        let geometry = PhotoEditGeometry(crop: .init(option: .none, sourceSize: CGSize(width: 400, height: 300)))
        let encoded = try JSONEncoder().encode(geometry)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        object.removeValue(forKey: "perspective")
        object.removeValue(forKey: "skew")
        let oldData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(PhotoEditGeometry.self, from: oldData)
        #expect(decoded.perspective == .identity)
        #expect(decoded.skew == .identity)
    }

    @Test func imageDocumentPackageRoundTripsPortableState() throws {
        let source = SBJResourceContent(data: Data([1, 2, 3]), contentType: .png)
        var geometry = PhotoEditGeometry(crop: .init(option: .square, freeAspectRatio: 1))
        geometry.rotation = .init(quarterTurns: 1, fineDegrees: 2.5)
        geometry.skew = .init(horizontalDegrees: 1.25)
        let document = SBJImageDocument(source: source, edits: .init(geometry: geometry))

        let restored = try SBJImageDocument(serializedRepresentation: document.serializedRepresentation)
        #expect(restored.source == source)
        #expect(restored.edits.geometry == geometry)
        #expect(restored.description.renderCapability == .partial(unsupportedFeatures: [.skew]))
    }

    @Test func cropMutationsOwnTheirDependentGeometryReset() {
        var geometry = PhotoEditGeometry(
            crop: .init(option: .ratio(width: 4, height: 3), freeAspectRatio: 4.0 / 3.0),
            placement: .init(x: 0.2, y: -0.1),
            magnification: 2
        )

        geometry.setCropDimensionsSwapped(true)
        #expect(geometry.crop.swapsDimensions)
        #expect(geometry.placement == .zero)
        #expect(geometry.magnification == 1)

        geometry.placement = .init(x: 0.1, y: 0.1)
        geometry.magnification = 1.5
        geometry.selectCrop(.square)
        #expect(geometry.crop.option == .square)
        #expect(geometry.placement == .zero)
        #expect(geometry.magnification == 1)
    }

    @Test func freeCropResizeClampsAndResetsDependentGeometry() {
        var geometry = PhotoEditGeometry(
            crop: .init(option: .free, freeAspectRatio: 1),
            placement: .init(x: 0.25, y: 0.25),
            magnification: 2
        )

        geometry.resizeFreeCrop(to: 10)
        #expect(geometry.crop.freeAspectRatio == 4)
        #expect(geometry.placement == .zero)
        #expect(geometry.magnification == 1)
    }

}
#endif
