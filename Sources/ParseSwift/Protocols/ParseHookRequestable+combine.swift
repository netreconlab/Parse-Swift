//
//  ParseHookRequestable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseHookRequestable {
    /**
     Fetches the complete `ParseUser`. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func hydrateUserPublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.hydrateUser(
				options: options
			) { result in
				switch result {
				case .success(let hookRequest):
					promise(.success(hookRequest))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}
#endif
