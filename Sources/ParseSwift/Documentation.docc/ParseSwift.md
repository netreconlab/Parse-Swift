# ``ParseSwift``
<!-- markdownlint-disable -->
A pure Swift library that gives you access to the powerful Parse Server backend from your Swift applications.

## Overview
![Parse logo](parse-swift.png)
For more information about the Parse Platform and its features, see the public [documentation](https://docs.parseplatform.org). The ParseSwift SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed using [protocol oriented programming (POP) and value types](https://www.pluralsight.com/guides/protocol-oriented-programming-in-swift) instead of OOP and reference types. You can learn more about POP by watching [Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/) or [Protocol and Value Oriented Programming in UIKit Apps](https://developer.apple.com/videos/play/wwdc2016/419/) videos from previous WWDC's. For more details about ParseSwift, visit the [api documentation](https://netreconlab.github.io/Parse-Swift/release/documentation/parseswift/).

To learn how to use or experiment with ParseSwift, you can run and edit the [ParseSwift.playground](https://github.com/netreconlab/Parse-Swift/tree/main/ParseSwift.playground/Pages). You can use the parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which has docker compose files (`docker-compose up` gives you a working server) configured to connect with the playground files, has [Parse Dashboard](https://github.com/parse-community/parse-dashboard), and can be used with MongoDB or PostgreSQL. You can also configure the Swift Playgrounds to work with your own Parse Server by editing the configuation in [Common.swift](https://github.com/netreconlab/Parse-Swift/blob/e9ba846c399257100b285d25d2bd055628b13b4b/ParseSwift.playground/Sources/Common.swift#L4-L19). To learn more, check out [CONTRIBUTING.md](https://github.com/netreconlab/Parse-Swift/blob/main/CONTRIBUTING.md#swift-playgrounds).

## Why use Parse-Swift from NetReconLab?
This repo is maintained by [Corey E. Baker](https://github.com/cbaker6), [1 of 2 of the original developers of Parse-Swift](https://github.com/parse-community/Parse-Swift/graphs/contributors). Corey was responsible for the direction and development of all releases from [1.0.0](https://github.com/parse-community/Parse-Swift/releases/tag/4.14.2) to [4.14.2](https://github.com/parse-community/Parse-Swift/releases/tag/4.14.2). This repo will remain aligned with the original core principals of a swifty framework that contains zero dependencies and takes advantage of all of the features the [parse-server](https://github.com/parse-community/parse-server) has to offer. You can learn more about why I left the parse-community and created my own repo [here](https://github.com/netreconlab/Parse-Swift/discussions/7).

## Topics

### Configure SDK

- ``ParseSwift/initialize(configuration:)``
- ``ParseSwift/initialize(applicationId:clientKey:primaryKey:serverURL:liveQueryServerURL:requiringCustomObjectIds:usingTransactions:usingEqualQueryConstraint:usingPostForQuery:primitiveStore:requestCachePolicy:cacheMemoryCapacity:cacheDiskCapacity:usingDataProtectionKeychain:deletingKeychainIfNeeded:httpAdditionalHeaders:maxConnectionAttempts:liveQueryMaxConnectionAttempts:parseFileTransfer:authentication:)``
- ``ParseSwift/configuration``
- ``ParseSwift/setAccessGroup(_:synchronizeAcrossDevices:)``
- ``ParseSwift/updateAuthentication(_:)``
- ``ParseSwift/clearCache()``
- ``ParseSwift/deleteObjectiveCKeychain()``
