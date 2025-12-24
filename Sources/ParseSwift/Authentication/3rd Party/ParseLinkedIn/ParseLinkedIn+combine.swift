//
//  ParseLinkedIn+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)
import Foundation
import Combine

public extension ParseLinkedIn {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using LinkedIn authentication for graph API login. Publishes when complete.
     - parameter id: The **id** from **LinkedIn**.
     - parameter accessToken: Required **access_token** from **LinkedIn**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func loginPublisher(id: String,
                        accessToken: String,
                        isMobileSDK: Bool,
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(id: id,
                       accessToken: accessToken,
                       isMobileSDK: isMobileSDK,
                       options: options,
                       completion: promise)
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using LinkedIn authentication for graph API login. Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func loginPublisher(authData: [String: String],
                        options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.login(authData: authData,
                       options: options,
                       completion: promise)
        }
    }
}

public extension ParseLinkedIn {
    /**
     Link the *current* `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     Publishes when complete.
     - parameter id: The **id** from **LinkedIn**.
     - parameter accessToken: Required **access_token** from **LinkedIn**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func linkPublisher(id: String,
                       accessToken: String,
                       isMobileSDK: Bool,
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(id: id,
                      accessToken: accessToken,
                      isMobileSDK: isMobileSDK,
                      options: options,
                      completion: promise)
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func linkPublisher(authData: [String: String],
                       options: API.Options = []) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
            self.link(authData: authData,
                      options: options,
                      completion: promise)
        }
    }
}

#endif
