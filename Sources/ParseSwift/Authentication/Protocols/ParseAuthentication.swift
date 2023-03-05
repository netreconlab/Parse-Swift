//
//  ParseAuthentication.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/14/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

// swiftlint:disable line_length

/**
 Objects that conform to the `ParseAuthentication` protocol provide
 convenience implementations for using 3rd party authentication methods.
 The authentication methods supported by the Parse Server can be found
 [here](https://docs.parseplatform.org/parse-server/guide/#oauth-and-3rd-party-authentication).
 */
public protocol ParseAuthentication: Codable {
    associatedtype AuthenticatedUser: ParseUser

    /// The type of authentication.
    static var __type: String { get } // swiftlint:disable:this identifier_name

    /// Returns **true** if the *current* user is linked to the respective authentication type.
    func isLinked() async -> Bool

    /// The default initializer for this authentication type.
    init()

    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func login(authData: [String: String],
               options: API.Options,
               callbackQueue: DispatchQueue,
               completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Link the *current* `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func link(authData: [String: String],
              options: API.Options,
              callbackQueue: DispatchQueue,
              completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Whether the `ParseUser` is logged in with the respective authentication type.
     - parameter user: The `ParseUser` to check authentication type. The user must be logged in on this device.
     - returns: **true** if the `ParseUser` is logged in via the repective
     authentication type. **false** if the user is not.
     */
    static func isLinked(with user: AuthenticatedUser) -> Bool

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type.
     - parameter user: The `ParseUser` to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    func unlink(_ user: AuthenticatedUser,
                options: API.Options,
                callbackQueue: DispatchQueue,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Unlink the *current* `ParseUser` *asynchronously* from the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<AuthenticatedUser, ParseError>)`.
     */
    func unlink(options: API.Options,
                callbackQueue: DispatchQueue,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void)

    /**
     Strips the *current* user of a respective authentication type.
     */
    func strip() async throws -> AuthenticatedUser

    /**
     Strips the `ParseUser`of a respective authentication type.
     - parameter user: The `ParseUser` to strip. The user must be logged in on this device.
     - returns: The user whose autentication type was stripped. This modified user has not been saved.
     */
    func strip(_ user: AuthenticatedUser) -> AuthenticatedUser

    #if canImport(Combine)
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using the respective authentication type. Publishes when complete.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func loginPublisher(authData: [String: String],
                        options: API.Options) -> Future<AuthenticatedUser, ParseError>

    /**
     Link the *current* `ParseUser` *asynchronously* using the respective authentication type. Publishes when complete.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     */
    func linkPublisher(authData: [String: String],
                       options: API.Options) -> Future<AuthenticatedUser, ParseError>

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type. Publishes when complete.
     - parameter user: The `ParseUser` to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     */
    func unlinkPublisher(_ user: AuthenticatedUser,
                         options: API.Options) -> Future<AuthenticatedUser, ParseError>

    /**
     Unlink the *current* `ParseUser` *asynchronously* from the respective authentication type. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func unlinkPublisher(options: API.Options) -> Future<AuthenticatedUser, ParseError>
    #endif

    // MARK: Async/Await

    /**
     Link the *current* `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter returns: An instance of the linked `AuthenticatedUser`.
     */
    func link(authData: [String: String],
              options: API.Options) async throws -> AuthenticatedUser

    /**
     Unlink the `ParseUser` *asynchronously* from the respective authentication type.
     - parameter user: The `ParseUser` to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter returns: An instance of the unlinked `AuthenticatedUser`.
     */
    func unlink(_ user: AuthenticatedUser,
                options: API.Options) async throws -> AuthenticatedUser

    /**
     Unlink the *current* `ParseUser` *asynchronously* from the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter returns: An instance of the unlinked `AuthenticatedUser`.
     */
    func unlink(options: API.Options) async throws -> AuthenticatedUser
}

// MARK: Convenience Implementations
public extension ParseAuthentication {

    var __type: String { // swiftlint:disable:this identifier_name
        Self.__type
    }

    func isLinked() async -> Bool {
        guard let current = try? await AuthenticatedUser.current() else {
            return false
        }
        return current.isLinked(with: __type)
    }

    static func isLinked(with user: AuthenticatedUser) -> Bool {
        user.isLinked(with: __type)
    }

    func unlink(_ user: AuthenticatedUser,
                options: API.Options = [],
                callbackQueue: DispatchQueue = .main,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        user.unlink(__type, options: options, callbackQueue: callbackQueue, completion: completion)
    }

    func unlink(options: API.Options = [],
                callbackQueue: DispatchQueue = .main,
                completion: @escaping (Result<AuthenticatedUser, ParseError>) -> Void) {
        Task {
            guard let current = try? await AuthenticatedUser.current() else {
                let error = ParseError(code: .invalidLinkedSession, message: "No current ParseUser.")
                callbackQueue.async {
                    completion(.failure(error))
                }
                return
            }
            unlink(current, options: options, callbackQueue: callbackQueue, completion: completion)
        }
    }

    @discardableResult
    func strip() async throws -> AuthenticatedUser {
        let user = try await AuthenticatedUser.current()
        return strip(user)
    }

