//
//  ParseConfigCodable.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/10/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 `ParseConfigCodable` allows access to the Config on the Parse Server as a
 dictionary where the keys are **strings** and the values are **Codable**.
 The current `ParseConfig` is persisted to the Keychain and Parse Server.
 - note: `ParseConfigCodable` or created types that conform
 `ParseConfigCodable` both access the same Config.
*/
public struct ParseConfigCodable<V: Codable> {}

// MARK: Update
extension ParseConfigCodable {

    /**
     Fetch the Config *asynchronously*.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of .main.
        - parameter completion: A block that will be called when retrieving the config completes or fails.
        It should have the following argument signature: `(Result<Self, ParseError>)`.
        - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
        desires a different policy, it should be inserted in `options`.
    */
    public static func fetch(options: API.Options = [],
                             callbackQueue: DispatchQueue = .main,
                             completion: @escaping (Result<[String: V], ParseError>) -> Void) {
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
                .decode(ParseConfigCodableFetchResponse<V>.self, from: data).params
            await Self.updateKeychainIfNeeded(fetched)
            return fetched
        }
    }
}

// MARK: Update
extension ParseConfigCodable {

    /**
     Update the Config *asynchronously*.
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
                            completion: @escaping (Result<Bool, ParseError>) -> Void) {
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
    internal static func updateCommand(_ config: [String: V]) async -> API.NonParseBodyCommand<ParseConfigCodableUpdateBody<[String: V]>, Bool> {
        let body = ParseConfigCodableUpdateBody(params: config)
        return API.NonParseBodyCommand(method: .PUT, // MARK: Should be switched to ".PATCH" when server supports PATCH.
                                       path: .config,
                                       body: body) { (data) -> Bool in
            let updated = try ParseCoding.jsonDecoder().decode(BooleanResponse.self, from: data).result

            if updated {
                await Self.updateKeychainIfNeeded(config)
            }
            return updated
        }
    }
}

// MARK: Current
extension ParseConfigCodable {

    /**
     Gets/Sets properties of the current config in the Keychain.

     - returns: Returns the latest `ParseConfig` on this device. If there is none, throws an error.
     - throws: An error of `ParseError` type.
    */
    public static func current() async throws -> [String: V] {
        guard let container = await Self.currentContainer(),
                let config = container.currentConfig else {
            throw ParseError(code: .otherCause,
                             message: "There is no current Config")
        }
        return config
    }

    static func currentContainer() async -> CurrentConfigDictionaryContainer<V>? {
        await yieldIfNotInitialized()
        guard let configInMemory: CurrentConfigDictionaryContainer<V> =
            try? await ParseStorage.shared.get(valueFor: ParseStorage.Keys.currentConfig) else {
            #if !os(Linux) && !os(Android) && !os(Windows)
                return try? await KeychainStore.shared.get(valueFor: ParseStorage.Keys.currentConfig)
            #else
                return nil
            #endif
        }
        return configInMemory
    }

    static func setCurrentContainer(_ newValue: CurrentConfigDictionaryContainer<V>?) async {
        try? await ParseStorage.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? await KeychainStore.shared.set(newValue, for: ParseStorage.Keys.currentConfig)
        #endif
    }

    static func updateKeychainIfNeeded(_ result: [String: V], deleting: Bool = false) async {
        if !deleting {
            await Self.setCurrent(result)
        } else {
            await Self.deleteCurrentContainerFromKeychain()
        }
    }

    internal static func deleteCurrentContainerFromKeychain() async {
        try? await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
        #if !os(Linux) && !os(Android) && !os(Windows)
        try? await KeychainStore.shared.delete(valueFor: ParseStorage.Keys.currentConfig)
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

struct CurrentConfigDictionaryContainer<T: Codable>: Codable {
    var currentConfig: [String: T]?
}

// MARK: ParseConfigCodableUpdateBody
internal struct ParseConfigCodableUpdateBody<T>: Codable where T: Codable {
    let params: T
}

// MARK: ParseConfigCodableFetchResponse
internal struct ParseConfigCodableFetchResponse<T>: Codable where T: Codable {
    let params: [String: T]
}
