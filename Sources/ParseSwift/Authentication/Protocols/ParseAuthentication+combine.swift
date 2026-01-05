//
//  ParseAuthentication+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/30/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseAuthentication {

    // MARK: Convenience Implementations - Combine

    func unlinkPublisher(
		_ user: AuthenticatedUser,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        user.unlinkPublisher(__type, options: options)
    }

    func unlinkPublisher(
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.unlink(options: options) { result in
				switch result {
				case .success(let user):
					promise(.success(user))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

public extension ParseUser {

    // MARK: 3rd Party Authentication - Login Combine

    /**
     Makes an *asynchronous* request to log in a user with specified credentials.
     Publishes an instance of the successfully logged in `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    static func loginPublisher(
		_ type: String,
		authData: [String: String],
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            Self.login(
				type,
				authData: authData,
				options: options
			) { result in
				switch result {
				case .success(let user):
					promise(.success(user))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Unlink the authentication type *asynchronously*. Publishes when complete.
     - parameter type: The type to unlink. The user must be logged in on this device.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func unlinkPublisher(
		_ type: String,
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.unlink(
				type,
				options: options
			) { result in
				switch result {
				case .success(let user):
					promise(.success(user))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Makes an *asynchronous* request to link a user with specified credentials. The user should already be logged in.
     Publishes an instance of the successfully linked `ParseUser`.

     This also caches the user locally so that calls to *current* will use the latest logged in user.
     - parameter type: The authentication type.
     - parameter authData: The data that represents the authentication.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func linkPublisher(
		_ type: String,
		authData: [String: String],
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            Self.link(
				type,
				authData: authData,
				options: options
			) { result in
				switch result {
				case .success(let user):
					promise(.success(user))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

#endif
