//
//  Query+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension Query {

    // MARK: Combine

    /**
     Finds objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func findPublisher(
		options: API.Options = []
	) -> Future<[ResultType], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.find(
				options: options
			) { result in
				switch result {
				case .success(let objects):
					promise(.success(objects))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Query plan information for finding objects *asynchronously* and publishes when complete.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func findExplainPublisher<U: Decodable & Sendable>(
		usingMongoDB: Bool = false,
		options: API.Options = []
	) -> Future<[U], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.findExplain(
				usingMongoDB: usingMongoDB,
				options: options
			) { (result: Result<[U], ParseError>) in
				switch result {
				case .success(let objects):
					promise(.success(objects))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Retrieves *asynchronously* a complete list of `ParseObject`'s  that satisfy this query
     and publishes when complete.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: The items are processed in an unspecified order. The query may not have any sort
     order, and may not use limit or skip.
    */
    func findAllPublisher(
		batchLimit: Int? = nil,
		options: API.Options = []
	) -> Future<[ResultType], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.findAll(
				batchLimit: batchLimit,
				options: options
			) { result in
				switch result {
				case .success(let objects):
					promise(.success(objects))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Gets an object *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func firstPublisher(
		options: API.Options = []
	) -> Future<ResultType, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.first(
				options: options
			) { result in
				switch result {
				case .success(let object):
					promise(.success(object))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Query plan information for getting an object *asynchronously* and publishes when complete.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func firstExplainPublisher<U: Decodable & Sendable>(
		usingMongoDB: Bool = false,
		options: API.Options = []
	) -> Future<U, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.firstExplain(
				usingMongoDB: usingMongoDB,
				options: options
			) { (result: Result<U, ParseError>) in
				switch result {
				case .success(let object):
					promise(.success(object))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Count objects *asynchronously* and publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func countPublisher(
		options: API.Options = []
	) -> Future<Int, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.count(
				options: options
			) { result in
				switch result {
				case .success(let count):
					promise(.success(count))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Query plan information for counting objects *asynchronously* and publishes when complete.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for MongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func countExplainPublisher<U: Decodable & Sendable>(
		usingMongoDB: Bool = false,
		options: API.Options = []
	) -> Future<[U], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.countExplain(
				usingMongoDB: usingMongoDB,
				options: options
			) { (result: Result<[U], ParseError>) in
				switch result {
				case .success(let count):
					promise(.success(count))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Finds objects *asynchronously* and returns a tuple of the results which include
     the total number of objects satisfying this query, despite limits/skip. Might be useful for pagination.
     Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func withCountPublisher(
		options: API.Options = []
	) -> Future<([ResultType], Int), ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.withCount(
				options: options
			) { result in
				switch result {
				case .success(let count):
					promise(.success(count))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Query plan information for counting objects *asynchronously* and publishes when complete.
     - note: An explain query will have many different underlying types. Since Swift is a strongly
     typed language, a developer should specify the type expected to be decoded which will be
     different for mongoDB and PostgreSQL. One way around this is to use a type-erased wrapper
     such as the [AnyCodable](https://github.com/Flight-School/AnyCodable) package.
     - parameter usingMongoDB: Set to **true** if your Parse Server uses MongoDB. Defaults to **false**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func withCountExplainPublisher<U: Decodable & Sendable>(
		usingMongoDB: Bool = false,
		options: API.Options = []
	) -> Future<[U], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.withCountExplain(
				usingMongoDB: usingMongoDB,
				options: options
			) { (result: Result<[U], ParseError>) in
				switch result {
				case .success(let count):
					promise(.success(count))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Executes an aggregate query *asynchronously* and publishes when complete.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
     - parameter pipeline: A pipeline of stages to process query.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func aggregatePublisher(
		_ pipeline: [[String: Encodable & Sendable]],
		options: API.Options = []
	) -> Future<[ResultType], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.aggregate(
				pipeline,
				options: options
			) { result in
				switch result {
				case .success(let objects):
					promise(.success(objects))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Query plan information for executing an aggregate query *asynchronously* and publishes when complete.
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
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func aggregateExplainPublisher<U: Decodable & Sendable>(
		_ pipeline: [[String: Encodable & Sendable]],
		usingMongoDB: Bool = false,
		options: API.Options = []
	) -> Future<[U], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.aggregateExplain(
				pipeline,
				usingMongoDB: usingMongoDB,
				options: options
			) { (result: Result<[U], ParseError>) in
				switch result {
				case .success(let objects):
					promise(.success(objects))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Executes a distinct query *asynchronously* and publishes unique values when complete.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
     - parameter key: A field to find distinct values.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func distinctPublisher(
		_ key: String,
		options: API.Options = []
	) -> Future<[ResultType], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.distinct(
				key,
				options: options
			) { result in
				switch result {
				case .success(let objects):
					promise(.success(objects))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Query plan information for executing a distinct query *asynchronously* and publishes unique values when complete.
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
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: MongoDB's **explain** does not conform to the traditional Parse Server response, so the
     `usingMongoDB` flag needs to be set for MongoDB users. See more
     [here](https://github.com/parse-community/parse-server/pull/7440).
    */
    func distinctExplainPublisher<U: Decodable & Sendable>(
		_ key: String,
		usingMongoDB: Bool = false,
		options: API.Options = []
	) -> Future<[U], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.distinctExplain(
				key,
				usingMongoDB: usingMongoDB,
				options: options
			) { (result: Result<[U], ParseError>) in
				switch result {
				case .success(let objects):
					promise(.success(objects))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

#endif
