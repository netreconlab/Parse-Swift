//
//  Query.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-23.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation

// MARK: Query
/**
  The `Query` class defines a query that is used to query for `ParseObject`s.
*/
public struct Query<T>: ParseTypeable where T: ParseObject {
    // interpolate as GET
    private let method: String = "GET"
    internal var limit: Int = 100
    internal var skip: Int = 0
    internal var keys: Set<String>?
    internal var include: Set<String>?
    internal var order: [Order]?
    internal var isCount: Bool?
    internal var explain: Bool?
    internal var hint: AnyCodable?
    internal var `where` = QueryWhere()
    internal var excludeKeys: Set<String>?
    internal var readPreference: String?
    internal var includeReadPreference: String?
    internal var subqueryReadPreference: String?
    internal var distinct: String?
    internal var pipeline: [[String: AnyCodable]]?
    internal var fields: Set<String>?
    internal var watch: Set<String>?
    var endpoint: API.Endpoint {
        .objects(className: T.className)
    }

    /// The className of the `ParseObject` to query.
    public static var className: String {
        T.className
    }

    /// The className of the `ParseObject` to query.
    public var className: String {
        Self.className
    }

    struct AggregateBody<V>: Codable where V: ParseObject {
        let pipeline: [[String: AnyCodable]]?
        let hint: AnyCodable?
        let explain: Bool?
        let includeReadPreference: String?

        init(query: Query<V>) {
            pipeline = query.pipeline
            hint = query.hint
            explain = query.explain
            includeReadPreference = query.includeReadPreference
        }

        func getQueryParameters() throws -> [String: String] {
            var dictionary = [String: String]()
            dictionary["explain"] = try encodeAsString(\.explain)
            dictionary["hint"] = try encodeAsString(\.hint)
            dictionary["includeReadPreference"] = try encodeAsString(\.includeReadPreference)
            dictionary["pipeline"] = try encodeAsString(\.pipeline)
            return dictionary
        }

        func encodeAsString<W>(_ key: KeyPath<Self, W?>) throws -> String? where W: Encodable {
            guard let value = self[keyPath: key] else {
                return nil
            }
            let encoded = try ParseCoding.jsonEncoder().encode(value)
            return String(decoding: encoded, as: UTF8.self)
        }
    }

    struct DistinctBody<V>: Codable where V: ParseObject {
        let hint: AnyCodable?
        let explain: Bool?
        let includeReadPreference: String?
        let distinct: String?

        init(query: Query<V>) {
            distinct = query.distinct
            hint = query.hint
            explain = query.explain
            includeReadPreference = query.includeReadPreference
        }

        func getQueryParameters() throws -> [String: String] {
            var dictionary = [String: String]()
            dictionary["explain"] = try encodeAsString(\.explain)
            dictionary["hint"] = try encodeAsString(\.hint)
            dictionary["includeReadPreference"] = try encodeAsString(\.includeReadPreference)
            dictionary["distinct"] = try encodeAsString(\.distinct)
            return dictionary
        }

        func encodeAsString<W>(_ key: KeyPath<Self, W?>) throws -> String? where W: Encodable {
            guard let value = self[keyPath: key] else {
                return nil
            }
            let encoded = try ParseCoding.jsonEncoder().encode(value)
            return String(decoding: encoded, as: UTF8.self)
        }
    }

    enum CodingKeys: String, CodingKey {
        case `where`
        case method = "_method"
        case limit
        case skip
        case include
        case isCount = "count"
        case keys
        case order
        case explain
        case hint
        case excludeKeys
        case readPreference
        case includeReadPreference
        case subqueryReadPreference
        case distinct
        case pipeline
    }

