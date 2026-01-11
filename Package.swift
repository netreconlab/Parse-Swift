// swift-tools-version:6.0

import PackageDescription

let sharedSwiftSettings: [SwiftSetting] = [
	.enableUpcomingFeature("MemberImportVisibility"),
	.enableUpcomingFeature("InferIsolatedConformances"),
	.enableUpcomingFeature("ImmutableWeakCaptures"),
	.enableExperimentalFeature("StrictConcurrency=minimal")
]

var testSwiftSettings: [SwiftSetting] {
	#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
	return sharedSwiftSettings
	#else
	// Linux, windows, etc. is too strict in the test suite.
	return sharedSwiftSettings + [.enableExperimentalFeature("StrictConcurrency=minimal")]
	#endif
}


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
			swiftSettings: testSwiftSettings
        )
    ]
)
