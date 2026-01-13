//
//  ParseInstallation.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/6/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 Objects that conform to the `ParseInstallation` protocol have a local representation of an
 installation persisted to the Keychain and Parse Server. This protocol inherits from the
 `ParseObject` protocol, and retains the same functionality of a `ParseObject`, but also extends
 it with installation-specific fields and related immutability and validity
 checks.

 A valid `ParseInstallation` can only be instantiated via
 *current* because the required identifier fields
 are readonly. The `timeZone` is also a readonly property which
 is automatically updated to match the device's time zone
 when the `ParseInstallation` is saved, thus these fields might not reflect the
 latest device state if the installation has not recently been saved.
 `ParseInstallation`s which have a valid `deviceToken` and are saved to
 the Parse Server can be used to target push notifications. Use `setDeviceToken` to set the
 `deviceToken` properly.

 - warning: If the use of badge is desired, it should be retrieved by using UIKit, AppKit, etc. and
 stored in `ParseInstallation.badge` when saving/updating the installation.
 - warning: Linux, Android, and Windows developers should set `appName`,
 `appIdentifier`, and `appVersion` manually as `ParseSwift` does not have access
 to Bundle.main.
*/
public protocol ParseInstallation: ParseObject {

    /**
     The device type for the `ParseInstallation`.
    */
    var deviceType: String? { get set }

    /**
     The installationId for the `ParseInstallation`.
    */
    var installationId: String? { get set }

    /**
     The device token for the `ParseInstallation`.
    */
    var deviceToken: String? { get set }

    /**
     The badge for the `ParseInstallation`.
    */
    var badge: Int? { get set }

    /**
     The name of the time zone for the `ParseInstallation`.
    */
    var timeZone: String? { get set }

    /**
     The channels for the `ParseInstallation`.
    */
    var channels: [String]? { get set }

    /**
     The application name  for the `ParseInstallation`.
     */
    var appName: String? { get set }

    /**
     The application identifier for the `ParseInstallation`.
     */
    var appIdentifier: String? { get set }

    /**
     The application version for the `ParseInstallation`.
     */
    var appVersion: String? { get set }

    /**
     The sdk version for the `ParseInstallation`.
     */
    var parseVersion: String? { get set }

    /**
     The locale identifier for the `ParseInstallation`.
     */
    var localeIdentifier: String? { get set }
}

// MARK: Default Implementations
public extension ParseInstallation {
    static var className: String {
        "_Installation"
    }

	var mergeable: Self {
		guard isSaved,
			originalData == nil else {
			return self
		}
		var object = Self()
		object.objectId = objectId
		object.createdAt = createdAt
		object.badge = badge
		object.timeZone = timeZone
		object.appName = appName
		object.appIdentifier = appIdentifier
		object.appVersion = appVersion
		object.parseVersion = parseVersion
		object.localeIdentifier = localeIdentifier
		object.originalData = try? ParseCoding.jsonEncoder().encode(self)
		return object
	}

