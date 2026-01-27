# ``ParseSwift``
A pure Swift library that gives you access to the powerful Parse Server backend from Swift applications built for iOS, macOS, watchOS, tvOS, visionOS, Android, Linux, and Windows.
<!-- markdownlint-disable -->

## Overview
![Parse logo](parse-swift.png)
See why ParseSwift is better than all of the other Parse SDK's by reviewing the [feature comparison tables](https://github.com/netreconlab/Parse-Swift/discussions/72). The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed using [protocol oriented programming (POP)](https://www.pluralsight.com/guides/protocol-oriented-programming-in-swift) and [value types](https://www.youtube.com/watch?v=A_b2oCBmm2Y) instead of OOP and reference types. You can learn more about POP by watching [Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/) or [Protocol and Value Oriented Programming in UIKit Apps](https://developer.apple.com/videos/play/wwdc2016/419/) videos from previous WWDC's. For more details about how to use ParseSwift, visit the [tuturial documentation](https://netreconlab.github.io/Parse-Swift/release/tutorials/parseswift/).

⭐️ ParseSwift was highlighted in [issue #560](https://iosdevweekly.com/issues/560#start) of [iOS Dev Weekly](https://iosdevweekly.com) and discussed in [episode 5](https://blog.swiftpackageindex.com/posts/swift-package-indexing-episode-5/) of [Swift Package Index Twitter Spaces](https://swiftpackageindexing.transistor.fm)

## Test Drive ParseSwift
To learn how to use or experiment with ParseSwift, you can run and edit the [ParseSwift.playground](https://github.com/netreconlab/Parse-Swift/tree/main/ParseSwift.playground/Pages). You can use the parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which has docker compose files (`docker-compose up` gives you a working server) configured to connect with the playground files, has [Parse Dashboard](https://github.com/parse-community/parse-dashboard), and can be used with MongoDB or PostgreSQL. You can also configure the Swift Playgrounds to work with your own Parse Server by editing the configuration in [Common.swift](https://github.com/netreconlab/Parse-Swift/blob/e9ba846c399257100b285d25d2bd055628b13b4b/ParseSwift.playground/Sources/Common.swift#L4-L19). To learn more, see this [discussion](https://github.com/netreconlab/Parse-Swift/discussions/74) or [CONTRIBUTING.md](https://github.com/netreconlab/Parse-Swift/blob/main/CONTRIBUTING.md#swift-playgrounds).

## Why use ParseSwift from NetReconLab?
This repo is maintained by [Corey E. Baker](https://github.com/cbaker6), [1 of 2 of the original developers of ParseSwift](https://github.com/parse-community/Parse-Swift/graphs/contributors). Corey was responsible for the direction and development of all parse-community releases of ParseSwift from [1.0.0](https://github.com/parse-community/Parse-Swift/releases/tag/4.14.2) to [4.14.2](https://github.com/parse-community/Parse-Swift/releases/tag/4.14.2). The NetReconLab repo will remain aligned with the original core principals of a swifty framework that contains zero dependencies and takes advantage of all of the features the [parse-server](https://github.com/parse-community/parse-server) has to offer. You can learn more about why I left the parse-community and created my own repo [here](https://github.com/netreconlab/Parse-Swift/discussions/7).

## Topics

### Configure SDK

- ``ParseSwift/initialize(configuration:)``
- ``ParseSwift/initialize(applicationId:clientKey:primaryKey:maintenanceKey:serverURL:liveQueryServerURL:requiringCustomObjectIds:usingTransactions:usingEqualQueryConstraint:usingPostForQuery:primitiveStore:requestCachePolicy:cacheMemoryCapacity:cacheDiskCapacity:usingDataProtectionKeychain:deletingKeychainIfNeeded:httpAdditionalHeaders:usingAutomaticLogin:maxConnectionAttempts:liveQueryConnectionAdditionalProperties:liveQueryMaxConnectionAttempts:parseFileTransfer:authentication:)``
- ``ParseSwift/configuration``
- ``ParseSwift/setAccessGroup(_:synchronizeAcrossDevices:)``
- ``ParseSwift/updateAuthentication(_:)``
- ``ParseSwift/clearCache()``
- ``ParseSwift/deleteObjectiveCKeychain()``
