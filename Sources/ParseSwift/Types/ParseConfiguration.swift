//
//  ParseConfiguration.swift
//  ParseSwift
//
//  Created by Corey Baker on 8/30/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// swiftlint:disable line_length

/**
 The Configuration for a Parse client.

 - important: It is recomended to only specify `primaryKey` when using the SDK on a server. Do not use this key on the client.
 - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
 - warning: `usingTransactions` is experimental.
 - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
 situtations when apps do not have credentials to setup a Keychain.
 */
public struct ParseConfiguration {

    /// The application id for your Parse application.
    public internal(set) var applicationId: String

    /// The primary key for your Parse application. This key should only
    /// be specified when using the SDK on a server.
    /// - note: This has been renamed from `masterKey` to reflect [inclusive language](https://github.com/dialpad/inclusive-language#motivation)
    public internal(set) var primaryKey: String?

    /// The client key for your Parse application.
    public internal(set) var clientKey: String?

    /// The server URL to connect to a Parse Server.
    public internal(set) var serverURL: URL

    /// The live query server URL to connect to a Parse LiveQuery Server.
    public internal(set) var liveQuerysServerURL: URL?

    /// Requires `objectId`'s to be created on the client.
    public internal(set) var isRequiringCustomObjectIds = false

    /// Use transactions when saving/updating multiple objects.
    /// - warning: This is experimental.
    public internal(set) var isUsingTransactions = false

    /// Use the **$eq** query constraint when querying.
    /// - warning: This is known not to work for LiveQuery on Parse Servers <= 5.0.0.
    public internal(set) var isUsingEqualQueryConstraint = false

    /// Use **POST** instead of **GET** when making query calls.
    /// Defaults to **false**.
    /// - warning: **POST** calls are not cached and will require all queries to access the
    /// server instead of following the `requestCachePolicy`.
    public internal(set) var isUsingPostForQuery = false

    /// The default caching policy for all http requests that determines when to
    /// return a response from the cache. Defaults to `useProtocolCachePolicy`.
    /// See Apple's [documentation](https://developer.apple.com/documentation/foundation/url_loading_system/accessing_cached_data)
    /// for more info.
    public internal(set) var requestCachePolicy = URLRequest.CachePolicy.useProtocolCachePolicy

    /// A dictionary of additional headers to send with requests. See Apple's
    /// [documentation](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders)
    /// for more info.
    public internal(set) var httpAdditionalHeaders: [AnyHashable: Any]?

    /// The memory capacity of the cache, in bytes. Defaults to 512KB.
    public internal(set) var cacheMemoryCapacity = 512_000

    /// The disk capacity of the cache, in bytes. Defaults to 10MB.
    public internal(set) var cacheDiskCapacity = 10_000_000

    /// If your app previously used the iOS Objective-C SDK, setting this value
    /// to **true** will attempt to migrate relevant data stored in the Keychain to
    /// ParseSwift. Defaults to **false**.
    public internal(set) var isMigratingFromObjcSDK: Bool = false

    /// Deletes the Parse Keychain when the app is running for the first time.
    /// Defaults to **false**.
    public internal(set) var isDeletingKeychainIfNeeded: Bool = false

    /// Sets `kSecUseDataProtectionKeychain` to **true**. See Apple's [documentation](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain)
    /// for more info.
    /// Defaults to **false**.
    ///  - warning: This is known to cause issues in Playgrounds or in situtations when
    ///  apps do not have credentials to setup a Keychain.
    public internal(set) var isUsingDataProtectionKeychain: Bool = false

    /// Maximum number of times to try to connect to a Parse Server.
    /// Defaults to 5.
    public internal(set) var maxConnectionAttempts: Int = 5

    /// Maximum number of times to try to connect to a Parse LiveQuery Server.
    /// Defaults to 20.
    public internal(set) var liveQueryMaxConnectionAttempts: Int = 20

    /**
     Override the default transfer behavior for `ParseFile`'s.
     Allows for direct uploads to other file storage providers.
     */
    public internal(set) var parseFileTransfer: ParseFileTransferable

    internal var authentication: ((URLAuthenticationChallenge,
                                   (URLSession.AuthChallengeDisposition,
                                    URLCredential?) -> Void) -> Void)?
    internal var mountPath: String
    internal var isTestingSDK = false
    internal var isTestingLiveQueryDontCloseSocket = false
    #if !os(Linux) && !os(Android) && !os(Windows)
    internal var keychainAccessGroup = ParseKeychainAccessGroup()
    #endif

