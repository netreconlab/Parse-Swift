//
//  ParseOTP.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/12/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

/**
 Provides utility functions for working with OTP User Authentication and `ParseUser`'s.
 Be sure your Parse Server is configured for [sign in with OTP](https://docs.parseplatform.org/parse-server/guide/#otp-authdata).
 For information on acquiring OTP sign-in credentials to use with `ParseOTP`, refer to [OTP's Documentation](https://developers.otp.com/identity/protocols/oauth2).
 */
public struct ParseOTP<AuthenticatedUser: ParseUser>: ParseAuthentication {

    /// Adapter status.
    enum Status: String, Codable {
        case enabled, disabled
    }

    /// Authentication keys required for OTP authentication.
    enum AuthenticationKeys: String, Codable {
        case secret
        case token
        case oldToken = "old"
        case mobile
        case status

        /// Properly makes an authData dictionary with the required keys.
        /// - parameter token: Required token for the user.
        /// - parameter secret: Optional secret for OTP.
        /// - parameter old: Optional old token for OTP.
        /// - parameter mobile: Optional mobile number for OTP.
        /// - returns: authData dictionary.
        func makeDictionary(
            secret: String? = nil,
            token: String? = nil,
            oldToken: String? = nil,
            mobile: String? = nil
        ) -> [String: String] {

            var returnDictionary = [String: String]()

            if let secret = secret {
                returnDictionary[AuthenticationKeys.secret.rawValue] = secret
            }

            if let token = token {
                returnDictionary[AuthenticationKeys.token.rawValue] = token
            }

            if let oldToken = oldToken {
                returnDictionary[AuthenticationKeys.oldToken.rawValue] = oldToken
            }

            if let mobile = mobile {
                returnDictionary[AuthenticationKeys.mobile.rawValue] = mobile
            }

            return returnDictionary
        }

        /// Verifies all mandatory keys are in authData.
        /// - parameter authData: Dictionary containing key/values.
        /// - returns: **true** if all the mandatory keys are present, **false** otherwise.
        func verifyMandatoryKeys(authData: [String: String]) -> Bool {
            authData[AuthenticationKeys.token.rawValue] != nil
            || authData[AuthenticationKeys.mobile.rawValue] != nil
        }
    }

    public static var __type: String { // swiftlint:disable:this identifier_name
        "mfa"
    }

    public init() {}
}

// MARK: Login
public extension ParseOTP {

    /**
     Login a `ParseUser` *asynchronously* using OTP authentication for login.
     - parameter secret: Optional **secret** from **OTP**.
     - parameter token: The `token` from **OTP**.
     - parameter oldToken: Optional **old token** from **OTP**.
     - parameter mobile: Optional **mobile** number from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    internal func login(
        otpAuthData: [String: String],
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        login(
            authData: otpAuthData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    /**
     Login a `ParseUser` *asynchronously* using TOTP authentication for login.
     - parameter mobile: The **token** from **OTP**.
     - parameter oldToken: Optional **old token** from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func validate(
        secret: String,
        token: String,
        oldToken: String? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        let otpAuthData = AuthenticationKeys
            .token
            .makeDictionary(
                secret: secret,
                token: token,
                oldToken: oldToken
            )
        login(
            otpAuthData: otpAuthData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    /**
     Validate a `ParseUser`  *asynchronously* using SMS OTP authentication for login.
     - parameter mobile: The **token** from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func validate(
        token: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        let otpAuthData = AuthenticationKeys
            .token
            .makeDictionary(
                token: token
            )
        login(
            otpAuthData: otpAuthData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    /**
     Login a `ParseUser` *asynchronously* using OTP authentication for login.
     - parameter mobile: The **mobile** number from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(
        mobile: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        let otpAuthData = AuthenticationKeys
            .token
            .makeDictionary(
                mobile: mobile
            )
        login(
            otpAuthData: otpAuthData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    func login(
        authData: [String: String],
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        guard AuthenticationKeys.token.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(
                    .failure(
                        .init(
                            code: .otherCause,
                            message: "Should have \"authData\" in consisting of keys \"id\", \"idToken\" or \"accessToken\"."
                        )
                    )
                )
            }
            return
        }
        AuthenticatedUser.login(
            Self.__type,
            authData: authData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }
}

// MARK: Link
public extension ParseOTP {

    /**
     Link the *current* `ParseUser` *asynchronously* using OTP authentication for login.
     - parameter id: The **id** from **OTP**.
     - parameter idToken: Optional **id_token** from **OTP**.
     - parameter accessToken: Optional **access_token** from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(
        id: String,
        idToken: String? = nil,
        accessToken: String? = nil,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        let otpAuthData = AuthenticationKeys
            .id
            .makeDictionary(
                id: id,
                idToken: idToken,
                accessToken: accessToken
            )
        link(
            authData: otpAuthData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    func link(
        authData: [String: String],
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        guard AuthenticationKeys.id.verifyMandatoryKeys(authData: authData) else {
            callbackQueue.async {
                completion(
                    .failure(
                        .init(
                            code: .otherCause,
                            message: "Should have \"authData\" in consisting of keys \"id\", \"idToken\" or \"accessToken\"."
                        )
                    )
                )
            }
            return
        }
        AuthenticatedUser.link(Self.__type,
                               authData: authData,
                               options: options,
                               callbackQueue: callbackQueue,
                               completion: completion)
    }
}

// MARK: 3rd Party Authentication - ParseOTP
public extension ParseUser {

    /// A otp `ParseUser`.
    static var otp: ParseOTP<Self> {
        ParseOTP<Self>()
    }

    /// An otp `ParseUser`.
    var otp: ParseOTP<Self> {
        Self.otp
    }
}
