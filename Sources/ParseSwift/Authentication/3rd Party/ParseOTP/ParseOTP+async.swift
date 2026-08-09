//
//  ParseOTP+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/12/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

public extension ParseOTP {
    // MARK: Async/Await

    /**
     Login a `ParseUser` *asynchronously* using OTP authentication for login.
     - parameter id: The **id** from **OTP**.
     - parameter idToken: Optional **id_token** from **OTP**.
     - parameter accessToken: Optional **access_token** from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(
        id: String,
        idToken: String? = nil,
        accessToken: String? = nil,
        options: API.Options = []
    ) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(
                id: id,
                idToken: idToken,
                accessToken: accessToken,
                options: options,
                completion: continuation.resume
            )
        }
    }

    /**
     Login a `ParseUser` *asynchronously* using OTP authentication for login.
     - parameter authData: Dictionary containing key/values.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func login(
        authData: [String: String],
        options: API.Options = []
    ) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.login(
                authData: authData,
                options: options,
                completion: continuation.resume
            )
        }
    }
}

public extension ParseOTP {

    /**
     Link the *current* `ParseUser` *asynchronously* using OTP authentication for login.
     - parameter id: The **id** from **OTP**.
     - parameter idToken: Optional **id_token** from **OTP**.
     - parameter accessToken: Optional **access_token** from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(
        id: String,
        idToken: String? = nil,
        accessToken: String? = nil,
        options: API.Options = []
    ) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(
                id: id,
                idToken: idToken,
                accessToken: accessToken,
                options: options,
                completion: continuation.resume
            )
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using OTP authentication for login.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: An instance of the logged in `ParseUser`.
     - throws: An error of type `ParseError`.
     */
    func link(
        authData: [String: String],
        options: API.Options = []
    ) async throws -> AuthenticatedUser {
        try await withCheckedThrowingContinuation { continuation in
            self.link(
                authData: authData,
                options: options,
                completion: continuation.resume
            )
        }
    }
}