    var endpoint: API.Endpoint {
        if let objectId = objectId {
            return .installation(objectId: objectId)
        }
        return .installations
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func mergeParse(with object: Self) throws -> Self {
        guard hasSameObjectId(as: object) else {
            throw ParseError(code: .otherCause,
                             message: "objectId's of objects do not match")
        }
        var updatedInstallation = self
        if shouldRestoreKey(\.ACL,
                             original: object) {
            updatedInstallation.ACL = object.ACL
        }
        if shouldRestoreKey(\.deviceType,
                             original: object) {
            updatedInstallation.deviceType = object.deviceType
        }
        if shouldRestoreKey(\.installationId,
                             original: object) {
            updatedInstallation.installationId = object.installationId
        }
        if shouldRestoreKey(\.deviceToken,
                                 original: object) {
            updatedInstallation.deviceToken = object.deviceToken
        }
        if shouldRestoreKey(\.badge,
                             original: object) {
            updatedInstallation.badge = object.badge
        }
        if shouldRestoreKey(\.timeZone,
                             original: object) {
            updatedInstallation.timeZone = object.timeZone
        }
        if shouldRestoreKey(\.channels,
                             original: object) {
            updatedInstallation.channels = object.channels
        }
        if shouldRestoreKey(\.appName,
                             original: object) {
            updatedInstallation.appName = object.appName
        }
        if shouldRestoreKey(\.appIdentifier,
                             original: object) {
            updatedInstallation.appIdentifier = object.appIdentifier
        }
        if shouldRestoreKey(\.appVersion,
                             original: object) {
            updatedInstallation.appVersion = object.appVersion
        }
        if shouldRestoreKey(\.parseVersion,
                             original: object) {
            updatedInstallation.parseVersion = object.parseVersion
        }
        if shouldRestoreKey(\.localeIdentifier,
                             original: object) {
            updatedInstallation.localeIdentifier = object.localeIdentifier
        }
        return updatedInstallation
    }

    func merge(with object: Self) throws -> Self {
        do {
            return try mergeAutomatically(object)
        } catch {
            return try mergeParse(with: object)
        }
    }
}

// MARK: Convenience
extension ParseInstallation {

    func endpoint(_ method: API.Method) async throws -> API.Endpoint {
        try await yieldIfNotInitialized()
        if !Parse.configuration.isRequiringCustomObjectIds ||
            method != .POST {
            return endpoint
        } else {
            return .installations
        }
    }

    func hasSameInstallationId<T: ParseInstallation>(as other: T) -> Bool {
        return other.className == className && other.installationId == installationId && installationId != nil
    }

    /**
     Sets the device token string property from an `Data`-encoded token.
     - parameter data: A token that identifies the device.
     */
    mutating public func setDeviceToken(_ data: Data) {
        let deviceTokenString = data.hexEncodedString()
        if deviceToken != deviceTokenString {
            deviceToken = deviceTokenString
        }
    }
}

// MARK: CurrentInstallationContainer
struct CurrentInstallationContainer<T: ParseInstallation>: Codable, Hashable {
    var currentInstallation: T?
    var installationId: String?
}

// MARK: Current Installation Support
public extension ParseInstallation {

    internal static func create() async throws {
        let newInstallationId = UUID().uuidString.lowercased()
        var newInstallation = BaseParseInstallation()
        newInstallation.installationId = newInstallationId
        newInstallation.createInstallationId(newId: newInstallationId)
        newInstallation.updateAutomaticInfo()
        let newBaseInstallationContainer =
            CurrentInstallationContainer<BaseParseInstallation>(currentInstallation: newInstallation,
                                                                installationId: newInstallationId)
        try await ParseStorage.shared.set(newBaseInstallationContainer,
                                          for: ParseStorage.Keys.currentInstallation)
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try? KeychainStore.shared.set(newBaseInstallationContainer,
                                      for: ParseStorage.Keys.currentInstallation)
        #endif
    }

