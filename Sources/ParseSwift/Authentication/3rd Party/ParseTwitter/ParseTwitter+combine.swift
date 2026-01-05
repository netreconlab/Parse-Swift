//
//  ParseTwitter+combine.swift
//  ParseTwitter+combine
//
//  Created by Corey Baker on 8/7/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseTwitter {
    // MARK: Combine

    /**
     Login a `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The **id** from **Twitter**.
     - parameter screenName: The `user screenName` from **Twitter**.
     - parameter consumerKey: The `consumerKey` from **Twitter**.
     - parameter consumerSecret: The `consumerSecret` from **Twitter**.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(
		userId: String,
		screenName: String? = nil,
		consumerKey: String,
		consumerSecret: String,
		authToken: String,
		authTokenSecret: String,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.login(
				userId: userId,
				screenName: screenName,
				consumerKey: consumerKey,
				consumerSecret: consumerSecret,
				authToken: authToken,
				authTokenSecret: authTokenSecret,
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
     Login a `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
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

public extension ParseTwitter {

    /**
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
     - parameter user: The `user` from **Twitter**.
     - parameter screenName: The `user screenName` from **Twitter**.
     - parameter consumerKey: The `consumerKey` from **Twitter**.
     - parameter consumerSecret: The `consumerSecret` from **Twitter**.
     - parameter authToken: The Twitter `authToken` obtained from Twitter.
     - parameter authTokenSecret: The Twitter `authSecretToken` obtained from Twitter.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func linkPublisher(
		userId: String,
		screenName: String? = nil,
		consumerKey: String,
		consumerSecret: String,
		authToken: String,
		authTokenSecret: String,
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.link(
				userId: userId,
				screenName: screenName,
				consumerKey: consumerKey,
				consumerSecret: consumerSecret,
				authToken: authToken,
				authTokenSecret: authTokenSecret,
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
     Link the *current* `ParseUser` *asynchronously* using Twitter authentication. Publishes when complete.
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