    /**
     Create a Parse Swift configuration.
     - parameter applicationId: The application id for your Parse application.
     - parameter clientKey: The client key for your Parse application.
     - parameter primaryKey: The master key for your Parse application. This key should only be
     specified when using the SDK on a server.
     - parameter serverURL: The server URL to connect to a Parse Server.
     - parameter liveQueryServerURL: The live query server URL to connect to a Parse LiveQuery Server.
     - parameter requiringCustomObjectIds: Requires `objectId`'s to be created on the client
     side for each object. Must be enabled on the server to work.
     - parameter usingTransactions: Use transactions when saving/updating multiple objects.
     - parameter usingEqualQueryConstraint: Use the **$eq** query constraint when querying.
     - parameter usingPostForQuery: Use **POST** instead of **GET** when making query calls.
     Defaults to **false**.
     - parameter primitiveStore: A key/value store that conforms to the `ParsePrimitiveStorable`
     protocol. Defaults to `nil` in which one will be created an memory, but never persisted. For Linux, this
     this is the only store available since there is no Keychain. Linux, Android, and Windows users should
     replace this store with an encrypted one.
     - parameter requestCachePolicy: The default caching policy for all http requests that determines
     when to return a response from the cache. Defaults to `useProtocolCachePolicy`. See Apple's [documentation](https://developer.apple.com/documentation/foundation/url_loading_system/accessing_cached_data)
     for more info.
     - parameter cacheMemoryCapacity: The memory capacity of the cache, in bytes. Defaults to 512KB.
     - parameter cacheDiskCapacity: The disk capacity of the cache, in bytes. Defaults to 10MB.
     - parameter usingDataProtectionKeychain: Sets `kSecUseDataProtectionKeychain` to **true**. See Apple's [documentation](https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain)
     for more info. Defaults to **false**.
     - parameter deletingKeychainIfNeeded: Deletes the Parse Keychain when the app is running for the first time.
     Defaults to **false**.
     - parameter httpAdditionalHeaders: A dictionary of additional headers to send with requests. See Apple's
     [documentation](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1411532-httpadditionalheaders)
     for more info.
     - parameter maxConnectionAttempts: Maximum number of times to try to connect to a Parse Server.
     Defaults to 5.
     - parameter liveQueryMaxConnectionAttempts: Maximum number of times to try to connect to a Parse
     LiveQuery Server. Defaults to 20.
     - parameter parseFileTransfer: Override the default transfer behavior for `ParseFile`'s.
     Allows for direct uploads to other file storage providers.
     - parameter authentication: A callback block that will be used to receive/accept/decline network challenges.
     Defaults to `nil` in which the SDK will use the default OS authentication methods for challenges.
     It should have the following argument signature: `(challenge: URLAuthenticationChallenge,
     completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void`.
     See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
     - important: It is recomended to only specify `primaryKey` when using the SDK on a server. Do not use this key on the client.
     - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
     - warning: `usingTransactions` is experimental.
     - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
     situtations when apps do not have credentials to setup a Keychain.
     */
    public init(applicationId: String,
                clientKey: String? = nil,
                primaryKey: String? = nil,
                webhookKey: String? = nil,
                serverURL: URL,
                liveQueryServerURL: URL? = nil,
                requiringCustomObjectIds: Bool = false,
                usingTransactions: Bool = false,
                usingEqualQueryConstraint: Bool = false,
                usingPostForQuery: Bool = false,
                primitiveStore: ParsePrimitiveStorable? = nil,
                requestCachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
                cacheMemoryCapacity: Int = 512_000,
                cacheDiskCapacity: Int = 10_000_000,
                usingDataProtectionKeychain: Bool = false,
                deletingKeychainIfNeeded: Bool = false,
                httpAdditionalHeaders: [AnyHashable: Any]? = nil,
                maxConnectionAttempts: Int = 5,
                liveQueryMaxConnectionAttempts: Int = 20,
                parseFileTransfer: ParseFileTransferable? = nil,
                authentication: ((URLAuthenticationChallenge,
                                  (URLSession.AuthChallengeDisposition,
                                   URLCredential?) -> Void) -> Void)? = nil) {
        self.applicationId = applicationId
        self.clientKey = clientKey
        self.primaryKey = primaryKey
        self.serverURL = serverURL
        self.liveQuerysServerURL = liveQueryServerURL
        self.isRequiringCustomObjectIds = requiringCustomObjectIds
        self.isUsingTransactions = usingTransactions
        self.isUsingEqualQueryConstraint = usingEqualQueryConstraint
        self.isUsingPostForQuery = usingPostForQuery
        self.mountPath = "/" + serverURL.pathComponents
            .filter { $0 != "/" }
            .joined(separator: "/")
        self.authentication = authentication
        self.requestCachePolicy = requestCachePolicy
        self.cacheMemoryCapacity = cacheMemoryCapacity
        self.cacheDiskCapacity = cacheDiskCapacity
        self.isUsingDataProtectionKeychain = usingDataProtectionKeychain
        self.isDeletingKeychainIfNeeded = deletingKeychainIfNeeded
        self.httpAdditionalHeaders = httpAdditionalHeaders
        self.maxConnectionAttempts = maxConnectionAttempts
        self.liveQueryMaxConnectionAttempts = liveQueryMaxConnectionAttempts
        self.parseFileTransfer = parseFileTransfer ?? ParseFileDefaultTransfer()
        ParseStorage.shared.use(primitiveStore ?? InMemoryKeyValueStore())
    }
}
