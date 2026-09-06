import Testing
@testable import SBJFoundation

@SBJStructure
private struct ResourceLeaf: Codable, Equatable {
    var resource: SBJResourceID?
}

@SBJStructure
private struct ResourceRoot: Codable, Equatable {
    var direct: SBJResourceID?
    var children: [ResourceLeaf]
}

@Suite("SBJ resource discovery")
struct SBJResourceDiscoveryTests {
    @Test("Discovers resource IDs across structured values and collections with paths")
    func discovery() {
        let root = ResourceRoot(
            direct: .init("direct"),
            children: [.init(resource: .init("nested")), .init(resource: nil)]
        )
        let usages = Set(root.sbjResourceUsages())
        #expect(usages.contains(.init(id: .init("direct"), path: "direct")))
        #expect(usages.contains(.init(id: .init("nested"), path: "children[0].resource")))
    }
}
