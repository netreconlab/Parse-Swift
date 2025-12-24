//
//  ParseHookTriggerable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)
import Foundation
import Combine

// MARK: Fetch
public extension ParseHookTriggerable {
    /**
     Fetches the Parse hook trigger *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func fetchPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.fetch(options: options, completion: promise)
        }
    }

    /**
     Fetches the Parse hook triggers *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func fetchAllPublisher(options: API.Options = []) -> Future<[Self], ParseError> {
        Future { promise in
            self.fetchAll(options: options, completion: promise)
        }
    }
}

// MARK: Create
public extension ParseHookTriggerable {
    /**
     Creates the Parse hook trigger *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func createPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.create(options: options, completion: promise)
        }
    }
}

// MARK: Update
public extension ParseHookTriggerable {
    /**
     Updates the Parse hook trigger *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func updatePublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.update(options: options, completion: promise)
        }
    }
}

// MARK: Delete
public extension ParseHookTriggerable {
    /**
     Deletes the Parse hook trigger *asynchronously*. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func deletePublisher(options: API.Options = []) -> Future<Void, ParseError> {
        Future { promise in
            self.delete(options: options, completion: promise)
        }
    }
}
#endif