    internal static func currentContainer() async -> CurrentInstallationContainer<Self> {
        guard let installationInMemory: CurrentInstallationContainer<Self> =
                try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation) else {
            #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
            guard let installationFromKeyChain: CurrentInstallationContainer<Self> =
                    try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
            else {
                try? await create()
                guard let installationFromKeyChain: CurrentInstallationContainer<Self> =
                        try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
                else {
                    // Could not create container correctly, return empty one.
                    return CurrentInstallationContainer<Self>()
                }
                try? await ParseStorage.shared.set(installationFromKeyChain, for: ParseStorage.Keys.currentInstallation)
                return installationFromKeyChain
            }
            return installationFromKeyChain
            #else
            try? await create()
            guard let installationFromMemory: CurrentInstallationContainer<Self> =
                    try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentInstallation)
            else {
                // Could not create container correctly, return empty one.
                return CurrentInstallationContainer<Self>()
            }
            return installationFromMemory
            #endif
        }
        return installationInMemory
    }

    internal static func setCurrentContainer(_ newValue: CurrentInstallationContainer<Self>) async {
        var currentContainer = newValue
        currentContainer.currentInstallation?.originalData = nil
        try? await ParseStorage.shared.set(currentContainer, for: ParseStorage.Keys.currentInstallation)
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try? KeychainStore.shared.set(currentContainer, for: ParseStorage.Keys.currentInstallation)
        #endif
    }

    internal static func updateInternalFieldsCorrectly() async {
        // Always pull automatic info to ensure user made no changes to immutable values
        var currentContainer = await Self.currentContainer()
        currentContainer.currentInstallation?.updateAutomaticInfo()
        await Self.setCurrentContainer(currentContainer)
    }

    internal static func deleteCurrentContainerFromStorage() async {
        try? await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentInstallation)
        #endif
        // Prepare new installation
        await BaseParseInstallation.createNewInstallationIfNeeded()
    }

    /**
     Get the current installation from the Keychain.

     - returns: Returns a `ParseInstallation` that is the current device. If there is none, throws an error.
     - throws: An error of `ParseError` type.
    */
    static func current() async throws -> Self {
        try await yieldIfNotInitialized()
        guard let installation = await Self.currentContainer().currentInstallation else {
            throw ParseError(code: .otherCause,
                             message: "There is no current Installation")
        }
        return installation
    }

    internal static func setCurrent(_ newValue: Self?) async {
        var currentContainer = await Self.currentContainer()
        currentContainer.currentInstallation = newValue
        currentContainer.installationId = newValue?.installationId
        await Self.setCurrentContainer(currentContainer)
        await Self.updateInternalFieldsCorrectly()
    }

    /**
     Copy the `ParseInstallation` *asynchronously* based on the `objectId`.
     On success, this saves the `ParseInstallation` to the keychain, so you can retrieve
     the current installation using *current*.

     - parameter objectId: The **id** of the `ParseInstallation` to become.
     - parameter copyEntireInstallation: When **true**, copies the entire `ParseInstallation`.
     When **false**, only the `channels` and `deviceToken` are copied; resulting in a new
     `ParseInstallation` for original `sessionToken`. Defaults to **true**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func become(_ objectId: String, // swiftlint:disable:this function_body_length
                       copyEntireInstallation: Bool = true,
                       options: API.Options = [],
                       callbackQueue: DispatchQueue = .main,
                       completion: @escaping @Sendable (Result<Self, ParseError>) -> Void) {
        Task {
            do {
                var currentInstallation = try await Self.current()
                guard currentInstallation.objectId != objectId else {
                    let currentInstallation = currentInstallation
                    // If the installationId's are the same, assume successful replacement already occured.
                    callbackQueue.async {
                        completion(.success(currentInstallation))
                    }
                    return
                }
                currentInstallation.objectId = objectId
                currentInstallation.fetch(options: options, callbackQueue: callbackQueue) { result in
                    switch result {
                    case .success(let updatedInstallation):
                        Task {
                            if copyEntireInstallation {
                                var updatedInstallation = updatedInstallation
                                updatedInstallation.updateAutomaticInfo()
                                var currentContainer = await Self.currentContainer()
                                currentContainer.installationId = updatedInstallation.installationId
                                currentContainer.currentInstallation = updatedInstallation
                                await Self.setCurrentContainer(currentContainer)
                            } else {
                                var current = try? await Self.current()
                                current?.channels = updatedInstallation.channels
                                if current?.deviceToken == nil {
                                    current?.deviceToken = updatedInstallation.deviceToken
                                }
                                await Self.setCurrent(current)
                            }
                            guard let latestInstallation = try? await Self.current() else {
                                let error = ParseError(code: .otherCause,
                                                       message: "Had trouble migrating the installation")
                                callbackQueue.async {
                                    completion(.failure(error))
                                }
                                return
                            }
                            latestInstallation.save(options: options,
                                                    callbackQueue: callbackQueue,
                                                    completion: completion)
                        }
                    case .failure(let error):
                        callbackQueue.async {
                            completion(.failure(error))
                        }
                    }
                }
            } catch {
                let error = ParseError(code: .otherCause,
                                       message: "Current installation does not exist")
                callbackQueue.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: Automatic Info
extension ParseInstallation {
    mutating func updateAutomaticInfo() {
        updateDeviceTypeFromDevice()
        updateTimeZoneFromDevice()
        updateVersionInfoFromDevice()
        updateLocaleIdentifierFromDevice()
    }

    mutating func createInstallationId(newId: String) {
        if installationId == nil {
            installationId = newId
        }
    }

    mutating func updateDeviceTypeFromDevice() {
        if deviceType != ParseConstants.deviceType {
            deviceType = ParseConstants.deviceType
        }
    }

    mutating func updateTimeZoneFromDevice() {
        let currentTimeZone = TimeZone.current.identifier
        if timeZone != currentTimeZone {
            timeZone = currentTimeZone
        }
    }

    mutating func updateVersionInfoFromDevice() {
        guard let appInfo = Bundle.main.infoDictionary else {
            return
        }
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
		#if targetEnvironment(macCatalyst)
        // If using an Xcode new enough to know about Mac Catalyst:
        // Mac Catalyst Apps use a prefix to the bundle ID. This should not be transmitted
        // to Parse Server. Catalyst apps should look like iOS apps otherwise
        // push and other services do not work properly.
        if let currentAppIdentifier = appInfo[String(kCFBundleIdentifierKey)] as? String {
            let macCatalystBundleIdPrefix = "maccatalyst."
            if currentAppIdentifier.hasPrefix(macCatalystBundleIdPrefix) {
                appIdentifier = currentAppIdentifier.replacingOccurrences(of: macCatalystBundleIdPrefix, with: "")
            }
        }

        #else
        if let currentAppIdentifier = appInfo[String(kCFBundleIdentifierKey)] as? String {
            if appIdentifier != currentAppIdentifier {
                appIdentifier = currentAppIdentifier
            }
        }
        #endif

        if let currentAppName = appInfo[String(kCFBundleNameKey)] as? String {
            if appName != currentAppName {
                appName = currentAppName
            }
        }

        if let currentAppVersion = appInfo[String(kCFBundleVersionKey)] as? String {
            if appVersion != currentAppVersion {
                appVersion = currentAppVersion
            }
        }
        #endif

        if parseVersion != ParseConstants.version {
            parseVersion = ParseConstants.version
        }
    }

    /**
     Save localeIdentifier in the following format: [language code]-[COUNTRY CODE].

     The language codes are two-letter lowercase ISO language codes (such as "en") as defined by
     <a href="http://en.wikipedia.org/wiki/ISO_639-1">ISO 639-1</a>.
     The country codes are two-letter uppercase ISO country codes (such as "US") as defined by
     <a href="http://en.wikipedia.org/wiki/ISO_3166-1_alpha-3">ISO 3166-1</a>.

     Many iOS locale identifiers do not contain the country code -> inconsistencies with Android/Windows Phone.
    */
    mutating func updateLocaleIdentifierFromDevice() {
        guard let language = Locale.current.languageCode else {
            return
        }

        let currentLocalIdentifier: String!
        if let regionCode = Locale.current.regionCode {
            currentLocalIdentifier = "\(language)-\(regionCode)"
        } else {
            currentLocalIdentifier = language
        }

        if localeIdentifier != currentLocalIdentifier {
            localeIdentifier = currentLocalIdentifier
        }
    }
}

