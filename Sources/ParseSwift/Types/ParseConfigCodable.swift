//
//  ParseConfigCodable.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/10/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 `ParseConfigCodable` allows access to the Config on the Parse Server as a
 dictionary where the keys are **strings** and the values are **Codable**.
 The current `ParseConfigCodable` is persisted to the Keychain and Parse Server.
 - note: Stored and fetched versions `ParseConfigCodable` and types that conform
 `ParseConfig`are interoperable and access the same Config.
*/
public struct ParseConfigCodable<V: Codable & Sendable> {}

// MARK: Update
extension ParseConfigCodable {

    /**
     Fetch the Config *asynchronously*.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when retrieving the config completes or fails.
        It should have the following argument signature: `(Result<[String: V], ParseError>)`.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public static func fetch(options: API.Options = [],
                             callbackQueue: DispatchQueue = .main,
                             completion: @escaping @Sendable (Result<[String: V], ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await fetchCommand()
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         completion: completion)
        }
    }

    internal static func fetchCommand() async -> API.NonParseBodyCommand<[String: V], [String: V]> {
        return API.NonParseBodyCommand(method: .GET,
                                       path: .config) { (data) -> [String: V] in
            let fetched = try ParseCoding
                .jsonDecoder()
                .decode(ConfigCodableFetchResponse<V>.self, from: data).params
            await Self.updateStorageIfNeeded(fetched)
            return fetched
        }
    }

}

// MARK: Update
extension ParseConfigCodable {

    /**
     Update the Config *asynchronously*.
     - parameter config: The Config to update on the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when retrieving the config completes or fails.
     It should have the following argument signature: `(Result<Bool, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    public static func save(_ config: [String: V],
                            options: API.Options = [],
                            callbackQueue: DispatchQueue = .main,
                            completion: @escaping @Sendable (Result<Bool, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await updateCommand(config)
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         completion: completion)
        }
    }

    // swiftlint:disable:next line_length
    internal static func updateCommand(_ config: [String: V]) async -> API.NonParseBodyCommand<ConfigCodableUpdateBody<[String: V]>, Bool> {
        let body = ConfigCodableUpdateBody(params: config)
        return API.NonParseBodyCommand(method: .PUT, // MARK: Should be switched to ".PATCH" when server supports PATCH.
                                       path: .config,
                                       body: body) { (data) -> Bool in
            let updated = try ParseCoding.jsonDecoder().decode(BooleanResponse.self, from: data).result

            if updated {
                await Self.updateStorageIfNeeded(config)
            }
            return updated
        }
    }

}

// MARK: Current
extension ParseConfigCodable {

    /**
     Get the current config from the Keychain.

     - returns: Returns the latest `ParseConfigCodable` on this device. If there is none, throws an error.
     - throws: An error of `ParseError` type.
    */
    public static func current() async throws -> [String: V] {
        try await yieldIfNotInitialized()
        guard let container = await Self.currentContainer(),
                let config = container.currentConfig else {
            throw ParseError(code: .otherCause,
                             message: "There is no current Config")
        }
        return config
    }

    static func currentContainer() async -> CurrentConfigDictionaryContainer<V>? {
        guard let configInMemory: CurrentConfigDictionaryContainer<V> =
            try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
            #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
                return try? KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
            #else
                return nil
            #endif
        }
        return configInMemory
    }

    static func setCurrentContainer(_ newValue: CurrentConfigDictionaryContainer<V>?) async {
        try? await ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try? KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
        #endif
    }

    static func updateStorageIfNeeded(_ result: [String: V], deleting: Bool = false) async {
        if !deleting {
            await Self.setCurrent(result)
        } else {
            await Self.deleteCurrentContainerFromStorage()
        }
    }

    internal static func deleteCurrentContainerFromStorage() async {
        try? await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try? KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
        #endif
    }

    static func setCurrent(_ current: [String: V]?) async {
        if await Self.currentContainer() == nil {
            await Self.setCurrentContainer(CurrentConfigDictionaryContainer<V>())
        }
        var currentContainer = await Self.currentContainer()
        currentContainer?.currentConfig = current
        await Self.setCurrentContainer(currentContainer)
    }

}

struct CurrentConfigDictionaryContainer<T: Codable & Sendable>: Codable & Sendable {
    var currentConfig: [String: T]?
}

// MARK: ConfigCodableUpdateBody
internal struct ConfigCodableUpdateBody<T>: Codable where T: Codable & Sendable {
    let params: T
}

// MARK: ConfigCodableFetchResponse
internal struct ConfigCodableFetchResponse<T>: Codable where T: Codable & Sendable {
    let params: [String: T]
}
