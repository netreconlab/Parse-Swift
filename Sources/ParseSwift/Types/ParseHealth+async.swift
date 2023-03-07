//
//  ParseHealth+async.swift
//  ParseHealth+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

public extension ParseHealth {

    // MARK: Async/Await

    /**
     Calls the health check function *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Status of ParseServer.
     - throws: An error of type `ParseError`.
     - important: Calls to this method will only return `Status.ok` or throw a `ParseError`.
     Other status values such as `Status.initialized` or `Status.starting` will never
     be produced. If you desire other statuses, either use the completion handler or publisher version of
     this method.
    */
    static func check(options: API.Options = []) async throws -> Status {
        try await withCheckedThrowingContinuation { continuation in
            Self.check(options: options,
                       allowIntermediateResponses: false,
                       completion: continuation.resume)
        }
    }
}
