//
//  ParseConfig+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseConfig {

    // MARK: Combine

    /**
     Fetch the Config *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetch(
				options: options
			) { result in
				switch result {
				case .success(let config):
					promise(.success(config))
				case .failure(let error):
					promise(.failure(error))
				}

			}
        }
    }

    /**
     Update the Config *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func savePublisher(options: API.Options = []) -> Future<Bool, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.save(
				options: options
			) { result in
				switch result {
				case .success(let saved):
					promise(.success(saved))
				case .failure(let error):
					promise(.failure(error))
				}

			}
        }
    }
}

#endif