    /**
      An enum that determines the order to sort the results based on a given key.

      - parameter key: The key to order by.
    */
    public enum Order: Codable, Equatable, Sendable {
        /// Sort in ascending order based on `key`.
        case ascending(String)
        /// Sort in descending order based on `key`.
        case descending(String)

        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .ascending(let value):
                try container.encode(value)
            case .descending(let value):
                try container.encode("-\(value)")
            }
        }

        public init(from decoder: Decoder) throws {
            let values = try decoder.singleValueContainer()
            var value = try values.decode(String.self)
            if value.hasPrefix("-") {
                value.removeFirst()
                self = .descending(value)
            } else {
                self = .ascending(value)
            }
        }
    }

    /**
      Create an instance with a variadic amount constraints.
     - parameter constraints: A variadic amount of zero or more `QueryConstraint`'s.
     */
    public init(_ constraints: QueryConstraint...) {
        self.init(constraints)
    }

    /**
      Create an instance with an array of constraints.
     - parameter constraints: An array of `QueryConstraint`'s.
     */
    public init(_ constraints: [QueryConstraint]) {
        constraints.forEach({ self.where.add($0) })
    }

    /**
      Add any amount of variadic constraints.
     - parameter constraints: A variadic amount of zero or more `QueryConstraint`'s.
     - returns: The current instance of query for easy chaining.
     */
    public func `where`(_ constraints: QueryConstraint...) -> Query<T> {
        self.`where`(constraints)
    }

    /**
      Add an array of variadic constraints.
     - parameter constraints: An array of zero or more `QueryConstraint`'s.
     - returns: The current instance of query for easy chaining.
     */
    public func `where`(_ constraints: [QueryConstraint]) -> Query<T> {
        var mutableQuery = self
        constraints.forEach({ mutableQuery.where.add($0) })
        return mutableQuery
    }

    /**
     A limit on the number of objects to return. The default limit is `100`, with a
     maximum of 1000 results being returned at a time.

     - parameter value: `n` number of results to limit to.
     - returns: The mutated instance of query for easy chaining.
     - note: If you are calling `find` with `limit = 1`, you may find it easier to use `first` instead.
    */
    public func limit(_ value: Int) -> Query<T> {
        var mutableQuery = self
        mutableQuery.limit = value
        return mutableQuery
    }

    /**
     The number of objects to skip before returning any.
     This is useful for pagination. Default is to skip zero results.
     - parameter value: `n` number of results to skip.
     - returns: The mutated instance of query for easy chaining.
    */
    public func skip(_ value: Int) -> Query<T> {
        var mutableQuery = self
        mutableQuery.skip = value
        return mutableQuery
    }

    /**
      Adds a hint to force index selection.
      - parameter value: String or Object of index that should be used when executing query.
      - returns: The mutated instance of query for easy chaining.
    */
    public func hint<U: Encodable>(_ value: U) -> Query<T> {
        var mutableQuery = self
        mutableQuery.hint = AnyCodable(value)
        return mutableQuery
    }

    /**
      Changes the read preference that the backend will use when performing the query to the database.
      - parameter readPreference: The read preference for the main query.
      - parameter includeReadPreference: The read preference for the queries to include pointers.
      - parameter subqueryReadPreference: The read preference for the sub queries.
      - returns: The mutated instance of query for easy chaining.
    */
    public func readPreference(_ readPreference: String?,
                               includeReadPreference: String? = nil,
                               subqueryReadPreference: String? = nil) -> Query<T> {
        var mutableQuery = self
        mutableQuery.readPreference = readPreference
        mutableQuery.includeReadPreference = includeReadPreference
        mutableQuery.subqueryReadPreference = subqueryReadPreference
        return mutableQuery
    }

    /**
     Make the query include `ParseObject`s that have a reference stored at the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: A variadic list of keys to load child `ParseObject`s for.
     - returns: The mutated instance of query for easy chaining.
     */
    public func include(_ keys: String...) -> Query<T> {
        self.include(keys)
    }

    /**
     Make the query include `ParseObject`s that have a reference stored at the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: An array of keys to load child `ParseObject`s for.
     - returns: The mutated instance of query for easy chaining.
     */
    public func include(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.include != nil {
            mutableQuery.include = mutableQuery.include?.union(keys)
        } else {
            mutableQuery.include = Set(keys)
        }
        return mutableQuery
    }

    /**
     Includes all nested `ParseObject`s one level deep.
     - warning: Requires Parse Server 3.0.0+.
     - returns: The mutated instance of query for easy chaining.
     */
    public func includeAll() -> Query<T> {
        var mutableQuery = self
        if mutableQuery.include != nil {
            mutableQuery.include?.insert(ParseConstants.includeAllKey)
        } else {
            mutableQuery.include = [ParseConstants.includeAllKey]
        }
        return mutableQuery
    }

    /**
     Exclude specific keys for a `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be excluded.
     - parameter keys: A variadic list of keys include in the result.
     - returns: The mutated instance of query for easy chaining.
     - warning: Requires Parse Server 5.0.0+.
     */
    public func exclude(_ keys: String...) -> Query<T> {
        self.exclude(keys)
    }

    /**
     Exclude specific keys for a `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be excluded.
     - parameter keys: An array of keys to exclude in the result.
     - returns: The mutated instance of query for easy chaining.
     - warning: Requires Parse Server 5.0.0+.
    */
    public func exclude(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.excludeKeys != nil {
            mutableQuery.excludeKeys = mutableQuery.excludeKeys?.union(keys)
        } else {
            mutableQuery.excludeKeys = Set(keys)
        }
        return mutableQuery
    }

    /**
     Make the query restrict the fields of the returned `ParseObject`s to include only the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: A variadic list of keys to include in the result.
     - returns: The mutated instance of query for easy chaining.
     - warning: Requires Parse Server 5.0.0+.
     - note: When using the `Query` for `ParseLiveQuery`, setting `fields` will take precedence
     over `select`. If `fields` are not set, the `select` keys will be used.
     */
    public func select(_ keys: String...) -> Query<T> {
        self.select(keys)
    }

    /**
     Make the query restrict the fields of the returned `ParseObject`s to include only the provided keys.
     If this is called multiple times, then all of the keys specified in each of the calls will be included.
     - parameter keys: An array of keys to include in the result.
     - returns: The mutated instance of query for easy chaining.
     - warning: Requires Parse Server 5.0.0+.
     - note: When using the `Query` for `ParseLiveQuery`, setting `fields` will take precedence
     over `select`. If `fields` are not set, the `select` keys will be used.
     */
    public func select(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.keys != nil {
            mutableQuery.keys = mutableQuery.keys?.union(keys)
        } else {
            mutableQuery.keys = Set(keys)
        }
        return mutableQuery
    }

    /**
     Sort the results of the query based on the `Order` enum.
      - parameter keys: A variadic list of keys to order by.
      - returns: The mutated instance of query for easy chaining.
    */
    public func order(_ keys: Order...) -> Query<T> {
        self.order(keys)
    }

    /**
     Sort the results of the query based on the `Order` enum.
      - parameter keys: An array of keys to order by.
      - returns: The mutated instance of query for easy chaining.
    */
    public func order(_ keys: [Order]?) -> Query<T> {
        var mutableQuery = self
        mutableQuery.order = keys
        return mutableQuery
    }

    /**
     A variadic list of select keys to receive for a `ParseObject` whenever an update occurs for a
     `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields name, id and age.
     If you are only interested in the change of the name field, you can set `query.fields` to "name".
     In this situation, when the change of a Player `ParseObject` fulfills the subscription, only the
     name field will be sent to the clients instead of the full Player `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be received.
     - note: Setting `fields` will take precedence over `select`. If `fields` are not set, the
     `select` keys will be used.
     - note: This is only for `ParseLiveQuery`.
     - parameter keys: A variadic list of keys to receive back instead of the whole `ParseObject`.
     - returns: The mutated instance of query for easy chaining.
     */
    public func fields(_ keys: String...) -> Query<T> {
        self.fields(keys)
    }

    /**
     A list of select keys to receive for a `ParseObject` whenever an update occurs for a
     `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields name, id and age.
     If you are only interested in the change of the name field, you can set `query.fields` to "name".
     In this situation, when the change of a Player `ParseObject` fulfills the subscription, only the
     name field will be sent to the clients instead of the full Player `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be received.
     - note: Setting `fields` will take precedence over `select`. If `fields` are not set, the
     `select` keys will be used.
     - important: This is only for `ParseLiveQuery`.
     - parameter keys: An array of keys to receive back instead of the whole `ParseObject`.
     - returns: The mutated instance of query for easy chaining.
     */
    public func fields(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.fields != nil {
            mutableQuery.fields = mutableQuery.fields?.union(keys)
        } else {
            mutableQuery.fields = Set(keys)
        }
        return mutableQuery
    }

    /**
     A variadic list of keys to watch mutations on when using `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields: name, position, and age.
     If you are only interested in the change of the **name** key, you can set
     `query.watch` to **name**. In this situation, when the change of a
     Player `ParseObject` fulfills the subscription and the **name** key is updated,
     only the name field will be sent to the clients instead of the full Player `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be received.
     - important: This is only for `ParseLiveQuery`.
     - warning: Requires Parse Server 6.0.0+.
     - parameter keys: A variadic list of fields to receive back instead of the whole `ParseObject`.
     - returns: The mutated instance of query for easy chaining.
     */
    public func watch(_ keys: String...) -> Query<T> {
        self.watch(keys)
    }

    /**
     A list of keys to watch mutations on when using `ParseLiveQuery`.
     
     Suppose the `ParseObject` Player contains three fields: name, position, and age.
     If you are only interested in the change of the **name** key, you can set
     `query.watch` to **name**. In this situation, when the change of a
     Player `ParseObject` fulfills the subscription and the **name** key is updated,
     only the name field will be sent to the clients instead of the full Player `ParseObject`.
     If this is called multiple times, then all of the keys specified in each of the calls will be received.
     - important: This is only for `ParseLiveQuery`.
     - warning: Requires Parse Server 6.0.0+.
     - parameter keys: An array of keys to lisen to instead of the whole `ParseObject`.
     - returns: The mutated instance of query for easy chaining.
     */
    public func watch(_ keys: [String]) -> Query<T> {
        var mutableQuery = self
        if mutableQuery.watch != nil {
            mutableQuery.watch = mutableQuery.watch?.union(keys)
        } else {
            mutableQuery.watch = Set(keys)
        }
        return mutableQuery
    }
}

