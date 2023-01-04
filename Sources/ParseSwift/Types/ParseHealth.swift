//
//  ParseHealth.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation

/**
  `ParseHealth` allows you to check the health of a Parse Server.
 */
public struct ParseHealth: ParseTypeable {

    /// The health status value of a Parse Server.
    public enum Status: String, Codable {
        /// The server started and is running.
        case ok
        /// The server has been created but the start method has not been called yet.
        case initialized
        /// The server is starting up.
        case starting
        /// There was a startup error, see the logs for details.
        case error
    }

    /**
     Calls the health check function *synchronously* and returns a result of it is execution.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the status of the server.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static public func check(options: API.Options = []) throws -> Status {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        return try healthCommand().execute(options: options)
    }

    /**
     Calls the health check function *asynchronously* and returns a result of it is execution.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when the health check completes or fails.
     It should have the following argument signature: `(Result<String, ParseError>)`.
    */
    static public func check(options: API.Options = [],
                             callbackQueue: DispatchQueue = .main,
                             completion: @escaping (Result<Status, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        healthCommand()
            .executeAsync(options: options,
                          callbackQueue: callbackQueue,
                          completion: completion)
    }

    internal static func healthCommand() -> API.Command<NoBody, Status> {
        return API.Command(method: .POST,
                           path: .health) { (data) -> Status in
            return try ParseCoding.jsonDecoder().decode(HealthResponse.self, from: data).status
        }
    }
}
