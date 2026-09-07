import Foundation
import Testing
@testable import SBJFoundation

@Suite("Image references")
struct ImageReferenceTests {
    @Test func emptyStateMatchesOriginalSemantics() {
        #expect(ImageReference.none.isEmpty)
        #expect(ImageReference.system("").isEmpty)
        #expect(ImageReference.bundled("").isEmpty)
        #expect(!ImageReference.system("info.circle").isEmpty)
        #expect(!ImageReference.bundled("logo").isEmpty)
        #expect(!ImageReference.file(URL(fileURLWithPath: "/tmp/image.png")).isEmpty)
    }

    @Test func accessibleImageItemRetainsOriginalAccessibilityBehavior() {
        let decorative = AccessibleImageItem(image: .system("star"), label: "Favorite")
        #expect(decorative.accessibilityLabel == nil)
        #expect(!decorative.labeled)

        let labeled = AccessibleImageItem(image: .system("star"), labeled: true, label: "Favorite")
        #expect(labeled.accessibilityLabel == "Favorite")
        #expect(labeled.labeled)
    }

    @Test func presentationImageReferencesAreSendable() {
        func requireSendable<T: Sendable>(_: T) {}
        requireSendable(ImageReference.system("star"))
        requireSendable(ImageReference.bundled("logo", bundle: Bundle.main))
        requireSendable(ImageReference.file(URL(fileURLWithPath: "/tmp/image.png")))
        requireSendable(Bundle.main)
    }
}
