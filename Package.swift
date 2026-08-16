// swift-tools-version: 6.4

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SBJStructure",
    platforms: [
        .iOS(.v17),
        .macOS(.v15),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "SBJStructure",
            targets: ["SBJStructure"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            exact: "604.0.0-prerelease-2026-06-05"
        ),
    ],
    targets: [
        .macro(
            name: "SBJStructureMacros",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "SBJStructure",
            dependencies: ["SBJStructureMacros"],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
                .defaultIsolation(nil),
            ],
        ),
        .testTarget(
            name: "SBJStructureTests",
            dependencies: [
                "SBJStructure",
                "SBJStructureMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
                .defaultIsolation(nil),
            ],
        ),
    ]
)
