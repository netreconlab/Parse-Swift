//
//  Queryable.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//
import Foundation

public protocol Queryable {
    associatedtype ResultType

    func find(options: API.Options) async throws -> [ResultType]
    func first(options: API.Options) async throws -> ResultType
    func count(options: API.Options) async throws -> Int
    func find(options: API.Options, callbackQueue: DispatchQueue,
              completion: @escaping @Sendable (Result<[ResultType], ParseError>) -> Void)
    func first(options: API.Options, callbackQueue: DispatchQueue,
               completion: @escaping @Sendable (Result<ResultType, ParseError>) -> Void)
    func count(options: API.Options, callbackQueue: DispatchQueue,
               completion: @escaping @Sendable (Result<Int, ParseError>) -> Void)
}

extension Queryable {

    /**
      Finds objects *asynchronously* and returns a completion block with the results.

      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ResultType], ParseError>)`
    */
    func find(
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<[ResultType], ParseError>) -> Void
	) {
        find(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    /**
      Gets an object *asynchronously* and returns a completion block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.

      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `^(ParseObject *object, ParseError *error)`.
      `result` will be `nil` if `error` is set OR no object was found matching the query.
      `error` will be `nil` if `result` is set OR if the query succeeded, but found no results.
    */
    func first(
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<ResultType, ParseError>) -> Void
	) {
        first(options: [], callbackQueue: callbackQueue, completion: completion)
    }

    /**
      Counts objects *asynchronously* and returns a completion block with the count.

      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `^(int count, ParseError *error)`
    */
    func count(
		callbackQueue: DispatchQueue = .main,
		completion: @escaping @Sendable (Result<Int, ParseError>) -> Void
	) {
        count(options: [], callbackQueue: callbackQueue, completion: completion)
    }
}
