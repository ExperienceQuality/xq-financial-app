// swift-tools-version: 5.10
import PackageDescription

/// Should-fail fixture: Package.swift must not depend on SwiftUI / UI frameworks.
let package = Package(
    name: "FixtureCore",
    products: [
        .library(name: "FixtureCore", targets: ["FixtureCore"])
    ],
    targets: [
        .target(name: "FixtureCore", dependencies: ["SwiftUI"])
    ]
)
