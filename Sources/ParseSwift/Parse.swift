import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// swiftlint:disable line_length

// MARK: Internal

internal struct Parse {
    static var configuration: ParseConfiguration!
    static var sessionDelegate: ParseURLSessionDelegate!
}

internal func initialize(applicationId: String,
                         clientKey: String? = nil,
                         primaryKey: String? = nil,
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
                         migratingFromObjcSDK: Bool = false,
                         usingDataProtectionKeychain: Bool = false,
                         deletingKeychainIfNeeded: Bool = false,
                         httpAdditionalHeaders: [AnyHashable: Any]? = nil,
                         maxConnectionAttempts: Int = 5,
                         liveQueryMaxConnectionAttempts: Int = 20,
                         testing: Bool = false,
                         testLiveQueryDontCloseSocket: Bool = false,
                         authentication: ((URLAuthenticationChallenge,
                                          (URLSession.AuthChallengeDisposition,
                                           URLCredential?) -> Void) -> Void)? = nil) async throws {
    var configuration = ParseConfiguration(applicationId: applicationId,
                                           clientKey: clientKey,
                                           primaryKey: primaryKey,
                                           serverURL: serverURL,
                                           liveQueryServerURL: liveQueryServerURL,
                                           requiringCustomObjectIds: requiringCustomObjectIds,
                                           usingTransactions: usingTransactions,
                                           usingEqualQueryConstraint: usingEqualQueryConstraint,
                                           usingPostForQuery: usingPostForQuery,
                                           primitiveStore: primitiveStore,
                                           requestCachePolicy: requestCachePolicy,
                                           cacheMemoryCapacity: cacheMemoryCapacity,
                                           cacheDiskCapacity: cacheDiskCapacity,
                                           usingDataProtectionKeychain: usingDataProtectionKeychain,
                                           deletingKeychainIfNeeded: deletingKeychainIfNeeded,
                                           httpAdditionalHeaders: httpAdditionalHeaders,
                                           maxConnectionAttempts: maxConnectionAttempts,
                                           liveQueryMaxConnectionAttempts: liveQueryMaxConnectionAttempts,
                                           authentication: authentication)
    configuration.isMigratingFromObjcSDK = migratingFromObjcSDK
    configuration.isTestingSDK = testing
    configuration.isTestingLiveQueryDontCloseSocket = testLiveQueryDontCloseSocket
    try await initialize(configuration: configuration)
}

internal func deleteKeychainIfNeeded() async {
    #if !os(Linux) && !os(Android) && !os(Windows)
    // Clear items out of the Keychain on app first run.
    if UserDefaults.standard.object(forKey: ParseConstants.bundlePrefix) == nil {
        if Parse.configuration.isDeletingKeychainIfNeeded {
            try? await KeychainStore.old.deleteAll()
            try? await KeychainStore.shared.deleteAll()
        }
        Parse.configuration.keychainAccessGroup = .init()
        clearCache()
        // This is no longer the first run
        UserDefaults.standard.setValue(String(ParseConstants.bundlePrefix),
                                       forKey: ParseConstants.bundlePrefix)
        UserDefaults.standard.synchronize()
    }
    #endif
}

// MARK: Public - All Platforms

/// The current `ParseConfiguration` for the ParseSwift client.
public var configuration: ParseConfiguration {
    Parse.configuration
}

/**
 Configure the Parse Swift client. This should only be used when starting your app. Typically in the
 `application(... didFinishLaunchingWithOptions launchOptions...)`.
 - parameter configuration: The Parse configuration.
 - throws: An error of `ParseError` type.
 - important: It is recomended to only specify `primaryKey/masterKey` when using the SDK on a server. Do not use this key on the client.
 - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
 - warning: `usingTransactions` is experimental.
 - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
 situtations when apps do not have credentials to setup a Keychain.
 */
