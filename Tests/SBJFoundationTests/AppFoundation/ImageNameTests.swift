import Testing
@testable import SBJFoundation

@Suite("Image names")
struct ImageNameTests {
    @Test func emptyStateMatchesOriginalSemantics() {
        #expect(ImageName.none.isEmpty)
        #expect(ImageName.system("").isEmpty)
        #expect(ImageName.bundled("").isEmpty)
        #expect(!ImageName.system("info.circle").isEmpty)
        #expect(!ImageName.bundled("logo").isEmpty)
    }

    @Test func accessibleImageItemRetainsOriginalAccessibilityBehavior() {
        let decorative = AccessibleImageItem(image: .system("star"), label: "Favorite")
        #expect(decorative.accessibilityLabel == nil)
        #expect(!decorative.labeled)

        let labeled = AccessibleImageItem(image: .system("star"), labeled: true, label: "Favorite")
        #expect(labeled.accessibilityLabel == "Favorite")
        #expect(labeled.labeled)
    }

    @Test func bundleReferenceSurface() {
        let main = BundleReference.main
        let identified = BundleReference.identifier("com.example.assets")
        #expect(main != identified)
        _ = ImageName.bundled("logo", bundle: main)
    }
    @Test func presentationImageReferencesAreSendable() {
        func requireSendable<T: Sendable>(_: T) {}
        requireSendable(BundleReference.main)
        requireSendable(ImageName.system("star"))
        requireSendable(ImageName.bundled("logo", bundle: .main))
    }

}
