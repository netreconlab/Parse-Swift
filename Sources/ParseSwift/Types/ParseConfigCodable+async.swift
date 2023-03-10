//
//  ParseConfigCodable+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 3/10/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

public extension ParseConfigCodable {

    // MARK: Fetchable - Async/Await

    /**
     Fetch the Config *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: The return type of self.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func fetch(options: API.Options = []) async throws -> [String: V] {
        try await withCheckedThrowingContinuation { continuation in
            Self.fetch(options: options,
                       completion: continuation.resume)
        }
    }

    // MARK: Savable - Async/Await

    /**
     Update the Config *asynchronously*.
     - parameter config: The Config to update on the server.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: **true** if saved, **false** if save is unsuccessful.
     - throws: An error of type `ParseError`.
    */
    static func save(_ config: [String: V],
                     options: API.Options = []) async throws -> Bool {
        try await withCheckedThrowingContinuation { continuation in
            Self.save(config,
                      options: options,
                      completion: continuation.resume)
        }
    }
}
