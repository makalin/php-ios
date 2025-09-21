// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SampleApp",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "SampleApp",
            dependencies: [
                .product(name: "PhpIOS", package: "php-ios")
            ],
            path: "Sources/SampleApp",
            resources: [
                .process("PhpScripts")
            ]
        )
    ]
)