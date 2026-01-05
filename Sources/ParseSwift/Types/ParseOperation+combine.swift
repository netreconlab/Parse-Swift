//
//  ParseOperation+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseOperation {

    // MARK: Combine

    /**
     Saves the operations on the `ParseObject` *asynchronously*. Publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func savePublisher(
		options: API.Options = []
	) -> Future<T, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.save(
				options: options
			) { result in
				switch result {
				case .success(let object):
					promise(.success(object))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

#endif
