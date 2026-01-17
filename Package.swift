// swift-tools-version:6.0

import PackageDescription

#if swift(>=6.2)
let sharedSwiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("InferIsolatedConformances"),
	.enableUpcomingFeature("ImmutableWeakCaptures"),
	.enableUpcomingFeature("NonisolatedNonsendingByDefault")
]
#else
let sharedSwiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("InferIsolatedConformances"),
	.enableUpcomingFeature("ImmutableWeakCaptures")
]
#endif

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
