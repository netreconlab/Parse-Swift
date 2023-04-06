// swift-tools-version:5.5

import PackageDescription

#if swift(>=5.5.2)
let platforms: [SupportedPlatform] = [
    .iOS(.v13),
    .macCatalyst(.v13),
    .macOS(.v10_15),
    .tvOS(.v13),
    .watchOS(.v6)
]
#else
let platforms: [SupportedPlatform] = [
    .iOS(.v15),
    .macCatalyst(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v8)
]
#endif

let package = Package(
    name: "ParseSwift",
    platforms: platforms,
    products: [
        .library(
            name: "ParseSwift",
            targets: ["ParseSwift"])
    ],
    targets: [
        .target(
            name: "ParseSwift",
            dependencies: []),
        .testTarget(
            name: "ParseSwiftTests",
            dependencies: ["ParseSwift"],
            exclude: ["Info.plist"])
    ]
)
