//
//  ParseHookTriggerable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
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
    func fetchPublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetch(
				options: options
			) { result in
				switch result {
				case .success(let hookTrigger):
					promise(.success(hookTrigger))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Fetches the Parse hook triggers *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchAllPublisher(
		options: API.Options = []
	) -> Future<[Self], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetchAll(
				options: options
			) { result in
				switch result {
				case .success(let hookTriggers):
					promise(.success(hookTriggers))
				case .failure(let error):
					promise(.failure(error))
				}
			}
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
    func createPublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.create(
				options: options
			) { result in
				switch result {
				case .success(let hookTrigger):
					promise(.success(hookTrigger))
				case .failure(let error):
					promise(.failure(error))
				}
			}
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
    func updatePublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.update(
				options: options
			) { result in
				switch result {
				case .success(let hookTrigger):
					promise(.success(hookTrigger))
				case .failure(let error):
					promise(.failure(error))
				}
			}
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
    func deletePublisher(
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.delete(
				options: options
			) { result in
				switch result {
				case .success:
					promise(.success(()))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}
#endif
