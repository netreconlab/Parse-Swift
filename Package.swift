// swift-tools-version:5.10

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_CONCISE_MAGIC_FILE"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_DEPRECATE_APPLICATION_MAIN"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_DISABLE_OUTWARD_ACTOR_ISOLATION"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_DYNAMIC_ACTOR_ISOLATION"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_FORWARD_TRAILING_CLOSURES"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_GLOBAL_ACTOR_ISOLATED_TYPES_USABILITY"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_IMPLICIT_OPEN_EXISTENTIALS"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_IMPORT_OBJC_FORWARD_DECLS"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_INFER_SENDABLE_FROM_CAPTURES"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_ISOLATED_DEFAULT_VALUES"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_GLOBAL_CONCURRENCY"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_NONFROZEN_ENUM_EXHAUSTIVITY"),
	.enableUpcomingFeature("SWIFT_UPCOMING_FEATURE_REGION_BASED_ISOLATION"),
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
            exclude: ["Info.plist"]
        )
    ]
)