    func strip(_ user: AuthenticatedUser) -> AuthenticatedUser {
        if Self.isLinked(with: user) {
            var user = user
            user.authData?.updateValue(nil, forKey: __type)
            return user
        }
        return user
    }
}

public extension ParseUser {

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Returns an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     See [supported 3rd party authentications](https://docs.parseplatform.org/parse-server/guide/#supported-3rd-party-authentications) for more information.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
    */
    static func login(_ type: String,
                      authData: [String: String],
                      options: API.Options,
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Self, ParseError>) -> Void) {
        Task {
            do {
                _ = try await Self.current()
                Self.link(type,
                          authData: authData,
                          options: options,
                          callbackQueue: callbackQueue,
                          completion: completion)
            } catch {
                let body = SignupLoginBody(authData: [type: authData])
                do {
                    try await signupCommand(body: body)
                        .execute(options: options,
                                 callbackQueue: callbackQueue,
                                 completion: completion)
                } catch {
                    let defaultError = ParseError(code: .otherCause,
                                                  message: error.localizedDescription)
                    let parseError = error as? ParseError ?? defaultError
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }
    }

    // MARK: 3rd Party Authentication - Link
    /**
     Whether the `ParseUser` is logged in with the respective authentication string type.
     - parameter type: The authentication type to check. The user must be logged in on this device.
     - returns: **true** if the `ParseUser` is logged in via the repective
     authentication type. **false** if the user is not.
     */
    func isLinked(with type: String) -> Bool {
        guard let authData = self.authData?[type] else {
            return false
        }
        return authData != nil
    }

    /**
     Strips the *current* user of a respective authentication type.
     - parameter type: The authentication type to strip.
     - returns: The user whose autentication type was stripped.
     */
    func strip(_ type: String) -> Self {
        var user = self
        user.authData?.updateValue(nil, forKey: type)
        return user
    }

    /**
     Unlink the authentication type *asynchronously*.
     - parameter type: The type to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     */
    func unlink(_ type: String,
                options: API.Options = [],
                callbackQueue: DispatchQueue = .main,
                completion: @escaping (Result<Self, ParseError>) -> Void) {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        let immutableOptions = options
        if self.isLinked(with: type) {
            guard let authData = self.strip(type).authData else {
                let error = ParseError(code: .otherCause, message: "Missing authData.")
                callbackQueue.async {
                    completion(.failure(error))
                }
                return
            }
            let body = SignupLoginBody(authData: authData)
            Task {
                do {
                    try await self.linkCommand(body: body)
                        .execute(options: immutableOptions,
                                 callbackQueue: callbackQueue,
                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(code: .otherCause, message: error.localizedDescription)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        } else {
            callbackQueue.async {
                completion(.success(self))
            }
        }
    }

    /**
     Makes an *asynchronous* request to link a user with specified credentials. The user should already be logged in.
     Returns an instance of the successfully linked `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     See [supported 3rd party authentications](https://docs.parseplatform.org/parse-server/guide/#supported-3rd-party-authentications) for more information.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func link(_ type: String,
                     authData: [String: String],
                     options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<Self, ParseError>) -> Void) {
        Task {
            var options = options
            options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
            let body = SignupLoginBody(authData: [type: authData])
            do {
                try await Self.current().linkCommand(body: body)
                    .execute(options: options,
                             callbackQueue: callbackQueue,
                             completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(code: .otherCause, message: error.localizedDescription)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    internal func linkCommand() async throws -> API.Command<Self, Self> {
        var mutableSelf = self.anonymous.strip(self)
        if let current = try? await Self.current() {
            guard current.hasSameObjectId(as: mutableSelf) else {
                let error = ParseError(code: .otherCause,
                                       message: "Cannot signup a user with a different objectId than the current user")
                throw error
            }
        }
        return API.Command<Self, Self>(method: .PUT,
                                       path: endpoint,
                                       body: mutableSelf) { (data) -> Self in
            let user = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: data)
            mutableSelf.updatedAt = user.updatedAt
            if let sessionToken = user.sessionToken {
                await Self.setCurrentContainer(.init(currentUser: mutableSelf,
                                                     sessionToken: sessionToken))
            } else {
                try await Self.setCurrent(mutableSelf)
            }
            return mutableSelf
        }
    }

    internal func linkCommand(body: SignupLoginBody) async throws -> API.Command<SignupLoginBody, Self> {
        let currentStrippedUser = try await self.anonymous.strip()
        var body = body
        if var currentAuthData = currentStrippedUser.authData {
            if let bodyAuthData = body.authData {
                bodyAuthData.forEach { (key, value) in
                    currentAuthData[key] = value
                }
            }
            body.authData = currentAuthData
        }

        return API.Command<SignupLoginBody, Self>(method: .PUT,
                                                  path: endpoint,
                                                  body: body) { (data) -> Self in
            let user = try ParseCoding.jsonDecoder().decode(UpdateSessionTokenResponse.self, from: data)
            var currentUser = currentStrippedUser
            currentUser.updatedAt = user.updatedAt
            currentUser.authData = body.authData
            if let sessionToken = user.sessionToken {
                await Self.setCurrentContainer(.init(currentUser: currentUser,
                                                     sessionToken: sessionToken))
            } else {
                try await Self.setCurrent(currentUser)
            }
            return currentUser
        }
    }
}
