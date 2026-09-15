import XCTest
import UniformTypeIdentifiers
@testable import SBJFoundation

final class FilenameTests: XCTestCase {
    func testSanitizedFilenameAddsPreferredContentTypeExtension() {
        XCTAssertEqual("Photo".sanitizedFilename(contentType: .jpeg), "Photo.jpeg")
    }

    func testSanitizedFilenamePreservesExistingExtension() {
        XCTAssertEqual("Photo.jpg".sanitizedFilename(contentType: .png), "Photo.jpg")
    }

    func testSanitizedFilenameSanitizesBeforeAddingExtension() {
        XCTAssertEqual("Bad/Photo".sanitizedFilename(contentType: .jpeg), "Bad-Photo.jpeg")
    }

    func testUniqueFilenameReturnsUnusedNameUnchanged() {
        XCTAssertEqual("notes.pdf".uniqueFilename(existingNames: ["map.pdf"]), "notes.pdf")
    }

    func testUniqueFilenamePreservesExtension() {
        XCTAssertEqual(
            "notes.pdf".uniqueFilename(existingNames: ["notes.pdf", "notes 2.pdf"]),
            "notes 3.pdf"
        )
    }

    func testUniqueFilenameComparisonIsCaseInsensitive() {
        XCTAssertEqual(
            "Notes.PDF".uniqueFilename(existingNames: ["notes.pdf"]),
            "Notes 2.PDF"
        )
    }

    func testUniqueFilenameWithoutExtension() {
        XCTAssertEqual(
            "notes".uniqueFilename(existingNames: ["notes", "notes 2"]),
            "notes 3"
        )
    }
}
