//
//  ParseLDAP+async.swift
//  ParseLDAP+async
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension ParseLDAP {
    // MARK: Async/Await
    /**
     Login a `ParseUser` *asynchronously* using LDAP authentication.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(id: String,
               password: String,
               options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(id: id,
                       password: password,
                       options: options,
                       completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using LDAP authentication.
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

public extension ParseLDAP {
    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication.
     - parameter id: The id of the `user`.
     - parameter password: The password of the user.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(id: String,
              password: String,
              options: API.Options = []) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(id: id,
                      password: password,
                      options: options,
                      completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using LDAP authentication.
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
