// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "run-on-macos-screen-unlock",
    products: [
        .executable(name: "run-on-macos-screen-unlock", targets: ["run-on-macos-screen-unlock"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "run-on-macos-screen-unlock",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
