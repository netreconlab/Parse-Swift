//
//  ParseInstallation+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)
import Foundation
import Combine

public extension ParseInstallation {

    // MARK: Combine
    /**
     Fetches the `ParseInstallation` *aynchronously* with the current data from the server.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func fetchPublisher(includeKeys: [String]? = nil,
                        options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Saves the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func savePublisher(ignoringCustomObjectIdConfig: Bool = false,
                       options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Creates the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func createPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.create(options: options,
                        completion: promise)
        }
    }

    /**
     Replaces the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func replacePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.replace(options: options,
                         completion: promise)
        }
    }

    /**
     Updates the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    internal func updatePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options,
                        completion: promise)
        }
    }

    /**
     Deletes the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }

    /**
     Copies the `ParseInstallation` *asynchronously* based on the `installationId` and publishes
     when complete. On success, this saves the `ParseInstallation` to the keychain, so you can retrieve
     the current installation using *current*.

     - parameter installationId: The **id** of the `ParseInstallation` to become.
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
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    static func becomePublisher(_ installationId: String,
                                copyEntireInstallation: Bool = true,
                                options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            Self.become(installationId,
                        copyEntireInstallation: copyEntireInstallation,
                        options: options,
                        completion: promise)
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseInstallation {
    /**
     Fetches a collection of installations *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a fetch was
     successful or a `ParseError` if it failed.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func fetchAllPublisher(includeKeys: [String]? = nil,
                           options: API.Options = []) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
            self.fetchAll(includeKeys: includeKeys,
                          options: options,
                          completion: promise)
        }
    }
}

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
// MARK: Migrate from Objective-C SDK
public extension ParseInstallation {
    /**
     Deletes the Objective-C Keychain along with the Objective-C `ParseInstallation`
     from the Parse Server *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: It is recommended to only use this method after a succesfful migration. Calling this
     method will destroy the entire Objective-C Keychain and `ParseInstallation` on the Parse
     Server.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    static func deleteObjCKeychainPublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            Self.deleteObjCKeychain(options: options, completion: promise)
        }
    }
}
#endif
#endif
