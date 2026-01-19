// swift-tools-version:5.10

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
	// Only necessary in Swift 5.10+
	.enableUpcomingFeature("ConciseMagicFile"),
	.enableUpcomingFeature("BareSlashRegexLiterals"),
	.enableUpcomingFeature("DeprecateApplicationMain"),
	.enableUpcomingFeature("DisableOutwardActorInference"),
	.enableUpcomingFeature("DynamicActorIsolation"),
	.enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
	.enableUpcomingFeature("ForwardTrailingClosures"),
	.enableUpcomingFeature("ImportObjcForwardDeclarations"),
	.enableUpcomingFeature("ImplicitOpenExistentials"),
	.enableUpcomingFeature("InferSendableFromCaptures"),
	.enableUpcomingFeature("IsolatedDefaultValues"),
	.enableUpcomingFeature("RegionBasedIsolation"),
	// Optional features in Swift 6+
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("InferIsolatedConformances"),
	.enableExperimentalFeature("StrictConcurrency=complete")
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
            exclude: ["Info.plist"],
			swiftSettings: sharedSwiftSettings
        )
    ]
)
