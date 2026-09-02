import Foundation
import Testing
@testable import SBJStructure

@Suite("Foundation utilities")
struct SBJFoundationUtilitiesTests {
    @Test func stringUtilities() {
        #expect("  Hello \n".trimmed == "Hello")
        #expect(" \n ".querify == nil)
        #expect("  Hello ".isEquivalent(to: "hello"))
        #expect("a-b".replacingOccurrences(using: ["-": "_"]) == "a_b")
    }

    @Test func collectionUtilities() {
        #expect([1, 2, 1, 3, 2].removingDuplicatesPreservingOrder() == [1, 2, 3])
        #expect(Set([1, 2, 1, 3, 2].removingDuplicatesUnordered()) == Set([1, 2, 3]))
        let grouped = ["a", "bb", "c"].grouped(by: \.count)
        #expect(grouped[1] == ["a", "c"])
        #expect(grouped[2] == ["bb"])
    }

    @Test func propertyInfoUsesOriginalAccessibleProtocol() {
        let info = SBJPropertyInfo(
            summary: "Summary",
            details: "Details",
            accessibilityLabel: "Label",
            accessibilityHint: "Hint",
            accessibilityValue: "Value"
        )
        let accessible: any Accessible = info
        #expect(accessible.accessibilityLabel == "Label")
        #expect(accessible.accessibilityHint == "Hint")
        #expect(accessible.accessibilityValue == "Value")
    }

    @Test func accessibleItemRetainsOriginalInitializer() {
        let item = AccessibleItem(label: "Label", hint: "Hint", value: "Value")
        #expect(item.accessibilityLabel == "Label")
        #expect(item.accessibilityHint == "Hint")
        #expect(item.accessibilityValue == "Value")
        #expect(!item.isEmpty)
        #expect(AccessibleItem().isEmpty)
    }

    @Test func imageSourceIsFoundationLevel() {
        #expect(ImageSource.none.isEmpty)
        #expect(ImageSource.system("").isEmpty)
        #expect(ImageSource.bundled("").isEmpty)
        #expect(!ImageSource.system("photo").isEmpty)
        #expect(!ImageSource.file(URL(fileURLWithPath: "/tmp/image.png")).isEmpty)
    }

    @Test func identifiedURLUsesGenericIdentityWrapper() {
        let value: IdentifiedURL = Identified(URL(string: "https://example.com")!)
        #expect(value.value.absoluteString == "https://example.com")
    }
}
