import Testing
@testable import SBJStructure

@Suite("SBJ edit traversal context")
struct SBJEditTraversalContextTests {
    @Test("root begins at tree level zero")
    func rootLevel() {
        #expect(SBJEditTraversalContext.root.treeLevel == 0)
    }

    @Test("descending increments tree level without mutating parent")
    func descendedLevel() {
        let parent = SBJEditTraversalContext(treeLevel: 2)
        let child = parent.descended()

        #expect(parent.treeLevel == 2)
        #expect(child.treeLevel == 3)
    }
}

@Suite("SBJ editor snapshot identity")
struct SBJEditorSnapshotIdentityTests {
    @Test("collection item identity is independent from its current index path")
    func collectionItemIdentityVsIndexPath() {
        let parent = SBJEditTraversalContext.root.property("relationships")
        let first = parent.descended(stableIdentifier: "relationship-42", index: 0)
        let moved = parent.descended(stableIdentifier: "relationship-42", index: 3)

        #expect(first.itemIdentifier == moved.itemIdentifier)
        #expect(first.indexPath != moved.indexPath)
    }

    @Test("different parent properties keep identical slots distinct")
    func parentPropertyDisambiguatesSlots() {
        let traits = SBJEditTraversalContext.root
            .property("traits")
            .descended(stableIdentifier: "slot:0", index: 0)
        let ideals = SBJEditTraversalContext.root
            .property("ideals")
            .descended(stableIdentifier: "slot:0", index: 0)

        #expect(traits.itemIdentifier != ideals.itemIdentifier)
    }
}
