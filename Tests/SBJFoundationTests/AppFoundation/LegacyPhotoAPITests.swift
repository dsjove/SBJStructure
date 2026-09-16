#if canImport(UIKit) && !os(watchOS)
import SwiftUI
import Testing
import UIKit
@testable import SBJFoundation

@Suite("Legacy photo compatibility")
struct LegacyPhotoAPITests {
    private final class Source: PhotoSource {
        var photo: Data?
        var thumbnail: Data?
        var changeCount = 0

        func photoChanged() {
            changeCount += 1
        }
    }

    @Test func clearingPhotoClearsThumbnailAndNotifiesSource() {
        let source = Source()
        source.photo = Data([0x01])
        source.thumbnail = Data([0x02])

        source.photoImage = nil

        #expect(source.photo == nil)
        #expect(source.thumbnail == nil)
        #expect(source.changeCount == 1)
    }

    @MainActor
    @Test func movedLegacyPhotoSurfaceStillCompiles() {
        let source = Source()
        _ = source.thumbnailView()
        _ = source.displayView
        _ = PhotoDisplayView2(source: source)
        _ = PhotoThumbailView(source: source)
        _ = PhotoImportMenu(image: Binding<UIImage?>.constant(nil))
        _ = PhotoEditSheet(viewing: UIImage())
    }
}
#endif
