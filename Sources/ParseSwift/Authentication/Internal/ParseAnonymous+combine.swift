//
//  ParseAnonymous+combine.swift
//  ParseAnonymous+combine
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

public extension ParseAnonymous {

    // MARK: Login - Combine
    /**
	 Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func loginPublisher(
		options: API.Options = []
	) -> Future<AuthenticatedUser, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.login(options: options) { result in
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
	Login a `ParseUser` *asynchronously* using the respective authentication type.
     - parameter authData: The authData for the respective authentication type. This will be ignored.
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

public extension ParseAnonymous {

	/**
	 Link a `ParseUser` *asynchronously* using the respective authentication type.
	 - parameter authData: The authData for the respective authentication type. This will be ignored.
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
