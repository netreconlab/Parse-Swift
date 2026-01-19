//
//  ParseHookFunctionable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Combine

// MARK: Fetch
public extension ParseHookFunctionable {
    /**
     Fetches the Parse hook function *asynchronously*. Publishes when complete.
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
				case .success(let hookFunction):
					promise(.success(hookFunction))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Fetches all of the Parse hook functions *asynchronously*. Publishes when complete.
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
				case .success(let hookFunctions):
					promise(.success(hookFunctions))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

// MARK: Create
public extension ParseHookFunctionable {
    /**
     Creates the Parse hook function *asynchronously*. Publishes when complete.
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
				case .success(let hookFunction):
					promise(.success(hookFunction))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

// MARK: Update
public extension ParseHookFunctionable {
    /**
     Updates the Parse hook function *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: Do not use on Parse Server 5.3.0 and below. Instead, delete and create.
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
				case .success(let hookFunction):
					promise(.success(hookFunction))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

// MARK: Delete
public extension ParseHookFunctionable {
    /**
     Deletes the Parse hook function *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
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
