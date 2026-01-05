//
//  ParseFacebook+combine.swift
//  ParseFacebook+combine
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Combine

public extension ParseFacebook {
    // MARK: Combine
    /**
     Login a `ParseUser` *asynchronously* using Facebook authentication for limited login. Publishes when complete.
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter authenticationToken: The `authenticationToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(
		userId: String,
		authenticationToken: String,
		expiresIn: Int? = nil,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.login(
				userId: userId,
				authenticationToken: authenticationToken,
				expiresIn: expiresIn,
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
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login. Publishes when complete.
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter accessToken: The `accessToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(
		userId: String,
		accessToken: String,
		expiresIn: Int? = nil,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.login(
				userId: userId,
				accessToken: accessToken,
				expiresIn: expiresIn,
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
     Login a `ParseUser` *asynchronously* using Facebook authentication for graph API login. Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(
		authData: [String: String],
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.login(
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

public extension ParseFacebook {
    /**
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for limited login.
     Publishes when complete.
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter authenticationToken: The `authenticationToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(
		userId: String,
		authenticationToken: String,
		expiresIn: Int? = nil,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.link(
				userId: userId,
				authenticationToken: authenticationToken,
				expiresIn: expiresIn,
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
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     Publishes when complete.
     - parameter userId: The **id** from **FacebookSDK**.
     - parameter accessToken: The `accessToken` from **FacebookSDK**.
     - parameter expiresIn: Optional expiration in seconds for Facebook login.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(
		userId: String,
		accessToken: String,
		expiresIn: Int? = nil,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.link(
				userId: userId,
				accessToken: accessToken,
				expiresIn: expiresIn,
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
     Link the *current* `ParseUser` *asynchronously* using Facebook authentication for graph API login.
     Publishes when complete.
     - parameter authData: Dictionary containing key/values.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(
		authData: [String: String],
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.link(
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
