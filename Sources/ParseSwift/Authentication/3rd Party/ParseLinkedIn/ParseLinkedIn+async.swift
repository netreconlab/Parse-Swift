//
//  ParseLinkedIn+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension ParseLinkedIn {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     - parameter id: The **id** from **LinkedIn**.
     - parameter accessToken: Required **access_token** from **LinkedIn**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(id: String,
               accessToken: String,
               isMobileSDK: Bool,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       accessToken: accessToken,
                       isMobileSDK: isMobileSDK,
                       options: options,
                       completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     - parameter authData: Dictionary containing key/values.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(authData: [String: String],
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(authData: authData,
                       options: options,
                       completion: { continuation.resume(with: $0) })
        }
    }
}

public extension ParseLinkedIn {

    /**
     Link the *current* `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     - parameter id: The **id** from **LinkedIn**.
     - parameter accessToken: Required **access_token** from **LinkedIn**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(id: String,
              accessToken: String,
              isMobileSDK: Bool,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      accessToken: accessToken,
                      isMobileSDK: isMobileSDK,
                      options: options,
                      completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using LinkedIn authentication for graph API login.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(authData: [String: String],
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(authData: authData,
                      options: options,
                      completion: { continuation.resume(with: $0) })
        }
    }
}
