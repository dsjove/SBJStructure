import Foundation
import Testing
@testable import SBJFoundation

@Suite("Attachment, tag, and unit dogfood")
struct AttachmentTagUnitDogfoodTests {
    @Test func unitModelsExposePropertyInformation() {
        #expect(UnitValue<LengthUnit>.propertyInfo(for: \UnitValue<LengthUnit>.value) != nil)
        #expect(UnitValue<LengthUnit>.propertyInfo(for: \UnitValue<LengthUnit>.unit) != nil)
        #expect(UnitConversionModel<LengthUnit>.propertyInfo(for: \UnitConversionModel<LengthUnit>.source) != nil)
        #expect(UnitConversionModel<LengthUnit>.propertyInfo(for: \UnitConversionModel<LengthUnit>.destinationUnit) != nil)
    }

    @Test func builtInDomainHelpExists() {
        #expect(SBJAssetReference.attachmentsHelp.exists)
        #expect(SBJAssetReference.editTags.exists)
        #expect(SBJAssetReference.unitConversionHelp.exists)
    }
}
