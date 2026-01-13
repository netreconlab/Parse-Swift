//
//  ParseObject+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Combine

public extension ParseObject {

    // MARK: Combine
    /**
     Fetches the `ParseObject` *aynchronously* with the current data from the server.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(
		includeKeys: [String]? = nil,
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetch(
				includeKeys: includeKeys,
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
     Saves the `ParseObject` *asynchronously* and publishes when complete.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func savePublisher(
		ignoringCustomObjectIdConfig: Bool = false,
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.save(
				ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
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
     Creates the `ParseObject` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func createPublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.create(
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
     Replaces the `ParseObject` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func replacePublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.replace(
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
     Updates the `ParseObject` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    internal func updatePublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.update(
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
     Deletes the `ParseObject` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func deletePublisher(
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.delete(
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

public extension Sequence where Element: ParseObject {

    /**
     Fetches a collection of objects *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a fetch was
     successful or a `ParseError` if it failed.
    */
    func fetchAllPublisher(
		includeKeys: [String]? = nil,
		options: API.Options = []
	) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetchAll(
				includeKeys: includeKeys,
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
	 Saves a collection of objects *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
	 when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
	 `objectId` environments. Defaults to false.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
	 successful or a `ParseError` if it failed.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
	 and plan to generate all of your `objectId`'s on the client-side then you should leave
	 `ignoringCustomObjectIdConfig = false`. Setting
	 `ParseConfiguration.isRequiringCustomObjectIds = true` and
	 `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
	 and the server will generate an `objectId` only when the client does not provide one. This can
	 increase the probability of colliiding `objectId`'s as the client and server `objectId`'s may be generated using
	 different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
	 client-side checks are disabled. Developers are responsible for handling such cases.
	*/
	func saveAllPublisher(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		ignoringCustomObjectIdConfig: Bool = false,
		options: API.Options = []
	) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
		Future { promise in
			nonisolated(unsafe) let promise = promise
			self.saveAll(
				batchLimit: limit,
				transaction: transaction,
				ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
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
	 Creates a collection of objects *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
	 successful or a `ParseError` if it failed.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	*/
	func createAllPublisher(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = []
	) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
		Future { promise in
			nonisolated(unsafe) let promise = promise
			self.createAll(
				batchLimit: limit,
				transaction: transaction,
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
	 Replaces a collection of objects *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
	 successful or a `ParseError` if it failed.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	*/
	func replaceAllPublisher(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = []
	) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
		Future { promise in
			nonisolated(unsafe) let promise = promise
			self.replaceAll(
				batchLimit: limit,
				transaction: transaction,
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
	 Updates a collection of objects *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
	 successful or a `ParseError` if it failed.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	*/
	internal func updateAllPublisher(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = []
	) -> Future<[(Result<Self.Element, ParseError>)], ParseError> {
		Future { promise in
			nonisolated(unsafe) let promise = promise
			self.updateAll(
				batchLimit: limit,
				transaction: transaction,
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
	 Deletes a collection of objects *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with `nil` if a delete was
	 successful or a `ParseError` if it failed.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	*/
	func deleteAllPublisher(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = []
	) -> Future<[(Result<Void, ParseError>)], ParseError> {
		Future { promise in
			nonisolated(unsafe) let promise = promise
			self.deleteAll(
				batchLimit: limit,
				transaction: transaction,
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
}

#endif
