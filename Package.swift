// swift-tools-version: 6.1
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
    dependencies: [
        .package(
            url: "https://github.com/davdroman/swiftui-navigation-transitions",
            exact: "0.16.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NavPilot",
            dependencies: [
                .product(
                    name: "UIKitNavigationTransitions",
                    package: "swiftui-navigation-transitions",
                    condition: .when(platforms: [.iOS, .macCatalyst, .tvOS, .visionOS])
                )
            ]
        ),
        .testTarget(
            name: "NavPilotTests",
            dependencies: ["NavPilot"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
