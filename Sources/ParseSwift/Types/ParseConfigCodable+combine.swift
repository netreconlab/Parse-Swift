//
//  ParseConfigCodable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/10/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseConfigCodable {

    // MARK: Combine

    /**
     Fetch the Config *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func fetchPublisher(options: API.Options = []) -> Future<[String: V], ParseError> {
        Future { promise in
            Self.fetch(options: options,
                       completion: promise)
        }
    }

    /**
     Update the Config *asynchronously*. Publishes when complete.
     - parameter config: The Config to update on the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func savePublisher(_ config: [String: V],
                              options: API.Options = []) -> Future<Bool, ParseError> {
        Future { promise in
            Self.save(config,
                      options: options,
                      completion: promise)
        }
    }

}

#endif
