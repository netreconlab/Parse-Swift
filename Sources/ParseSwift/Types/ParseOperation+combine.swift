//
//  ParseOperation+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)
import Foundation
import Combine

public extension ParseOperation {

    // MARK: Combine

    /**
     Saves the operations on the `ParseObject` *asynchronously*. Publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func savePublisher(options: API.Options = []) -> Future<T, ParseError> {
        Future { promise in
            self.save(options: options,
                      completion: promise)
        }
    }
}

#endif
