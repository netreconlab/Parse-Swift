<!-- markdownlint-disable -->
![parse-swift](https://user-images.githubusercontent.com/8621344/204069535-e1882bb0-bbcb-4178-87e6-58fd1bed96d1.png)

<h3 align="center">iOS · macOS · watchOS · tvOS · Linux · Android · Windows</h3>

<h4 align="center">
⭐️ ParseSwift was highlighted in <a href="https://iosdevweekly.com/issues/560#start" target="_blank"> issue #560</a> of <a href="https://iosdevweekly.com" target="_blank"> iOS Dev Weekly</a> and discussed in <a href="https://blog.swiftpackageindex.com/posts/swift-package-indexing-episode-5/" target="_blank"> episode 5</a> of <a href="https://swiftpackageindexing.transistor.fm" target="_blank">Swift Package Index Twitter Spaces</a> </h3>

---

[![Playgrounds](https://img.shields.io/badge/swift-playgrounds-2196f3.svg)](https://github.com/netreconlab/Parse-Swift/tree/main/ParseSwift.playground/Pages)
[![Documentation](https://img.shields.io/badge/read_-docs-2196f3.svg)](https://swiftpackageindex.com/netreconlab/Parse-Swift/documentation)
[![Tutorial](https://img.shields.io/badge/read_-tutorials-2196f3.svg)](https://netreconlab.github.io/Parse-Swift/release/tutorials/parseswift/)
[![Build Status CI](https://github.com/netreconlab/Parse-Swift/workflows/ci/badge.svg?branch=main)](https://github.com/netreconlab/Parse-Swift/actions?query=workflow%3Aci+branch%3Amain)
[![Build Status Release](https://github.com/netreconlab/Parse-Swift/workflows/release/badge.svg)](https://github.com/netreconlab/Parse-Swift/actions?query=workflow%3Arelease)
[![Coverage](https://codecov.io/gh/netreconlab/Parse-Swift/branch/main/graph/badge.svg)](https://app.codecov.io/gh/netreconlab/Parse-Swift/branch/main)
[![Codacy Badge](https://app.codacy.com/project/badge/Grade/403b74d0f2514e288b0a1b2e52b6d841)](https://www.codacy.com/gh/netreconlab/Parse-Swift/dashboard?utm_source=github.com&amp;utm_medium=referral&amp;utm_content=netreconlab/Parse-Swift&amp;utm_campaign=Badge_Grade)
[![Pod](https://img.shields.io/cocoapods/v/ParseSwiftOG.svg)](https://cocoapods.org/pods/ParseSwiftOG)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)][license-link]
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2FParse-Swift%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/netreconlab/Parse-Swift)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fnetreconlab%2FParse-Swift%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/netreconlab/Parse-Swift)

---

A pure Swift library that gives you access to the powerful Parse Server backend. See why ParseSwift<sup>OG</sup> is better than all of the other Parse SDK's by reviewing the [feature comparison tables](https://github.com/netreconlab/Parse-Swift/discussions/72). 

The ParseSwift<sup>OG</sup> SDK is not a port of the [Parse-SDK-iOS-OSX SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) and though some of it may feel familiar, it is not backwards compatible and is designed using [protocol oriented programming (POP)](https://www.pluralsight.com/guides/protocol-oriented-programming-in-swift) and [value types](https://www.youtube.com/watch?v=A_b2oCBmm2Y) instead of OOP and reference types. You can learn more about POP by watching [Protocol-Oriented Programming in Swift](https://developer.apple.com/videos/play/wwdc2015/408/) or [Protocol and Value Oriented Programming in UIKit Apps](https://developer.apple.com/videos/play/wwdc2016/419/) videos from previous WWDC's. For more details about ParseSwift<sup>OG</sup>, visit the [api documentation](https://netreconlab.github.io/Parse-Swift/release/documentation/parseswift/).

> :information_source: **Why Choose ParseSwift<sup>OG</sup> Over parse-community/Parse-Swift?** <br>
> This repo is maintained by [Corey E. Baker](https://github.com/cbaker6), [1 of 2 of the original developers of ParseSwift](https://github.com/parse-community/Parse-Swift/graphs/contributors). Corey was responsible for the direction and development of all parse-community releases of ParseSwift from [1.0.0](https://github.com/parse-community/Parse-Swift/releases/tag/4.14.2) to [4.14.2](https://github.com/parse-community/Parse-Swift/releases/tag/4.14.2). ParseSwift<sup>OG</sup> has the most up-to-date features and bug fixes to develop client and server-side applications. It is the most flexible Parse Client SDK to date, can be used to write [Cloud Code](https://github.com/netreconlab/parse-server-swift), and is developed with zero dependencies. This repo is aligned with the original core principals of a swifty framework. Star, watch, and submit [questions](https://github.com/netreconlab/Parse-Swift/discussions), [issues](https://github.com/netreconlab/Parse-Swift/issues), and [pull requests](https://github.com/netreconlab/Parse-Swift/pulls) to [NetReconLab ParseSwift<sup>OG</sup>](https://github.com/netreconlab/Parse-Swift) instead of the parse-community ParseSwift to support it's development. Learn how to seemlessly migrate your apps from parse-community to ParseSwift<sup>OG</sup> by reading the [discussion](https://github.com/netreconlab/Parse-Swift/discussions/70). For more details about why ParseSwift<sup>OG</sup> exists, see the [discussion](https://github.com/netreconlab/Parse-Swift/discussions/7). If you benefit from ParseSwift and would like to show monetary support, feel free to: <br>
<a href="https://www.buymeacoffee.com/cbaker6" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-orange.png" alt="Buy Me A Coffee" height="41" width="174"></a>

## Contributors
Developers who dedicate their time and effort are who make this repo possible!

<a href="https://github.com/netreconlab/Parse-Swift/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=netreconlab/Parse-Swift" />
</a>

---

- [Why use ParseSwift<sup>OG</sup> from NetReconLab?](https://github.com/netreconlab/Parse-Swift/discussions/7)
- [Contributors](#contributors)
- [Example Apps and Frameworks](#example-apps-and-frameworks)
- [Test Drive Parse-Swift](#test-drive-parse-swift)
- [Installation](#installation)
  - [Swift Package Manager](#swift-package-manager)
  - [CocoaPods](#cocoapods)
- [Usage Guide](#usage-guide)
- [LiveQuery](#livequery)
  - [Setup Server](#setup-server)
  - [Use Client](#use-client)
    - [SwiftUI View Models Using Combine](#swiftui-view-models-using-combine)
    - [Traditional Callbacks](#traditional-callbacks)
  - [Advanced Usage](#advanced-usage)
- [Migrating from Older Versions and SDKs](#migrating-from-older-versions-and-sdks)

## Example Apps and Frameworks
Below is a list of apps and frameworks that use ParseSwift<sup>OG</sup> to help developers take advantage of the framework:
- [ParseServerSwift](https://github.com/netreconlab/parse-server-swift) - Write Parse Cloud Code in Swift using ParseSwift<sup>OG</sup>
- [ParseServerAnyAnalytics](https://github.com/netreconlab/parse-server-any-analytics-adapter) - Analytics adapter to connect Parse Server analytics to any 3rd party analytics tool
- [CarekitSampe-ParseCareKit](https://github.com/netreconlab/CareKitSample-ParseCareKit) - An example application of [CareKit](https://github.com/carekit-apple/CareKit)'s OCKSample synchronizing CareKit data to the Cloud via [ParseCareKit](https://github.com/netreconlab/ParseCareKit)
- [ParseCareKit](https://github.com/netreconlab/ParseCareKit) - Synchronize CareKit 2.1+ data with a parse-server using ParseSwift<sup>OG</sup>
- [SnapCat](https://github.com/netreconlab/SnapCat) - SnapCat is a social media application for posting pictures, comments, and finding friends. SnapCat is designed using SwiftUI and the ParseSwift<sup>OG</sup> SDK
- [ParseMigrateKeychain](https://github.com/netreconlab/ParseMigrateKeychain) - A sample app that demonstrates how to migrate an app written with the Parse [Objective-C SDK](https://github.com/parse-community/Parse-SDK-iOS-OSX) to the ParseSwift<sup>OG</sup> SDK. Learn more, see the [discussion](https://github.com/netreconlab/Parse-Swift/discussions/71).

## Test Drive Parse-Swift
To learn how to use or experiment with ParseSwift<sup>OG</sup>, you can run and edit the [ParseSwift.playground](https://github.com/netreconlab/Parse-Swift/tree/main/ParseSwift.playground/Pages). You can use the parse-server in [this repo](https://github.com/netreconlab/parse-hipaa/tree/parse-swift) which has docker compose files (`docker-compose up` gives you a working server) configured to connect with the playground files, has [Parse Dashboard](https://github.com/parse-community/parse-dashboard), and can be used with MongoDB or PostgreSQL. You can also configure the Swift Playgrounds to work with your own Parse Server by editing the configuation in [Common.swift](https://github.com/netreconlab/Parse-Swift/blob/e9ba846c399257100b285d25d2bd055628b13b4b/ParseSwift.playground/Sources/Common.swift#L4-L19). To learn more, see this [discussion](https://github.com/netreconlab/Parse-Swift/discussions/74) or [CONTRIBUTING.md](https://github.com/netreconlab/Parse-Swift/blob/main/CONTRIBUTING.md#swift-playgrounds).

## Installation

### [Swift Package Manager](https://swift.org/package-manager/)

You can use The Swift Package Manager (SPM) to install ParseSwift<sup>OG</sup> by adding the following description to your `Package.swift` file:

```swift
// swift-tools-version:5.5.2
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/netreconlab/Parse-Swift", .upToNextMajor(from: "5.7.0")),
    ]
)
```
Then run `swift build`. 

You can also install using SPM in your Xcode project by going to 
"Project->NameOfYourProject->Swift Packages" and placing `https://github.com/netreconlab/Parse-Swift.git` in the 
search field.

### [CocoaPods](https://cocoapods.org)

Add the following line to your Podfile:

```ruby
pod 'ParseSwiftOG'
```

To link to the latest updates on the main branch, add the following line to your Podfile:

```ruby
pod 'ParseSwiftOG', :git => 'https://github.com/netreconlab/Parse-Swift.git', :branch => 'main'
```

In your projects, use:

```swift
import ParseSwiftOG
```

## Usage Guide

After installing ParseSwift<sup>OG</sup>, to use it first `import ParseSwift` in your AppDelegate.swift and then add the following code in your `application:didFinishLaunchingWithOptions:` method:
```swift
try await ParseSwift.initialize(applicationId: "xxxxxxxxxx", clientKey: "xxxxxxxxxx", serverURL: URL(string: "https://example.com")!)
```
Please checkout the [Swift Playground](https://github.com/netreconlab/Parse-Swift/tree/main/ParseSwift.playground/Pages) for more usage information.

## LiveQuery

`Query` is one of the key concepts on the Parse Platform. It allows you to retrieve `ParseObject`s by specifying some conditions, making it easy to build apps such as a dashboard, a todo list or even some strategy games. However, `Query` is based on a pull model, which is not suitable for apps that need real-time support.

Suppose you are building an app that allows multiple users to edit the same file at the same time. `Query` would not be an ideal tool since you can not know when to query from the server to get the updates.

To solve this problem, we introduce Parse LiveQuery. This tool allows you to subscribe to a `Query` you are interested in. Once subscribed, the server will notify clients whenever a `ParseObject` that matches the `Query` is created or updated, in real-time.

### Setup Server

Parse LiveQuery contains two parts, the LiveQuery server and the LiveQuery clients (this SDK). In order to use live queries, you need to at least setup the server.

The easiest way to setup the LiveQuery server is to make it run with the [Open Source Parse Server](https://github.com/ParsePlatform/parse-server/wiki/Parse-LiveQuery#server-setup).


### Use Client

#### SwiftUI View Models Using Combine

The LiveQuery client interface is based around the concept of `Subscription`s. You can register any `Query` for live updates from the associated live query server and use the query as a view model for a SwiftUI view by simply using the `subscribe` property of a query: https://github.com/netreconlab/Parse-Swift/blob/0c17c781a211299f324753fa9bcbb6845c22fad2/ParseSwift.playground/Pages/19%20-%20SwiftUI%20-%20LiveQuery.xcplaygroundpage/Contents.swift#L66-L125

or by calling the `subscribe(_ client: ParseLiveQuery)` method of a query. If you want to customize your view model more you can subclass `Subscription` or add the subscription to your own view model. You can test out LiveQuery subscriptions in [Swift Playgrounds](https://github.com/netreconlab/Parse-Swift/blob/main/ParseSwift.playground/Pages/19%20-%20SwiftUI%20-%20LiveQuery.xcplaygroundpage/Contents.swift).

#### Traditional Callbacks

You can also use asynchronous call backs to subscribe to a LiveQuery: 

```swift
let myQuery = Message.query("from" == "parse")
do {
  let subscription = try await myQuery.subscribeCallback()
} catch {
    print("Error subscribing...")
}
```

or by calling the `subscribeCallback(_ client: ParseLiveQuery)` method of a query.

Where `Message` is a ParseObject.

Once you've subscribed to a query, you can `handle` events on them, like so:

```swift
subscription.handleSubscribe { subscribedQuery, isNew in

    //Handle the subscription however you like.
    if isNew {
        print("Successfully subscribed to new query \(subscribedQuery)")
    } else {
        print("Successfully updated subscription to new query \(subscribedQuery)")
    }
}
```

You can handle any event for LiveQuery [docs](https://swiftpackageindex.com/netreconlab/parse-swift/main/documentation/parseswift/event):
```swift
subscription.handleEvent { _, event in
    // Called whenever an object was created
    switch event {

    case .entered(let object):
        print("Entered: \(object)")
    case .left(let object):
        print("Left: \(object)")
    case .created(let object):
        print("Created: \(object)")
    case .updated(let object):
        print("Updated: \(object)")
    case .deleted(let object):
        print("Deleted: \(object)")
    }
}
```

Similiarly, you can unsubscribe and register to be notified when it occurs:
```swift
subscription.handleUnsubscribe { query in
    print("Unsubscribed from \(query)")
}

//: To unsubscribe from your query.
do {
    try await query.unsubscribe()
} catch {
    print(error)
}
```

Handling errors is and other events is similar, take a look at the `Subscription` class for more information. You can test out LiveQuery subscriptions in [Swift Playgrounds](https://github.com/netreconlab/Parse-Swift/blob/main/ParseSwift.playground/Pages/11%20-%20LiveQuery.xcplaygroundpage/Contents.swift).

### Advanced Usage

You are not limited to a single Live Query Client - you can create multiple instances of `ParseLiveQuery`, use certificate authentication and pinning, receive metrics about each client connection, connect to individual server URLs, and more.

[license-link]: LICENSE

## Migrating from Older Versions and SDKs

1. See the [discussion](https://github.com/netreconlab/Parse-Swift/discussions/74) to learn how to migrate from ParseSwift<sup>OG</sup> 4.15.0+ to 5.1.1+
1. See the [discussion](https://github.com/netreconlab/Parse-Swift/discussions/70) to learn how to migrate from [parse-community/Parse-Swift](https://github.com/parse-community/Parse-Swift)
1. See the [discussion](https://github.com/netreconlab/Parse-Swift/discussions/71) to learn how to migrate from [Parse-SDK-iOS-OSX](https://github.com/parse-community/Parse-SDK-iOS-OSX)

