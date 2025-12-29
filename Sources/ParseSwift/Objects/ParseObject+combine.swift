//
//  ParseObject+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)
import Foundation
import Combine

public extension ParseObject {

    // MARK: Combine
    /**
     Fetches the `ParseObject` *aynchronously* with the current data from the server.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
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
     Saves the `ParseObject` *asynchronously* and publishes when complete.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
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
     Creates the `ParseObject` *asynchronously* and publishes when complete.

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
     Replaces the `ParseObject` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func replacePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.replace(options: options,
                         completion: promise)
        }
    }

    /**
     Updates the `ParseObject` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    internal func updatePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options,
                        completion: promise)
        }
    }

    /**
     Deletes the `ParseObject` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}

public extension Sequence where Element: ParseObject {
    /**
     Fetches a collection of objects *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a fetch was
     successful or a `ParseError` if it failed.
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

#endif
