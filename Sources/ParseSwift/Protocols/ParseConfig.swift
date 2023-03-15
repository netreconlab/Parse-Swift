//
//  ParseConfig.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/22/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 Objects that conform to the `ParseConfig` protocol are able to access the Config on the Parse Server.
 When conforming to `ParseConfig`, any properties added can be retrieved by the client or updated on
 the server. The current `ParseConfig` is persisted to the Keychain and Parse Server.
 - note: Stored and fetched versions `ParseConfigCodable` and types that conform
 `ParseConfig`are interoperable and access the same Config.
*/
public protocol ParseConfig: ParseTypeable {}

// MARK: Update
extension ParseConfig {

    /**
     Fetch the Config *asynchronously*.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when retrieving the config completes or fails.
        It should have the following argument signature: `(Result<Self, ParseError>)`.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public func fetch(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await fetchCommand()
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         completion: completion)
        }
    }

    internal func fetchCommand() async -> API.NonParseBodyCommand<Self, Self> {

        return API.NonParseBodyCommand(method: .GET,
                                       path: .config) { (data) -> Self in
            let fetched = try ParseCoding.jsonDecoder().decode(ConfigFetchResponse<Self>.self, from: data).params
            await Self.updateStorageIfNeeded(fetched)
            return fetched
        }
    }
}

// MARK: Update
extension ParseConfig {

    /**
     Update the Config *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when retrieving the config completes or fails.
     It should have the following argument signature: `(Result<Bool, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public func save(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<Bool, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await updateCommand()
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         completion: completion)
        }
    }

    internal func updateCommand() async -> API.NonParseBodyCommand<ConfigUpdateBody<Self>, Bool> {
        let body = ConfigUpdateBody(params: self)
        return API.NonParseBodyCommand(method: .PUT, // MARK: Should be switched to ".PATCH" when server supports PATCH.
                                       path: .config,
                                       body: body) { (data) -> Bool in
            let updated = try ParseCoding.jsonDecoder().decode(BooleanResponse.self, from: data).result

            if updated {
                await Self.updateStorageIfNeeded(self)
            }
            return updated
        }
    }
}

internal struct ConfigUpdateBody<T>: ParseTypeable, Decodable where T: ParseConfig {
    let params: T
}

// MARK: Current
struct CurrentConfigContainer<T: ParseConfig>: Codable, Equatable {
    var currentConfig: T?
}

extension ParseConfig {

    /**
     Gets/Sets properties of the current config in the Keychain.

     - returns: Returns the latest `ParseConfig` on this device. If there is none, throws an error.
     - throws: An error of `ParseError` type.
    */
    public static func current() async throws -> Self {
        try await yieldIfNotInitialized()
        guard let container = await Self.currentContainer(),
                let config = container.currentConfig else {
            throw ParseError(code: .otherCause,
                             message: "There is no current Config")
        }
        return config
    }

    static func currentContainer() async -> CurrentConfigContainer<Self>? {
        guard let configInMemory: CurrentConfigContainer<Self> =
            try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
            #if !os(Linux) && !os(Android) && !os(Windows)
                return try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
            #else
                return nil
            #endif
        }
        return configInMemory
    }

    static func setCurrentContainer(_ newValue: CurrentConfigContainer<Self>?) async {
        try? await ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? await KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
        #endif
    }

    static func updateStorageIfNeeded(_ result: Self, deleting: Bool = false) async {
        if !deleting {
            await Self.setCurrent(result)
        } else {
            await Self.deleteCurrentContainerFromStorage()
        }
    }

    static func deleteCurrentContainerFromStorage() async {
        try? await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
        #endif
    }

    static func setCurrent(_ current: Self?) async {
        if await Self.currentContainer() == nil {
            await Self.setCurrentContainer(CurrentConfigContainer<Self>())
        }
        var currentContainer = await Self.currentContainer()
        currentContainer?.currentConfig = current
        await Self.setCurrentContainer(currentContainer)
    }
}
