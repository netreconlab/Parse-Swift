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

    func login(
        authData: [String: String],
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        callbackQueue.async {
            completion(
                .failure(
                    .init(
                        code: .otherCause,
                        message: "Login is not supported. Please use \"link(...)\"."
                    )
                )
            )
        }
    }
}

// MARK: Link
public extension ParseOTP {

    /**
     Verify and/or reauthenticate a `ParseUser` token  *asynchronously* using OTP enrollment.
     - parameter token: The **token** from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func verify(
        token: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        Task {
            do {
                let currentUser = try await AuthenticatedUser.current()
                guard let potentialOTPAuthData = currentUser.authData?[Self.__type],
                    var otpAuthData = potentialOTPAuthData else {
                    let error = ParseError(
                        code: .otherCause,
                        message: "Logged in user is missing authData, did you link MFA before attempting to call \"verify()\"."
                    )
                    completion(.failure(error))
                    return
                }
                if let oldToken = otpAuthData[AuthenticationKeys.token.rawValue] {
                    otpAuthData[AuthenticationKeys.oldToken.rawValue] = oldToken
                }
                otpAuthData[AuthenticationKeys.token.rawValue] = token
                link(
                    authData: otpAuthData,
                    options: options,
                    callbackQueue: callbackQueue,
                    completion: completion
                )
            } catch {
                let defaultError = ParseError(
                    code: .otherCause,
                    message: "Could not retrieve logged in user from Keychain",
                    swift: error
                )
                let parseError = error as? ParseError ?? defaultError
                completion(.failure(parseError))
            }
        }
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using OTP enrollment.
     - parameter secret: The **secret** from **OTP**.
     - parameter token: The **token** from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(
        secret: String,
        token: String,
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void
    ) {
        let otpAuthData = AuthenticationKeys
            .token
            .makeDictionary(
                secret: secret,
                token: token
            )
        link(
            authData: otpAuthData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
    }

    /**
     Link the *current* `ParseUser` *asynchronously* using SMS OTP enrollment.
     - parameter mobile: The **mobile** number from **OTP**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(
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
        AuthenticatedUser.link(
            Self.__type,
            authData: authData,
            options: options,
            callbackQueue: callbackQueue,
            completion: completion
        )
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
