//
//  ParseServer+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

public extension ParseServer {

    // MARK: Async/Await

    /**
     Check the server health *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Status of ParseServer.
     - throws: An error of type `ParseError`.
     - important: Calls to this method will only return `Status.ok` or throw a `ParseError`.
     Other status values such as `Status.initialized` or `Status.starting` will never
     be produced. If you desire other statuses, either use the completion handler or publisher version of
     this method.
    */
    static func health(options: API.Options = []) async throws -> Status {
        try await withCheckedThrowingContinuation { continuation in
            Self.health(options: options,
                        allowIntermediateResponses: false,
                        completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Retrieves any information provided by the server *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Status of ParseServer.
     - throws: An error of type `ParseError`.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    static func information(options: API.Options = []) async throws -> Information {
        try await withCheckedThrowingContinuation { continuation in
            Self.information(options: options,
                             completion: { continuation.resume(with: $0) })
        }
    }

}
