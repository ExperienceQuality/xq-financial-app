// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "FitnessCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FitnessCore", targets: ["FitnessCore"])
    ],
    targets: [
        .target(name: "FitnessCore"),
        .testTarget(name: "FitnessCoreTests", dependencies: ["FitnessCore"])
    ]
)