public func initialize(configuration: ParseConfiguration) async throws { // swiftlint:disable:this cyclomatic_complexity function_body_length
    Parse.configuration = configuration
    await KeychainStore.createShared()
    await ParseStorage.shared.use(configuration.primitiveStore)
    Parse.sessionDelegate = ParseURLSessionDelegate(callbackQueue: .main,
                                                    authentication: configuration.authentication)
    Utility.updateParseURLSession()
    await deleteKeychainIfNeeded()

    #if !os(Linux) && !os(Android) && !os(Windows)
    do {
        let keychainAccessGroup = try await ParseKeychainAccessGroup.current()
        Parse.configuration.keychainAccessGroup = keychainAccessGroup
    } catch {
        await ParseKeychainAccessGroup.setCurrent(ParseKeychainAccessGroup())
    }
    #endif

    do {
        let previousSDKVersion =  try await ParseVersion.current()
        let currentSDKVersion = try ParseVersion(string: ParseConstants.version)
        let oneNineEightSDKVersion = try ParseVersion(string: "1.9.8")

        // All migrations from previous versions to current should occur here:
        #if !os(Linux) && !os(Android) && !os(Windows)
        if previousSDKVersion < oneNineEightSDKVersion {
            // Old macOS Keychain cannot be used because it is global to all apps.
            await KeychainStore.createOld()
            try? await KeychainStore.shared.copy(KeychainStore.old,
                                                 oldAccessGroup: configuration.keychainAccessGroup,
                                                 newAccessGroup: configuration.keychainAccessGroup)
            // Need to delete the old Keychain because a new one is created with bundleId.
            try? await KeychainStore.old.deleteAll()
        }
        #endif
        if currentSDKVersion > previousSDKVersion {
            try? await ParseVersion.setCurrent(currentSDKVersion)
        }
    } catch {
        // Migrate old installations made with ParseSwift < 1.3.0
        if let currentInstallation = try? await BaseParseInstallation.current() {
            if currentInstallation.objectId == nil {
                await BaseParseInstallation.deleteCurrentContainerFromKeychain()
                // Prepare installation
                await BaseParseInstallation.createNewInstallationIfNeeded()
            }
        } else {
            // Prepare installation
            await BaseParseInstallation.createNewInstallationIfNeeded()
        }
        try await ParseVersion.setCurrent(try ParseVersion(string: ParseConstants.version))
    }

    // Migrate installations with installationId, but missing
    // currentInstallation, ParseSwift < 1.9.10
    let currentInstallationContainer = await BaseParseInstallation.currentContainer()
    if let installationId = currentInstallationContainer.installationId,
       currentInstallationContainer.currentInstallation == nil {
        if let foundInstallation = try? await BaseParseInstallation
            .query("installationId" == installationId)
            .first(options: [.cachePolicy(.reloadIgnoringLocalCacheData)]) {
            let newContainer = CurrentInstallationContainer<BaseParseInstallation>(currentInstallation: foundInstallation,
                                                                                   installationId: installationId)
            await BaseParseInstallation.setCurrentContainer(newContainer)
        }
    }
    await BaseParseInstallation.createNewInstallationIfNeeded()

    #if !os(Linux) && !os(Android) && !os(Windows)
    ParseLiveQuery.defaultClient = try await ParseLiveQuery(isDefault: true)
    if configuration.isMigratingFromObjcSDK {
        await KeychainStore.createObjectiveC()
        if let objcParseKeychain = KeychainStore.objectiveC {
            guard let installationId: String = await objcParseKeychain.objectObjectiveC(forKey: "installationId"),
                  try await BaseParseInstallation.current().installationId != installationId else {
                return
            }
            var updatedInstallation = try await BaseParseInstallation.current()
            updatedInstallation.installationId = installationId
            var currentInstallationContainer = await BaseParseInstallation.currentContainer()
            currentInstallationContainer.installationId = installationId
            currentInstallationContainer.currentInstallation = updatedInstallation
            await BaseParseInstallation.setCurrentContainer(currentInstallationContainer)
        }
    }
    #endif
}

/**
 Configure the Parse Swift client. This should only be used when starting your app. Typically in the
 `application(... didFinishLaunchingWithOptions launchOptions...)`.
 - parameter applicationId: The application id for your Parse application.
 - parameter clientKey: The client key for your Parse application.
 - parameter primaryKey: The primary key for your Parse application. This key should only be
 specified when using the SDK on a server. This has been renamed from `masterKey` to reflect
 inclusive language.
 - parameter serverURL: The server URL to connect to Parse Server.
 - parameter liveQueryServerURL: The live query server URL to connect to Parse Server.
 - parameter requiringCustomObjectIds: Requires `objectId`'s to be created on the client
 side for each object. Must be enabled on the server to work.
 - parameter usingTransactions: Use transactions when saving/updating multiple objects.
 - parameter usingEqualQueryConstraint: Use the **$eq** query constraint when querying.
 - parameter usingPostForQuery: Use **POST** instead of **GET** when making query calls.
 Defaults to **false**.
 - parameter primitiveStore: A key/value store that conforms to the `ParseKeyValueStore`
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
 - parameter maxConnectionAttempts: Maximum number of times to try to connect to Parse Server.
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
 - throws: An error of `ParseError` type.
 - important: It is recomended to only specify `primaryKey/masterKey` when using the SDK on a server. Do not use this key on the client.
 - note: Setting `usingPostForQuery` to **true**  will require all queries to access the server instead of following the `requestCachePolicy`.
 - warning: `usingTransactions` is experimental.
 - warning: Setting `usingDataProtectionKeychain` to **true** is known to cause issues in Playgrounds or in
 situtations when apps do not have credentials to setup a Keychain.
 */
