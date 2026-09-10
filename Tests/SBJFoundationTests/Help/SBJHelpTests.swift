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
        let resolved = SBJAssetReference.resolvedContentType(
            override: .markdown,
            assetTypeIdentifier: UTType.html.identifier
        )
        XCTAssertEqual(resolved, .markdown)
    }

    func testAssetCatalogIdentifierResolvesContentType() {
        let resolved = SBJAssetReference.resolvedContentType(
            override: nil,
            assetTypeIdentifier: UTType.html.identifier
        )
        XCTAssertEqual(resolved, .html)
    }

    func testBundleResourceNameDefaultsToSanitizedDisplayName() {
        let asset = SBJAssetReference(
            displayName: "Recipe Details",
            subdirectory: "help"
        )
        XCTAssertEqual(asset.fullName, "help/RecipeDetails.html")
    }

    func testExplicitDataAssetContentTypeOverride() {
        let asset = SBJAssetReference(displayName: "Recipe Details", dataAsset: "help/RecipeDetails", contentType: .markdown)
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
        _ = SBJHelpLink(asset: .structureEditorCore)
    }

    func testHelpUsesSharedSemanticImageVocabulary() {
        XCTAssertEqual(SBJSemanticImageReference.help, .system("questionmark.circle"))
        XCTAssertEqual(SBJSemanticImageReference.about, .system("info.circle"))
        XCTAssertEqual(SBJSemanticImageReference.dismiss, .system("checkmark.circle"))
        XCTAssertEqual(SBJSemanticImageReference.scrollPageDown, .system("chevron.down"))
        XCTAssertEqual(SBJSemanticImageReference.scrollToTop, .system("chevron.up.2"))
        XCTAssertEqual(SBJSemanticImageReference.navigateToProperty, .system("chevron.right"))
    }
    func testBundledStructureSearchHelpIsAvailable() {
        let asset = SBJAssetReference.structureEditorSearch
        XCTAssertTrue(asset.exists)
        XCTAssertEqual(asset.contentType, .html)
        XCTAssertTrue(asset.stringValue()?.contains("Finding fields") == true)
    }

    func testBundledResourceContentTypeCanComeFromExtension() {
        let asset = SBJAssetReference.help("Embedding Fixture", bundle: .module)
        XCTAssertEqual(asset.contentType, .html)
        XCTAssertTrue(asset.exists)
    }

    func testEmbeddedFrameworkHelpIsExpandedInsideApplicationHelp() throws {
        let parent = SBJAssetReference.help("Embedding Fixture", bundle: .module)
        let source = try XCTUnwrap(SBJHelpTemplateRenderer().renderedSource(for: parent))
        XCTAssertFalse(source.contains("SBJ_STRUCTURE_EDITOR_SEARCH_HELP"))
        XCTAssertTrue(source.contains("Finding fields"))
        XCTAssertTrue(source.contains("Embedding Fixture"))
        XCTAssertFalse(source.contains("UI_help\\"))
        XCTAssertTrue(source.contains("data:image/png;base64"))
    }


}
#endif