// MARK: Fetchable
extension ParseInstallation {
    internal static func updateStorageIfNeeded(_ results: [Self], deleting: Bool = false) async throws {
        let currentInstallation = try await Self.current()
        var foundCurrentInstallationObjects = results.filter { $0.hasSameInstallationId(as: currentInstallation) }
        foundCurrentInstallationObjects = try foundCurrentInstallationObjects.sorted(by: {
            guard let firstUpdatedAt = $0.updatedAt,
                  let secondUpdatedAt = $1.updatedAt else {
                throw ParseError(code: .otherCause,
                                 message: "Objects from the server should always have an \"updatedAt\"")
            }
            return firstUpdatedAt.compare(secondUpdatedAt) == .orderedDescending
        })
        if let foundCurrentInstallation = foundCurrentInstallationObjects.first {
            if !deleting {
                await Self.setCurrent(foundCurrentInstallation)
            } else {
                await Self.deleteCurrentContainerFromStorage()
            }
        }
    }

    /**
     Fetches the `ParseInstallation` *asynchronously* and executes the given callback block.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func fetch(
        includeKeys: [String]? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<Self, ParseError>) -> Void
    ) {
        var murabeOptions = options
        murabeOptions.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let options = murabeOptions
        Task {
            do {
                try await fetchCommand(include: includeKeys)
                    .execute(options: options,
                             callbackQueue: callbackQueue) { result in
                        if case .success(let foundResult) = result {
                            Task {
                                do {
                                    try await Self.updateStorageIfNeeded([foundResult])
                                    completion(.success(foundResult))
                                } catch {
                                    let parseError = error as? ParseError ?? ParseError(swift: error)
                                    completion(.failure(parseError))
                                }
                            }
                        } else {
                            completion(result)
                        }
                    }

            } catch {
                callbackQueue.async {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    completion(.failure(parseError))
                }
            }
        }
    }

    func fetchCommand(include: [String]?) throws -> API.Command<Self, Self> {
        guard objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }

        var params: [String: String]?
        if let includeParams = include {
            params = ["include": "\(Set(includeParams))"]
        }

        return API.Command(method: .GET,
                           path: endpoint,
                           params: params) { (data) -> Self in
            try ParseCoding.jsonDecoder().decode(Self.self, from: data)
        }
    }
}

// MARK: Savable
extension ParseInstallation {

    /**
     Saves the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(
        ignoringCustomObjectIdConfig: Bool = false,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<Self, ParseError>) -> Void
    ) {
        Task {
            do {
                let object = try await command(method: Method.save,
                                               ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                                               options: options,
                                               callbackQueue: callbackQueue)
                callbackQueue.async {
                    completion(.success(object))
                }
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Creates the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func create(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.create
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                callbackQueue.async {
                    completion(.success(object))
                }
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Replaces the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func replace(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.replace
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                callbackQueue.async {
                    completion(.success(object))
                }
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Updates the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func update(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<Self, ParseError>) -> Void
    ) {
        let method = Method.update
        Task {
            do {
                let object = try await command(method: method,
                                               options: options,
                                               callbackQueue: callbackQueue)
                callbackQueue.async {
                    completion(.success(object))
                }
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    func saveCommand(ignoringCustomObjectIdConfig: Bool = false) async throws -> API.Command<Self, Self> {
        try await yieldIfNotInitialized()
        if Parse.configuration.isRequiringCustomObjectIds && objectId == nil && !ignoringCustomObjectIdConfig {
            throw ParseError(code: .missingObjectId, message: "objectId must not be nil")
        }
        if try await isSaved() {
            return try replaceCommand() // MARK: Should be switched to "updateCommand" when server supports PATCH.
        }
        return try await createCommand()
    }

    // MARK: Saving ParseObjects - private
    func createCommand() async throws -> API.Command<Self, Self> {
        try await yieldIfNotInitialized()
        var object = self
        if object.ACL == nil,
            let acl = try? await ParseACL.defaultACL() {
            object.ACL = acl
        }
        let updatedObject = object
        let mapper = { @Sendable (data) -> Self in
			do {
				// Try to decode CreateResponse, if that doesn't work try Pointer
				let savedObject = try ParseCoding.jsonDecoder().decode(
					CreateResponse.self,
					from: data
				).apply(
					to: updatedObject
				)
				return savedObject
			} catch let originalError {
				do {
					let pointer = try ParseCoding.jsonDecoder().decode(
						Pointer<Self>.self,
						from: data
					)
					let fetchedObject = try await pointer.fetch()
					return fetchedObject
				} catch {
					throw originalError
				}
			}
        }
        return API.Command<Self, Self>(method: .POST,
                                       path: try await endpoint(.POST),
                                       body: object,
                                       mapper: mapper)
    }

    func replaceCommand() throws -> API.Command<Self, Self> {
        guard self.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        let mapper = { @Sendable (data: Data) -> Self in
            var updatedObject = self
            updatedObject.originalData = nil
            updatedObject = try ParseCoding.jsonDecoder().decode(ReplaceResponse.self,
                                                                 from: data).apply(to: updatedObject)
            // MARK: The lines below should be removed when server supports PATCH.
            guard let originalData = self.originalData,
                  let original = try? ParseCoding.jsonDecoder().decode(Self.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<Self, Self>(method: .PUT,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }

    func updateCommand() throws -> API.Command<Self, Self> {
        guard self.objectId != nil else {
            throw ParseError(code: .missingObjectId,
                             message: "objectId must not be nil")
        }
        let mapper = { @Sendable (data: Data) -> Self in
            var updatedObject = self
            updatedObject.originalData = nil
            updatedObject = try ParseCoding.jsonDecoder().decode(UpdateResponse.self,
                                                                 from: data).apply(to: updatedObject)
            guard let originalData = self.originalData,
                  let original = try? ParseCoding.jsonDecoder().decode(Self.self,
                                                                       from: originalData),
                  original.hasSameObjectId(as: updatedObject) else {
                      return updatedObject
                  }
            return try updatedObject.merge(with: original)
        }
        return API.Command<Self, Self>(method: .PATCH,
                                 path: endpoint,
                                 body: self,
                                 mapper: mapper)
    }
}

// MARK: Deletable
extension ParseInstallation {

    /**
     Deletes the `ParseInstallation` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func delete(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<Void, ParseError>) -> Void
    ) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            do {
                try await deleteCommand()
                    .execute(options: options,
                             callbackQueue: callbackQueue) { result in
                        switch result {

                        case .success:
                            Task {
                                do {
                                    try await Self.updateStorageIfNeeded([self], deleting: true)
                                    completion(.success(()))
                                } catch {
                                    let parseError = error as? ParseError ?? ParseError(swift: error)
                                    completion(.failure(parseError))
                                }
                            }
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    func deleteCommand() async throws -> API.NonParseBodyCommand<NoBody, NoBody> {
        guard try await isSaved() else {
            throw ParseError(code: .otherCause, message: "Cannot Delete an object without id")
        }

        return API.NonParseBodyCommand<NoBody, NoBody>(
            method: .DELETE,
            path: endpoint
        ) { (data) -> NoBody in
            let error = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data)
            if let error = error {
                throw error
            } else {
                return NoBody()
            }
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseInstallation {

	/**
	 Saves a collection of installations all at once *asynchronously* and executes the completion block when done.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
	 when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
	 `objectId` environments. Defaults to false.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
	 - parameter completion: The block to execute.
	 It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
	 - important: If an object saved has the same objectId as current, it will automatically update the current.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
	 and plan to generate all of your `objectId`'s on the client-side then you should leave
	 `ignoringCustomObjectIdConfig = false`. Setting
	 `ParseConfiguration.isRequiringCustomObjectIds = true` and
	 `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
	 and the server will generate an `objectId` only when the client does not provide one. This can
	 increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
	 different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
	 client-side checks are disabled. Developers are responsible for handling such cases.
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
	*/
	func saveAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		ignoringCustomObjectIdConfig: Bool = false,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
	) {
		let originalObjects = Array(self)
		Task {
			do {
				let objects = try await originalObjects.saveAll(
					batchLimit: limit,
					transaction: transaction,
					ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
					options: options,
					callbackQueue: callbackQueue
				)
				try? await Self.Element.updateStorageIfNeeded(
					objects.compactMap { try? $0.get() }
				)
				callbackQueue.async {
					completion(.success(objects))
				}
			} catch {
				let parseError = error as? ParseError ?? ParseError(swift: error)
				callbackQueue.async {
					completion(.failure(parseError))
				}
			}
		}
	}

	/**
	 Creates a collection of installations all at once *asynchronously* and executes the completion block when done.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
	 - parameter completion: The block to execute.
	 It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
	*/
	func createAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
	) {
		let originalObjects = Array(self)
		Task {
			do {
				let objects = try await originalObjects.createAll(
					batchLimit: limit,
					transaction: transaction,
					options: options,
					callbackQueue: callbackQueue
				)
				try? await Self.Element.updateStorageIfNeeded(
					objects.compactMap { try? $0.get() }
				)
				callbackQueue.async {
					completion(.success(objects))
				}
			} catch {
				let parseError = error as? ParseError ?? ParseError(swift: error)
				callbackQueue.async {
					completion(.failure(parseError))
				}
			}
		}
	}

	/**
	 Replaces a collection of installations all at once *asynchronously* and executes the completion block when done.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
	 - parameter completion: The block to execute.
	 It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
	 - important: If an object replaced has the same objectId as current, it will automatically replace the current.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
	*/
	func replaceAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
	) {
		let originalObjects = Array(self)
		Task {
			do {
				let objects = try await originalObjects.replaceAll(
					batchLimit: limit,
					transaction: transaction,
					options: options,
					callbackQueue: callbackQueue
				)
				try? await Self.Element.updateStorageIfNeeded(
					objects.compactMap { try? $0.get() }
				)
				callbackQueue.async {
					completion(.success(objects))
				}
			} catch {
				let parseError = error as? ParseError ?? ParseError(swift: error)
				callbackQueue.async {
					completion(.failure(parseError))
				}
			}
		}
	}

	/**
	 Updates a collection of installations all at once *asynchronously* and executes the completion block when done.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
	 - parameter completion: The block to execute.
	 It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
	 - important: If an object updated has the same objectId as current, it will automatically update the current.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
	*/
	internal func updateAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
	) {
		let originalObjects = Array(self)
		Task {
			do {
				let objects = try await originalObjects.updateAll(
					batchLimit: limit,
					transaction: transaction,
					options: options,
					callbackQueue: callbackQueue
				)
				try? await Self.Element.updateStorageIfNeeded(
					objects.compactMap { try? $0.get() }
				)
				callbackQueue.async {
					completion(.success(objects))
				}
			} catch {
				let parseError = error as? ParseError ?? ParseError(swift: error)
				callbackQueue.async {
					completion(.failure(parseError))
				}
			}
		}
	}

	/**
	 Fetches a collection of installations all at once *asynchronously* and executes the completion block when done.
	 - parameter includeKeys: The name(s) of the key(s) to include that are
	 `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
	 `includeAll` for `Query`.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
	 - parameter completion: The block to execute.
	 It should have the following argument signature: `(Result<[(Result<Element, ParseError>)], ParseError>)`.
	 - important: If an object fetched has the same objectId as current, it will automatically update the current.
	 - warning: The order in which installations are returned are not guaranteed. You should not expect results in
	 any particular order.
	*/
	func fetchAll(
		includeKeys: [String]? = nil,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<[(Result<Element, ParseError>)], ParseError>) -> Void
	) {
		if (allSatisfy { $0.className == Self.Element.className}) {
			let uniqueObjectIds = Array(Set(compactMap { $0.objectId }))
			var query = Self.Element.query(containedIn(key: "objectId", array: uniqueObjectIds))
			if let include = includeKeys {
				query = query.include(include)
			}
			query.find(options: options, callbackQueue: callbackQueue) { result in
				switch result {

				case .success(let fetchedObjects):
					let fetchedObjectsToReturn = uniqueObjectIds.map { uniqueObjectId -> (Result<Self.Element, ParseError>) in
						if let fetchedObject = fetchedObjects.first(where: {$0.objectId == uniqueObjectId}) {
							return .success(fetchedObject)
						} else {
							let error = ParseError(
								code: .objectNotFound,
								message: "objectId \"\(uniqueObjectId)\" was not found in className \"\(Self.Element.className)\""
							)
							return .failure(error)
						}
					}
					Task {
						try? await Self.Element.updateStorageIfNeeded(fetchedObjects)
						callbackQueue.async {
							completion(.success(fetchedObjectsToReturn))
						}
					}
				case .failure(let error):
					callbackQueue.async {
						completion(.failure(error))
					}
				}
			}
		} else {
			let error = ParseError(
				code: .otherCause,
				message: "All objects must have the same class"
			)
			callbackQueue.async {
				completion(.failure(error))
			}
		}
	}

	/**
	 Deletes a collection of installations all at once *asynchronously* and executes the completion block when done.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
	 - parameter completion: The block to execute.
	 It should have the following argument signature: `(Result<[(Result<Void, ParseError>)], ParseError>)`.
	 Each element in the array is either `nil` if the delete successful or a `ParseError` if it failed.
	 1. A `ParseError.Code.aggregateError`. This object's "errors" property is an
	 array of other Parse.Error objects. Each error object in this array
	 has an "object" property that references the object that could not be
	 deleted (for instance, because that object could not be found).
	 2. A non-aggregate Parse.Error. This indicates a serious error that
	 caused the delete operation to be aborted partway through (for
	 instance, a connection failure in the middle of the delete).
	 - important: If an object deleted has the same objectId as current, it will automatically update the current.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
	*/
	func deleteAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<[(Result<Void, ParseError>)], ParseError>) -> Void
	) {
		let originalObjects = Array(self)
		Task {
			do {
				let objects = try await originalObjects.deleteAll(
					batchLimit: limit,
					transaction: transaction,
					options: options,
					callbackQueue: callbackQueue
				)
				try? await Self.Element.updateStorageIfNeeded(
					originalObjects,
					deleting: true
				)
				callbackQueue.async {
					completion(.success(objects))
				}
			} catch {
				let parseError = error as? ParseError ?? ParseError(swift: error)
				callbackQueue.async {
					completion(.failure(parseError))
				}
			}
		}
	}
}

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
// MARK: Migrate from Objective-C SDK
public extension ParseInstallation {