public func initialize(
    applicationId: String,
    clientKey: String? = nil,
    primaryKey: String? = nil,
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
                       URLCredential?) -> Void) -> Void)? = nil
) async throws {
    let configuration = ParseConfiguration(applicationId: applicationId,
                                           clientKey: clientKey,
                                           primaryKey: primaryKey,
                                           serverURL: serverURL,
                                           liveQueryServerURL: liveQueryServerURL,
                                           requiringCustomObjectIds: requiringCustomObjectIds,
                                           usingTransactions: usingTransactions,
                                           usingEqualQueryConstraint: usingEqualQueryConstraint,
                                           usingPostForQuery: usingPostForQuery,
                                           primitiveStore: primitiveStore,
                                           requestCachePolicy: requestCachePolicy,
                                           cacheMemoryCapacity: cacheMemoryCapacity,
                                           cacheDiskCapacity: cacheDiskCapacity,
                                           usingDataProtectionKeychain: usingDataProtectionKeychain,
                                           deletingKeychainIfNeeded: deletingKeychainIfNeeded,
                                           httpAdditionalHeaders: httpAdditionalHeaders,
                                           maxConnectionAttempts: maxConnectionAttempts,
                                           liveQueryMaxConnectionAttempts: liveQueryMaxConnectionAttempts,
                                           parseFileTransfer: parseFileTransfer,
                                           authentication: authentication)
    try await initialize(configuration: configuration)
}

/**
 Update the authentication callback.
 - parameter authentication: A callback block that will be used to receive/accept/decline network challenges.
 Defaults to `nil` in which the SDK will use the default OS authentication methods for challenges.
 It should have the following argument signature: `(challenge: URLAuthenticationChallenge,
 completionHandler: (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) -> Void`.
 See Apple's [documentation](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) for more for details.
 */
public func updateAuthentication(_ authentication: ((URLAuthenticationChallenge,
                                                     (URLSession.AuthChallengeDisposition,
                                                      URLCredential?) -> Void) -> Void)?) {
    Parse.sessionDelegate = ParseURLSessionDelegate(callbackQueue: .main,
                                                    authentication: authentication)
    Utility.updateParseURLSession()
}

/**
 Manually remove all stored cache.
 - note: The OS typically handles this automatically.
 */
public func clearCache() {
    URLSession.parse.configuration.urlCache?.removeAllCachedResponses()
}

// MARK: Public - Apple Platforms

#if !os(Linux) && !os(Android) && !os(Windows)

/**
 Delete the Parse iOS Objective-C SDK Keychain from the device.
 - throws: An error of `ParseError` type.
 - note: ParseSwift uses a different Keychain. After migration, the iOS Objective-C SDK Keychain is no longer needed.
 - warning: The keychain cannot be recovered after deletion.
 */
public func deleteObjectiveCKeychain() async throws {
    try await KeychainStore.objectiveC?.deleteAllObjectiveC()
}

/**
 Sets all of the items in the Parse Keychain to a specific access group.
 Apps in the same access group can share Keychain items. See Apple's
  [documentation](https://developer.apple.com/documentation/security/ksecattraccessgroup)
  for more information.
 - parameter accessGroup: The name of the access group.
 - parameter synchronizeAcrossDevices: **true** to synchronize all necessary Parse Keychain items to
 other devices using iCloud. See Apple's [documentation](https://developer.apple.com/documentation/security/ksecattrsynchronizable)
 for more information. **false** to disable synchronization.
 - throws: An error of type `ParseError`.
 - returns: **true** if the Keychain was moved to the new `accessGroup`, **false** otherwise.
 - important: Setting `synchronizeAcrossDevices == true` requires `accessGroup` to be
 set to a valid [keychain group](https://developer.apple.com/documentation/security/ksecattraccessgroup).
 */
@discardableResult public func setAccessGroup(_ accessGroup: String?,
                                              synchronizeAcrossDevices: Bool) async throws -> Bool {
    if synchronizeAcrossDevices && accessGroup == nil {
        throw ParseError(code: .otherCause,
                         message: "\"accessGroup\" must be set to a valid string when \"synchronizeAcrossDevices == true\"")
    }
    guard let currentAccessGroup = try? await ParseKeychainAccessGroup.current() else {
        throw ParseError(code: .otherCause,
                         message: "Problem unwrapping the current access group. Did you initialize the SDK before calling this method?")
    }
    let newKeychainAccessGroup = ParseKeychainAccessGroup(accessGroup: accessGroup,
                                                          isSyncingKeychainAcrossDevices: synchronizeAcrossDevices)
    guard newKeychainAccessGroup != currentAccessGroup else {
        await ParseKeychainAccessGroup.setCurrent(newKeychainAccessGroup)
        return true
    }
    do {
        try await KeychainStore.shared.copy(KeychainStore.shared,
                                            oldAccessGroup: currentAccessGroup,
                                            newAccessGroup: newKeychainAccessGroup)
        await ParseKeychainAccessGroup.setCurrent(newKeychainAccessGroup)
    } catch {
        await ParseKeychainAccessGroup.setCurrent(currentAccessGroup)
        throw error
    }
    return true
}
#endif
