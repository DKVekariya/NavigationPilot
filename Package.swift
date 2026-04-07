// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NavPilot",
    platforms: [
        .iOS(.v16),
        .macOS(.v15),
        .tvOS(.v15),
        .watchOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "NavPilot",
            targets: ["NavPilot"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NavPilot"
        ),
        .testTarget(
            name: "NavPilotTests",
            dependencies: ["NavPilot"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