    /**
     Deletes the Objective-C Keychain along with the Objective-C `ParseInstallation`
     from the Parse Server *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default
     value of .main.
     - parameter completion: The block to execute when completed.
     It should have the following argument signature: `(Result<Void, ParseError>)`.
     - warning: It is recommended to only use this method after a succesfful migration. Calling this
     method will destroy the entire Objective-C Keychain and `ParseInstallation` on the Parse
     Server.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func deleteObjCKeychain( // swiftlint:disable:this function_body_length
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping @Sendable (Result<Void, ParseError>) -> Void
    ) {
        Task {
            do {
                try await yieldIfNotInitialized()
            } catch {
                let defaultError = ParseError(
                    code: .otherCause,
                    swift: error
                )
                let parseError = error as? ParseError ?? defaultError
                callbackQueue.async {
                    completion(.failure(parseError))
                }
                return
            }
			let objcParseKeychain = KeychainStore.createObjectiveC()
            guard let oldInstallationId: String = objcParseKeychain.objectObjectiveC(forKey: "installationId") else {
                let error = ParseError(code: .otherCause,
                                       message: "Could not find Installation in the Objective-C SDK Keychain")
                callbackQueue.async {
                    completion(.failure(error))
                }
                return
            }
            do {
                var currentInstallation = try await Self.current()
                currentInstallation.installationId = oldInstallationId
                do {
                    try await deleteObjectiveCKeychain()
                    // Only delete the `ParseInstallation` on Parse Server if it is not current.
                    guard currentInstallation.installationId == oldInstallationId else {
                        currentInstallation.delete(options: options,
                                                   callbackQueue: callbackQueue,
                                                   completion: completion)
                        return
                    }
                    callbackQueue.async {
                        completion(.success(()))
                    }
                } catch {
                    callbackQueue.async {
                        completion(.failure(ParseError(swift: error)))
                    }
                    return
                }
            } catch {
                let error = ParseError(code: .otherCause,
                                       message: "Current installation does not exist")
                callbackQueue.async {
                    completion(.failure(error))
                }
            }
        }
    }
}
#endif // swiftlint:disable:this file_length
