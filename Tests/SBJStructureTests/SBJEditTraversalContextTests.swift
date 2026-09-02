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
