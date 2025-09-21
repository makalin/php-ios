// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PhpIOS",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PhpIOS",
            targets: ["PhpIOS"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PhpIOSBridge",
            dependencies: [],
            path: "Sources/PhpIOSBridge",
            exclude: ["../PhpIOS/lib"],
            publicHeadersPath: ".",
            linkerSettings: [
                .linkedLibrary("libphp-ios", .when(platforms: [.iOS])),
                .unsafeFlags(["-ObjC"], .when(platforms: [.iOS]))
            ]
        ),
        .target(
            name: "PhpIOS",
            dependencies: ["PhpIOSBridge"],
            path: "Sources/PhpIOS",
            exclude: ["lib"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "PhpIOSTests",
            dependencies: ["PhpIOS"],
            path: "Tests/PhpIOSTests"
        ),
    ]
)