//
//  ParseApple+combine.swift
//  ParseApple+combine
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseApple {
    // MARK: Combine

    /**
     Login a `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The **identityToken** from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(
		user: String,
		identityToken: Data,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.login(
				user: user,
				identityToken: identityToken,
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
     Login a `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter authData: Dictionary containing key/values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
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

public extension ParseApple {

    /**
     Link the *current* `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
     - parameter user: The `user` from `ASAuthorizationAppleIDCredential`.
     - parameter identityToken: The **identityToken** from `ASAuthorizationAppleIDCredential`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(
		user: String,
		identityToken: Data,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.link(
				user: user,
				identityToken: identityToken,
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
     Link the *current* `ParseUser` *asynchronously* using Apple authentication. Publishes when complete.
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
