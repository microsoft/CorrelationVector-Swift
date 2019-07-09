// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "CorrelationVector",
    products: [
        .library(
            name: "CorrelationVector",
            targets: ["CorrelationVector"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CorrelationVector",
            dependencies: []),
        .testTarget(
            name: "CorrelationVectorTests",
            dependencies: ["CorrelationVector"]),
    ]
)
