//
//  ParseGoogle+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension ParseGoogle {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using Google authentication for graph API login.
     - parameter id: The **id** from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(id: String,
               idToken: String? = nil,
               accessToken: String? = nil,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       idToken: idToken,
                       accessToken: accessToken,
                       options: options,
                       completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using Google authentication for graph API login.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
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

public extension ParseGoogle {

    /**
     Link the *current* `ParseUser` *asynchronously* using Google authentication for graph API login.
     - parameter id: The **id** from **Google**.
     - parameter idToken: Optional **id_token** from **Google**.
     - parameter accessToken: Optional **access_token** from **Google**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(id: String,
              idToken: String? = nil,
              accessToken: String? = nil,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      idToken: idToken,
                      accessToken: accessToken,
                      options: options,
                      completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using Google authentication for graph API login.
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
