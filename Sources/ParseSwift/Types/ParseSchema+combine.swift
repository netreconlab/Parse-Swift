//
//  ParseSchema+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/22/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseSchema {
    /**
     Fetches the `ParseSchema` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
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
				case .success(let schema):
					promise(.success(schema))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Creates the `ParseSchema` *aynchronously* on the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
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
				case .success(let schema):
					promise(.success(schema))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Updates the `ParseSchema` *aynchronously* on the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
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
				case .success(let schema):
					promise(.success(schema))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Deletes all objects in the `ParseSchema` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: This will delete all objects for this `ParseSchema` and cannot be reversed.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    func purgePublisher(
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.purge(
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

    /**
     Deletes the `ParseSchema` *aynchronously* from the server. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: This can only be used on a `ParseSchema` without objects. If the `ParseSchema`
     currently contains objects, run `purge()` first.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
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
