//
//  ParseServer.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
  `ParseHealth` allows you to check the health of a Parse Server.
 */
@available(*, deprecated, renamed: "ParseServer")
public typealias ParseHealth = ParseServer

/**
  `ParseServer` allows you to check the health or retrieve general information about a Parse Server.
 */
public struct ParseServer: ParseTypeable {

    /// The health status value of a Parse Server.
    public enum Status: String, Codable, Sendable {
        /// The server started and is running.
        case ok
        /// The server has been created but the start method has not been called yet.
        case initialized
        /// The server is starting up.
        case starting
        /// There was a startup error, see the logs for details.
        case error
    }

    /// Any provided information from the Parse Server.
    public struct Information: Decodable, Sendable {

        /// The version of the Parse Server.
        public var version: ParseVersion? {
            guard let versionString = versionString else {
                return nil
            }
            return try? ParseVersion(string: versionString)
        }
        var versionString: String?
        var features: AnyDecodable?

        enum CodingKeys: String, CodingKey { // swiftlint:disable:this nesting
            case versionString = "parseServerVersion"
            case features
        }

        /**
         Get all of the features available from the Parse Server.
         - returns: A decodable type that can consist of many different sub types.
         */
        public func getFeatures<T: Decodable>() throws -> T {
            guard let features = features else {
                throw ParseError(code: .otherCause,
                                 message: "There are no features available from the server")
            }
            guard let currentFeatures = features.value as? T else {
                throw ParseError(code: .otherCause,
                                 message: "Could not cast \"\(features)\"; to unreleated type: \"\(T.self)\"")
            }
            return currentFeatures
        }

    }
}

// MARK: Health
extension ParseServer {

    /**
     Check the server health *asynchronously* and returns the result of its execution.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter allowIntermediateResponses: If *true*, this method will continue to update `Status`
     until the server returns `Status.ok`. Otherwise, calling this method will only return `Status.ok`
     or throw a `ParseError`.
     - parameter completion: A block that will be called when the health check completes or fails.
     It should have the following argument signature: `(Result<Status, ParseError>)`.
    */
    static public func health(options: API.Options = [],
                              callbackQueue: DispatchQueue = .main,
                              allowIntermediateResponses: Bool = true,
                              completion: @escaping @Sendable (Result<Status, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await healthCommand()
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         allowIntermediateResponses: allowIntermediateResponses,
                         completion: completion)
        }
    }

    /**
     Check the server health *asynchronously* and returns the result of its execution.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter allowIntermediateResponses: If *true*, this method will continue to update `Status`
     until the server returns `Status.ok`. Otherwise, calling this method will only return `Status.ok`
     or throw a `ParseError`.
     - parameter completion: A block that will be called when the health check completes or fails.
     It should have the following argument signature: `(Result<Status, ParseError>)`.
    */
    @available(*, deprecated, renamed: "health")
    static public func check(options: API.Options = [],
                             callbackQueue: DispatchQueue = .main,
                             allowIntermediateResponses: Bool = true,
                             completion: @escaping @Sendable (Result<Status, ParseError>) -> Void) {
        health(options: options,
               callbackQueue: callbackQueue,
               allowIntermediateResponses: allowIntermediateResponses,
               completion: completion)
    }

    internal static func healthCommand() -> API.Command<NoBody, Status> {
        return API.Command(method: .POST,
                           path: .health) { (data) -> Status in
            return try ParseCoding.jsonDecoder().decode(HealthResponse.self, from: data).status
        }
    }

}

// MARK: Information
extension ParseServer {

    /**
     Retrieves any information provided by the server *asynchronously* and returns the result of its execution.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: A block that will be called when the health check completes or fails.
     It should have the following argument signature: `(Result<Information, ParseError>)`.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    static public func information(options: API.Options = [],
                                   callbackQueue: DispatchQueue = .main,
                                   completion: @escaping @Sendable (Result<Information, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            await infoCommand()
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         completion: completion)
        }
    }

    internal static func infoCommand() -> API.Command<NoBody, Information> {
        return API.Command(method: .GET,
                           path: .serverInfo) { (data) -> Information in
            return try ParseCoding.jsonDecoder().decode(Information.self, from: data)
        }
    }

}
