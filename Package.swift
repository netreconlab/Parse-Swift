// swift-tools-version:5.10

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("DisableOutwardActorInference"),
	.enableUpcomingFeature("DynamicActorIsolation"),
	.enableUpcomingFeature("ForwardTrailingClosures"),
	.enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
	.enableUpcomingFeature("ImplicitOpenExistentials"),
	.enableUpcomingFeature("InferSendableFromCaptures"),
	.enableUpcomingFeature("IsolatedDefaultValues"),
	.enableUpcomingFeature("GlobalConcurrency"),
	.enableUpcomingFeature("NonfrozenEnumExhaustivity"),
	.enableUpcomingFeature("RegionBasedIsolation"),
	.enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
    name: "ParseSwift",
    platforms: [
        .iOS(.v13),
        .macCatalyst(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "ParseSwift",
            targets: ["ParseSwift"]
        )
    ],
    targets: [
        .target(
            name: "ParseSwift",
			dependencies: [],
			swiftSettings: sharedSwiftSettings
        ),
        .testTarget(
            name: "ParseSwiftTests",
            dependencies: ["ParseSwift"],
            exclude: ["Info.plist"]
        )
    ]
)
