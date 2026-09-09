#if !os(watchOS)
import XCTest
import UniformTypeIdentifiers
@testable import SBJFoundation

final class SBJHelpTests: XCTestCase {
    func testFilenameExtensionsUseUniformTypeIdentifiers() {
        XCTAssertEqual(UTType(filenameExtension: "html"), .html)
        XCTAssertEqual(UTType(filenameExtension: "md"), .markdown)
    }

    func testExplicitContentTypeOverridesAssetCatalogIdentifier() {
        let resolved = SBJHelpAsset.resolvedContentType(
            override: .markdown,
            assetTypeIdentifier: UTType.html.identifier
        )
        XCTAssertEqual(resolved, .markdown)
    }

    func testAssetCatalogIdentifierResolvesContentType() {
        let resolved = SBJHelpAsset.resolvedContentType(
            override: nil,
            assetTypeIdentifier: UTType.html.identifier
        )
        XCTAssertEqual(resolved, .html)
    }

    func testAssetPathPreservesLegacySanitizingConvention() {
        let asset = SBJHelpAsset(title: "Recipe Details", folder: "help", contentType: .html)
        XCTAssertEqual(asset.fullName, "help/RecipeDetails")
    }

    func testFilenameExtensionInitializerSetsContentTypeOverride() {
        let asset = SBJHelpAsset(
            title: "Recipe Details",
            folder: "help",
            filenameExtension: "md"
        )
        XCTAssertEqual(asset.contentTypeOverride, .markdown)
    }

    @MainActor
    func testBuiltInPresentersAreSelectedByContentType() {
        XCTAssertNotNil(SBJHelpPresenters.builtIn(for: .html))
        XCTAssertNotNil(SBJHelpPresenters.builtIn(for: .markdown))
        XCTAssertNil(SBJHelpPresenters.builtIn(for: .json))
    }

    @MainActor
    func testHelpLinkCompilesOnCurrentPlatform() {
        _ = SBJHelpLink("Help", contentType: .html)
    }

    func testHelpUsesSharedSemanticImageVocabulary() {
        XCTAssertEqual(SBJSemanticImageReference.help, .system("questionmark.circle"))
        XCTAssertEqual(SBJSemanticImageReference.about, .system("info.circle"))
        XCTAssertEqual(SBJSemanticImageReference.dismiss, .system("checkmark.circle"))
        XCTAssertEqual(SBJSemanticImageReference.scrollPageDown, .system("chevron.down"))
        XCTAssertEqual(SBJSemanticImageReference.scrollToTop, .system("chevron.up.2"))
        XCTAssertEqual(SBJSemanticImageReference.navigateToProperty, .system("chevron.right"))
    }
    func testBundledStructureEditorHelpIsAvailable() {
        let asset = SBJHelpAsset.structureEditor
        XCTAssertTrue(asset.exists)
        XCTAssertEqual(asset.contentType, .html)
        XCTAssertTrue(asset.stringValue()?.contains("Using the Editor") == true)
    }

    func testBundledResourceContentTypeCanComeFromExtension() {
        let asset = SBJHelpAsset(
            title: "Embedding Fixture",
            resourceName: "EmbeddingFixture",
            resourceExtension: "html",
            bundle: .module
        )
        XCTAssertEqual(asset.contentType, .html)
        XCTAssertTrue(asset.exists)
    }

    func testEmbeddedFrameworkHelpIsExpandedInsideApplicationHelp() throws {
        let parent = SBJHelpAsset(
            title: "Embedding Fixture",
            resourceName: "EmbeddingFixture",
            resourceExtension: "html",
            bundle: .module
        )
        let document = try XCTUnwrap(SBJHelpTemplateRenderer().document(for: parent))
        XCTAssertFalse(document.source.contains("SBJ_STRUCTURE_EDITOR_HELP"))
        XCTAssertTrue(document.source.contains("Using the Editor"))
        XCTAssertTrue(document.source.contains("Embedding Fixture"))
        XCTAssertFalse(document.source.contains("UI_help\\"))
        XCTAssertTrue(document.source.contains("data:image/png;base64"))
    }

    func testStandardHelpSemanticImagesComeFromUIVocabulary() {
        let images = SBJHelpConfiguration.standardSemanticImages
        XCTAssertEqual(images["help"], SBJSemanticImageReference.help)
        XCTAssertEqual(images["restore"], SBJSemanticImageReference.restore)
        XCTAssertEqual(images["add"], SBJSemanticImageReference.add)
        XCTAssertEqual(images["moveUp"], SBJSemanticImageReference.moveUp)
    }

}
#endif
