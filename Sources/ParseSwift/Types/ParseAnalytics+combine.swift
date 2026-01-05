//
//  ParseAnalytics+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/20/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

#if os(iOS)
import UIKit
#endif

public extension ParseAnalytics {

    // MARK: Combine

    #if os(iOS)

    /**
     Tracks *asynchronously* this application being launched. If this happened as the result of the
     user opening a push notification, this method sends along information to
     correlate this open with that push. Publishes when complete.
     
     - parameter launchOptions: The dictionary indicating the reason the application was
     launched, if any. This value can be found as a parameter to various
     `UIApplicationDelegate` methods, and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func trackAppOpenedPublisher(
		launchOptions: [UIApplication.LaunchOptionsKey: Any & Sendable],
		at date: Date? = nil,
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            Self.trackAppOpened(
				launchOptions: launchOptions,
				at: date,
				options: options
			) { result in
				switch result {
				case .success:
					promise(.success(()))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    #endif

    /**
     Tracks *asynchronously* this application being launched. If this happened as the result of the
     user opening a push notification, this method sends along information to
     correlate this open with that push. Publishes when complete.
     
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func trackAppOpenedPublisher(
		dimensions: [String: String]? = nil,
		at date: Date? = nil,
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            Self.trackAppOpened(
				dimensions: dimensions,
				at: date,
				options: options
			) { result in
				switch result {
				case .success(let pushedString):
					promise(.success(pushedString))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event. Publishes when complete.
  
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func trackPublisher(
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.track(
				options: options
			) { result in
				switch result {
				case .success(let pushedString):
					promise(.success(pushedString))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Tracks *asynchronously* the occurrence of a custom event with additional dimensions.
     Publishes when complete.
  
     - parameter dimensions: The dictionary of information by which to segment this
     event and can be empty or `nil`.
     - parameter at: Explicitly set the time associated with a given event. If not provided the
     server time will be used.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: This method makes a copy of the current `ParseAnalytics` and then mutates
     it. You will not have access to the mutated analytic after calling this method.
    */
    func trackPublisher(
		dimensions: [String: String]?,
		at date: Date? = nil,
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
            var analytic = self
			nonisolated(unsafe) let promise = promise
            analytic.track(
				dimensions: dimensions,
				at: date,
				options: options
			) { result in
				switch result {
				case .success:
					promise(.success(()))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

#endif