// MARK: Queryable
extension Query: Queryable {

    public typealias ResultType = T

    /**
      Finds objects *asynchronously* and returns a completion block with the results.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ResultType], ParseError>)`.
    */
    public func find(options: API.Options = [],
                     callbackQueue: DispatchQueue = .main,
                     completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        Task {
            do {
                try await findCommand().execute(options: options,
                                                callbackQueue: callbackQueue,
                                                completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Query plan information for finding objects *asynchronously* and returns a completion block with the results.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func findExplain<U: Decodable>(usingMongoDB: Bool = false,
                                          options: API.Options = [],
                                          callbackQueue: DispatchQueue = .main,
                                          completion: @escaping (Result<[U], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        Task {
            if !usingMongoDB {
                do {
                    try await findExplainCommand().execute(options: options,
                                                           callbackQueue: callbackQueue,
                                                           completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            } else {
                do {
                    try await findExplainMongoCommand().execute(options: options,
                                                                callbackQueue: callbackQueue,
                                                                completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }
    }

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query.
        
      - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
         is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
         Defaults to 50.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of .main.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
     - warning: The items are processed in an unspecified order. The query may not have any sort
     order, and may not use limit or skip.
    */
    public func findAll(batchLimit limit: Int? = nil,
                        options: API.Options = [],
                        callbackQueue: DispatchQueue = .main,
                        completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        if self.limit == 0 {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        if order != nil ||
            skip > 0 ||
            self.limit != 100 {
            let error = ParseError(code: .otherCause,
                                   message: "Cannot iterate on a query with sort, skip, or limit.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }

        Task {
            var query = self
                .order([.ascending("objectId")])
            query.limit = limit ?? ParseConstants.batchLimit
            let originalQueryWhere = query.where
            var results = [ResultType]()
            var finished = false
            while !finished {
                do {
                    let currentResults = try await query.findCommand().execute(options: options,
                                                                               callbackQueue: callbackQueue)
                    results.append(contentsOf: currentResults)
                    if currentResults.count >= query.limit {
                        guard let lastObjectId = results[results.count - 1].objectId else {
                            throw ParseError(code: .otherCause, message: "Last object should have an objectId.")
                        }
                        query.where = originalQueryWhere
                        query.where.add("objectId" > lastObjectId)
                    } else {
                        finished = true
                    }
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                    return
                }
            }
            let finalResults = results
            callbackQueue.async {
                completion(.success(finalResults))
            }
        }
    }

    /**
      Gets an object *asynchronously* and calls the given block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<ParseObject, ParseError>)`.
    */
    public func first(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<ResultType, ParseError>) -> Void) {
        guard limit > 0 else {
            let error = ParseError(code: .objectNotFound,
                                   message: "Object not found on the server.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        Task {
            do {
                try await firstCommand().execute(options: options,
                                                 callbackQueue: callbackQueue,
                                                 completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Query plan information for getting an object *asynchronously* and returns a completion block with the result.

      - warning: This method mutates the query. It will reset the limit to `1`.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func firstExplain<U: Decodable>(usingMongoDB: Bool = false,
                                           options: API.Options = [],
                                           callbackQueue: DispatchQueue = .main,
                                           completion: @escaping (Result<U, ParseError>) -> Void) {
        guard limit > 0 else {
            let error = ParseError(code: .objectNotFound,
                                   message: "Object not found on the server.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        Task {
            if !usingMongoDB {
                do {
                    try await firstExplainCommand().execute(options: options,
                                                            callbackQueue: callbackQueue,
                                                            completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            } else {
                do {
                    try await firstExplainMongoCommand().execute(options: options,
                                                                 callbackQueue: callbackQueue,
                                                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }
    }

    /**
      Counts objects *asynchronously* and returns a completion block with the count.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Int, ParseError>)`
    */
    public func count(options: API.Options = [],
                      callbackQueue: DispatchQueue = .main,
                      completion: @escaping (Result<Int, ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success(0))
            }
            return
        }
        Task {
            do {
                try await countCommand().execute(options: options,
                                                 callbackQueue: callbackQueue,
                                                 completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Query plan information for counting objects *asynchronously* and returns a completion block with the count.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func countExplain<U: Decodable>(usingMongoDB: Bool = false,
                                           options: API.Options = [],
                                           callbackQueue: DispatchQueue = .main,
                                           completion: @escaping (Result<[U], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        Task {
            if !usingMongoDB {
                do {
                    try await countExplainCommand().execute(options: options,
                                                            callbackQueue: callbackQueue,
                                                            completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            } else {
                do {
                    try await countExplainMongoCommand().execute(options: options,
                                                                 callbackQueue: callbackQueue,
                                                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }
    }

    /**
     Finds objects *asynchronously* and returns a completion block with the results which include
     the total number of objects satisfying this query, despite limits/skip. Might be useful for pagination.

      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<([ResultType], Int), ParseError>)`
    */
    public func withCount(options: API.Options = [],
                          callbackQueue: DispatchQueue = .main,
                          completion: @escaping (Result<([ResultType], Int), ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success(([], 0)))
            }
            return
        }
        Task {
            do {
                try await withCountCommand().execute(options: options,
                                                     callbackQueue: callbackQueue,
                                                     completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Query plan information for withCount objects *asynchronously* and a completion block with the results.
      - note: An explain query will have many different underlying types. Since Swift is a strongly
      typed language, a developer should specify the type expected to be decoded which will be
      different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
      such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
      - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
      - parameter options: A set of header options sent to the server. Defaults to an empty set.
      - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
      - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<Decodable, ParseError>)`.
      - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
      `usingMongoDB` flag needs to be set for MongoDB users. See more
      [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func withCountExplain<U: Decodable>(usingMongoDB: Bool = false,
                                               options: API.Options = [],
                                               callbackQueue: DispatchQueue = .main,
                                               completion: @escaping (Result<[U], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        Task {
            if !usingMongoDB {
                do {
                    try await withCountExplainCommand().execute(options: options,
                                                                callbackQueue: callbackQueue,
                                                                completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            } else {
                do {
                    try await withCountExplainMongoCommand().execute(options: options,
                                                                     callbackQueue: callbackQueue,
                                                                     completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }
    }

    /**
      Executes an aggregate query *asynchronously*.
        - requires: `.usePrimaryKey` has to be available. It is recommended to only
        use the primary key in server-side applications where the key is kept secure and not
        exposed to the public.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ParseObject], ParseError>)`.
        - warning: This has not been tested thoroughly.
    */
    public func aggregate(_ pipeline: [[String: Encodable]],
                          options: API.Options = [],
                          callbackQueue: DispatchQueue = .main,
                          completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        Task {
            var options = options
            options.insert(.usePrimaryKey)

            var updatedPipeline = [[String: AnyCodable]]()
            pipeline.forEach { updatedPipeline = $0.map { [$0.key: AnyCodable($0.value)] } }

            guard let encoded = try? ParseCoding.jsonEncoder()
                    .encode(self.`where`) else {
                let error = ParseError(code: .otherCause,
                                       message: "Cannot decode \"where\" to String.")
                callbackQueue.async {
                    completion(.failure(error))
                }
                return
            }
            let whereString = String(decoding: encoded, as: UTF8.self)
            var query = self
            query.`where` = QueryWhere()

            if whereString != "{}" {
                var finishedPipeline = [["match": AnyCodable(whereString)]]
                finishedPipeline.append(contentsOf: updatedPipeline)
                query.pipeline = finishedPipeline
            } else {
                query.pipeline = updatedPipeline
            }

            do {
                try await query.aggregateCommand()
                    .execute(options: options,
                             callbackQueue: callbackQueue,
                             completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Query plan information for executing an aggregate query *asynchronously*.
        - requires: `.usePrimaryKey` has to be available. It is recommended to only
        use the primary key in server-side applications where the key is kept secure and not
        exposed to the public.
        - note: An explain query will have many different underlying types. Since Swift is a strongly
        typed language, a developer should specify the type expected to be decoded which will be
        different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
        such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
        - parameter pipeline: A pipeline of stages to process query.
        - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ParseObject], ParseError>)`.
        - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
        `usingMongoDB` flag needs to be set for MongoDB users. See more
        [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func aggregateExplain<U: Decodable>(_ pipeline: [[String: Encodable]], // swiftlint:disable:this function_body_length line_length
                                               usingMongoDB: Bool = false,
                                               options: API.Options = [],
                                               callbackQueue: DispatchQueue = .main,
                                               completion: @escaping (Result<[U], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        Task {
            var options = options
            options.insert(.usePrimaryKey)

            var updatedPipeline = [[String: AnyCodable]]()
            pipeline.forEach { updatedPipeline = $0.map { [$0.key: AnyCodable($0.value)] } }

            guard let encoded = try? ParseCoding.jsonEncoder()
                .encode(self.`where`) else {
                let error = ParseError(code: .otherCause,
                                       message: "Cannot decode \"where\" to String.")
                callbackQueue.async {
                    completion(.failure(error))
                }
                return
            }

            let whereString = String(decoding: encoded, as: UTF8.self)
            var query = self
            query.`where` = QueryWhere()

            if whereString != "{}" {
                var finishedPipeline = [["match": AnyCodable(whereString)]]
                finishedPipeline.append(contentsOf: updatedPipeline)
                query.pipeline = finishedPipeline
            } else {
                query.pipeline = updatedPipeline
            }
            if !usingMongoDB {
                do {
                    try await query.aggregateExplainCommand()
                        .execute(options: options,
                                 callbackQueue: callbackQueue,
                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            } else {
                do {
                    try await query.aggregateExplainMongoCommand()
                        .execute(options: options,
                                 callbackQueue: callbackQueue,
                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }
    }

    /**
     Executes a distinct query *asynchronously* and returns unique values.
        - requires: `.usePrimaryKey` has to be available. It is recommended to only
        use the primary key in server-side applications where the key is kept secure and not
        exposed to the public.
        - parameter key: A field to find distinct values.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[ParseObject], ParseError>)`.
        - warning: This has not been tested thoroughly.
    */
    public func distinct(_ key: String,
                         options: API.Options = [],
                         callbackQueue: DispatchQueue = .main,
                         completion: @escaping (Result<[ResultType], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([ResultType]()))
            }
            return
        }
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            do {
                try await distinctCommand(key: key)
                    .execute(options: options,
                             callbackQueue: callbackQueue,
                             completion: completion)
            } catch {
                let parseError = error as? ParseError ?? ParseError(swift: error)
                callbackQueue.async {
                    completion(.failure(parseError))
                }
            }
        }
    }

    /**
     Query plan information for executing a distinct query *asynchronously* and returns unique values.
        - requires: `.usePrimaryKey` has to be available. It is recommended to only
        use the primary key in server-side applications where the key is kept secure and not
        exposed to the public.
        - note: An explain query will have many different underlying types. Since Swift is a strongly
        typed language, a developer should specify the type expected to be decoded which will be
        different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
        such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
        - parameter key: A field to find distinct values.
        - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
        - parameter options: A set of header options sent to the server. Defaults to an empty set.
        - parameter callbackQueue: The queue to return to after completion. Default value of `.main`.
        - parameter completion: The block to execute.
      It should have the following argument signature: `(Result<[Decodable], ParseError>)`.
        - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
        `usingMongoDB` flag needs to be set for MongoDB users. See more
        [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    public func distinctExplain<U: Decodable>(_ key: String,
                                              usingMongoDB: Bool = false,
                                              options: API.Options = [],
                                              callbackQueue: DispatchQueue = .main,
                                              completion: @escaping (Result<[U], ParseError>) -> Void) {
        guard limit > 0 else {
            callbackQueue.async {
                completion(.success([U]()))
            }
            return
        }
        Task {
            var options = options
            options.insert(.usePrimaryKey)
            if !usingMongoDB {
                do {
                    try await distinctExplainCommand(key: key)
                        .execute(options: options,
                                 callbackQueue: callbackQueue,
                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            } else {
                do {
                    try await distinctExplainMongoCommand(key: key)
                        .execute(options: options,
                                 callbackQueue: callbackQueue,
                                 completion: completion)
                } catch {
                    let parseError = error as? ParseError ?? ParseError(swift: error)
                    callbackQueue.async {
                        completion(.failure(parseError))
                    }
                }
            }
        }
    }
}

extension Query {

    func findCommand() async throws -> API.NonParseBodyCommand<Query<ResultType>, [ResultType]> {
        try await yieldIfNotInitialized()
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: endpoint,
                                           params: try getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: endpoint,
                                           body: self) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
            }
        }
    }

    func firstCommand() async throws -> API.NonParseBodyCommand<Query<ResultType>, ResultType> {
        try await yieldIfNotInitialized()
        var query = self
        query.limit = 1
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                if let decoded = try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results.first {
                    return decoded
                }
                throw ParseError(code: .objectNotFound,
                                 message: "Object not found on the server.")
            }
        } else {
            return API.NonParseBodyCommand(method: .POST, path: query.endpoint, body: query) {
                if let decoded = try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results.first {
                    return decoded
                }
                throw ParseError(code: .objectNotFound,
                                 message: "Object not found on the server.")
            }
        }
    }

    func countCommand() async throws -> API.NonParseBodyCommand<Query<ResultType>, Int> {
        try await yieldIfNotInitialized()
        var query = self
        query.limit = 0
        query.isCount = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).count ?? 0
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).count ?? 0
            }
        }
    }

    func withCountCommand() async throws -> API.NonParseBodyCommand<Query<ResultType>, ([ResultType], Int)> {
        try await yieldIfNotInitialized()
        var query = self
        query.isCount = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                let decoded = try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0)
                return (decoded.results, decoded.count ?? 0)
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                let decoded = try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0)
                return (decoded.results, decoded.count ?? 0)
            }
        }
    }

    func aggregateCommand() async throws -> API.NonParseBodyCommand<AggregateBody<ResultType>, [ResultType]> {
        try await yieldIfNotInitialized()
        let body = AggregateBody(query: self)
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: .aggregate(className: T.className),
                                           params: try body.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: .aggregate(className: T.className),
                                           body: body) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
            }
        }
    }

    func distinctCommand(key: String) async throws -> API.NonParseBodyCommand<DistinctBody<ResultType>, [ResultType]> {
        try await yieldIfNotInitialized()
        var query = self
        query.distinct = key
        let body = DistinctBody(query: query)
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: .aggregate(className: T.className),
                                           params: try body.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: .aggregate(className: T.className),
                                           body: body) {
                try ParseCoding.jsonDecoder().decode(QueryResponse<T>.self, from: $0).results
            }
        }
    }

    func findExplainCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        }
    }

    func firstExplainCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, U> {
        try await yieldIfNotInitialized()
        var query = self
        query.limit = 1
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                if let decoded = try ParseCoding
                    .jsonDecoder()
                    .decode(AnyResultsResponse<U>.self, from: $0)
                    .results.first {
                    return decoded
                }
                throw ParseError(code: .objectNotFound,
                                 message: "Object not found on the server.")
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                if let decoded = try ParseCoding
                    .jsonDecoder()
                    .decode(AnyResultsResponse<U>.self, from: $0)
                    .results.first {
                    return decoded
                }
                throw ParseError(code: .objectNotFound,
                                 message: "Object not found on the server.")
            }
        }
    }

    func countExplainCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.limit = 1
        query.isCount = true
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        }
    }

    func withCountExplainCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.isCount = true
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        }
    }

    // swiftlint:disable:next line_length
    func aggregateExplainCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<AggregateBody<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.explain = true
        let body = AggregateBody(query: query)
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: .aggregate(className: T.className),
                                           params: try body.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: .aggregate(className: T.className),
                                           body: body) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        }
    }

    // swiftlint:disable:next line_length
    func distinctExplainCommand<U: Decodable>(key: String) async throws -> API.NonParseBodyCommand<DistinctBody<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.explain = true
        query.distinct = key
        let body = DistinctBody(query: query)
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: .aggregate(className: T.className),
                                           params: try body.getQueryParameters()) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        } else {
            return API.NonParseBodyCommand(method: .POST, path: .aggregate(className: T.className), body: body) {
                try ParseCoding.jsonDecoder().decode(AnyResultsResponse<U>.self, from: $0).results
            }
        }
    }

    func findExplainMongoCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        }
    }

    func firstExplainMongoCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, U> {
        try await yieldIfNotInitialized()
        var query = self
        query.limit = 1
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                do {
                    return try ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results
                } catch {
                    throw ParseError(code: .objectNotFound,
                                     message: "Object not found on the server. Error: \(error)")
                }
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                do {
                    return try ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results
                } catch {
                    throw ParseError(code: .objectNotFound,
                                     message: "Object not found on the server. Error: \(error)")
                }
            }
        }
    }

    func countExplainMongoCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.limit = 1
        query.isCount = true
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        }
    }

    func withCountExplainMongoCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<Query<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.isCount = true
        query.explain = true
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: query.endpoint,
                                           params: try query.getQueryParameters()) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: query.endpoint,
                                           body: query) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        }
    }

    // swiftlint:disable:next line_length
    func aggregateExplainMongoCommand<U: Decodable>() async throws -> API.NonParseBodyCommand<AggregateBody<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.explain = true
        let body = AggregateBody(query: query)
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: .aggregate(className: T.className),
                                           params: try body.getQueryParameters()) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: .aggregate(className: T.className),
                                           body: body) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        }
    }

    // swiftlint:disable:next line_length
    func distinctExplainMongoCommand<U: Decodable>(key: String) async throws -> API.NonParseBodyCommand<DistinctBody<ResultType>, [U]> {
        try await yieldIfNotInitialized()
        var query = self
        query.explain = true
        query.distinct = key
        let body = DistinctBody(query: query)
        if !Parse.configuration.isUsingPostForQuery {
            return API.NonParseBodyCommand(method: .GET,
                                           path: .aggregate(className: T.className),
                                           params: try body.getQueryParameters()) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        } else {
            return API.NonParseBodyCommand(method: .POST,
                                           path: .aggregate(className: T.className),
                                           body: body) {
                try [ParseCoding.jsonDecoder().decode(AnyResultsMongoResponse<U>.self, from: $0).results]
            }
        }
    }
}

// MARK: Codable
public extension Query {

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(`where`, forKey: .`where`)
        try container.encodeIfPresent(method, forKey: .method)
        try container.encodeIfPresent(limit, forKey: .limit)
        try container.encodeIfPresent(skip, forKey: .skip)
        try container.encodeIfPresent(include?.sorted(), forKey: .include)
        try container.encodeIfPresent(isCount, forKey: .isCount)
        try container.encodeIfPresent(keys?.sorted(), forKey: .keys)
        try container.encodeIfPresent(order, forKey: .order)
        try container.encodeIfPresent(explain, forKey: .explain)
        try container.encodeIfPresent(hint, forKey: .hint)
        try container.encodeIfPresent(excludeKeys?.sorted(), forKey: .excludeKeys)
        try container.encodeIfPresent(readPreference, forKey: .readPreference)
        try container.encodeIfPresent(includeReadPreference, forKey: .includeReadPreference)
        try container.encodeIfPresent(subqueryReadPreference, forKey: .subqueryReadPreference)
        try container.encodeIfPresent(distinct, forKey: .distinct)
        try container.encodeIfPresent(pipeline, forKey: .pipeline)
    }

    // swiftlint:disable:next function_body_length
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        `where` = try values.decode(QueryWhere.self, forKey: .`where`)
        if let limit = try values.decodeIfPresent(Int.self, forKey: .limit) {
            self.limit = limit
        }
        if let skip = try values.decodeIfPresent(Int.self, forKey: .skip) {
            self.skip = skip
        }
        do {
            keys = try values.decodeIfPresent(Set<String>.self, forKey: .keys)
        } catch {
            if let commaString = try values.decodeIfPresent(String.self, forKey: .keys) {
                let commaArray = commaString
                    .split(separator: ",")
                    .compactMap { String($0) }
                keys = Set(commaArray)
            }
        }
        do {
            include = try values.decodeIfPresent(Set<String>.self, forKey: .include)
        } catch {
            if let commaString = try values.decodeIfPresent(String.self, forKey: .include) {
                let commaArray = commaString
                    .split(separator: ",")
                    .compactMap { String($0) }
                include = Set(commaArray)
            }
        }
        do {
            order = try values.decodeIfPresent([Order].self, forKey: .order)
        } catch {
            let orderString = try values
                .decodeIfPresent(String.self, forKey: .order)?
                .split(separator: ",")
                .compactMap { String($0) }
            order = orderString?.map {
                var value = $0
                if value.hasPrefix("-") {
                    value.removeFirst()
                    return Order.descending(value)
                } else {
                    return Order.ascending(value)
                }
            }
        }
        do {
            excludeKeys = try values.decodeIfPresent(Set<String>.self, forKey: .excludeKeys)
        } catch {
            if let commaString = try values.decodeIfPresent(String.self, forKey: .excludeKeys) {
                let commaArray = commaString
                    .split(separator: ",")
                    .compactMap { String($0) }
                excludeKeys = Set(commaArray)
            }
        }
        isCount = try values.decodeIfPresent(Bool.self, forKey: .isCount)
        explain = try values.decodeIfPresent(Bool.self, forKey: .explain)
        hint = try values.decodeIfPresent(AnyCodable.self, forKey: .hint)
        readPreference = try values.decodeIfPresent(String.self, forKey: .readPreference)
        includeReadPreference = try values.decodeIfPresent(String.self, forKey: .includeReadPreference)
        subqueryReadPreference = try values.decodeIfPresent(String.self, forKey: .subqueryReadPreference)
        distinct = try values.decodeIfPresent(String.self, forKey: .distinct)
        pipeline = try values.decodeIfPresent([[String: AnyCodable]].self, forKey: .pipeline)
    }
}

// MARK: Query
public extension ParseObject {

    /**
      Create a query with no constraints.
     */
    static var query: Query<Self> {
        Query<Self>()
    }

    /**
      Create a query with a variadic amount constraints.
     - parameter constraints: A variadic amount of zero or more `QueryConstraint`'s.
     - returns: An instance of query for easy chaining.
     */
    static func query(_ constraints: QueryConstraint...) -> Query<Self> {
        Self.query(constraints)
    }

    /**
      Create a query with an array of constraints.
     - parameter constraints: An array of `QueryConstraint`'s.
     - returns: An instance of query for easy chaining.
     */
    static func query(_ constraints: [QueryConstraint] = []) -> Query<Self> {
        Query<Self>(constraints)
    }
}

// MARK: ParseUser
extension Query where T: ParseUser {
    var endpoint: API.Endpoint {
        return .users
    }
}

// MARK: ParseInstallation
extension Query where T: ParseInstallation {
    var endpoint: API.Endpoint {
        return .installations
    }
}

// MARK: ParseSession
extension Query where T: ParseSession {
    var endpoint: API.Endpoint {
        return .sessions
    }
}

// MARK: ParseRole
extension Query where T: ParseRole {
    var endpoint: API.Endpoint {
        return .roles
    }
}

enum RawCodingKey: CodingKey {
    case key(String)
    var stringValue: String {
        switch self {
        case .key(let str):
            return str
        }
    }
    var intValue: Int? {
        nil
    }
    init?(stringValue: String) {
        self = .key(stringValue)
    }
    init?(intValue: Int) {
        fatalError()
    }
}

internal extension Query {
    func getQueryParameters() throws -> [String: String] {
        var dictionary = [String: String]()
        dictionary["limit"] = try encodeAsString(\.limit)
        dictionary["skip"] = try encodeAsString(\.skip)
        dictionary["keys"] = try encodeAsString(\.keys)
        dictionary["include"] = try encodeAsString(\.include)
        dictionary["order"] = try encodeAsString(\.order)
        dictionary["count"] = try encodeAsString(\.isCount)
        dictionary["explain"] = try encodeAsString(\.explain)
        dictionary["hint"] = try encodeAsString(\.hint)
        dictionary["where"] = try encodeAsString(\.`where`)
        dictionary["excludeKeys"] = try encodeAsString(\.excludeKeys)
        dictionary["readPreference"] = try encodeAsString(\.readPreference)
        dictionary["includeReadPreference"] = try encodeAsString(\.includeReadPreference)
        dictionary["subqueryReadPreference"] = try encodeAsString(\.subqueryReadPreference)
        dictionary["distinct"] = try encodeAsString(\.distinct)
        dictionary["pipeline"] = try encodeAsString(\.pipeline)
        return dictionary
    }

    func encodeAsString<W>(_ key: KeyPath<Self, W?>) throws -> String? where W: Encodable {
        guard let value = self[keyPath: key] else {
            return nil
        }
        let encoded = try ParseCoding.jsonEncoder().encode(value)
        return String(decoding: encoded, as: UTF8.self)
    }

    func encodeAsString(_ key: KeyPath<Self, Set<String>?>) throws -> String? {
        guard let value = self[keyPath: key]?.sorted() else {
            return nil
        }
        let encoded = try ParseCoding.jsonEncoder().encode(value)
        return String(decoding: encoded, as: UTF8.self)
    }

    func encodeAsString<W>(_ key: KeyPath<Self, W>) throws -> String? where W: Encodable {
        let encoded = try ParseCoding.jsonEncoder().encode(self[keyPath: key])
        return String(decoding: encoded, as: UTF8.self)
    }
}
// swiftlint:disable:this file_length
