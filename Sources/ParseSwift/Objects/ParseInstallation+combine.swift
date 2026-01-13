//
//  ParseInstallation+combine.swift
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

public extension ParseInstallation {

    // MARK: Combine
    /**
     Fetches the `ParseInstallation` *aynchronously* with the current data from the server.
     Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
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
				case .success(let installation):
					promise(.success(installation))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Saves the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
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
				case .success(let installation):
					promise(.success(installation))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Creates the `ParseInstallation` *asynchronously* and publishes when complete.

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
				case .success(let installation):
					promise(.success(installation))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Replaces the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
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
				case .success(let installation):
					promise(.success(installation))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Updates the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
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
				case .success(let installation):
					promise(.success(installation))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Deletes the `ParseInstallation` *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
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

    /**
     Copies the `ParseInstallation` *asynchronously* based on the `installationId` and publishes
     when complete. On success, this saves the `ParseInstallation` to the keychain, so you can retrieve
     the current installation using *current*.

     - parameter installationId: The **id** of the `ParseInstallation` to become.
     - parameter copyEntireInstallation: When **true**, copies the entire `ParseInstallation`.
     When **false**, only the `channels` and `deviceToken` are copied; resulting in a new
     `ParseInstallation` for original `sessionToken`. Defaults to **true**.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<Self, ParseError>)`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    static func becomePublisher(
		_ installationId: String,
		copyEntireInstallation: Bool = true,
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            Self.become(
				installationId,
				copyEntireInstallation: copyEntireInstallation,
				options: options
			) { result in
				switch result {
				case .success(let installation):
					promise(.success(installation))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseInstallation {

    /**
     Fetches a collection of installations *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a fetch was
     successful or a `ParseError` if it failed.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
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
				case .success(let installations):
					promise(.success(installations))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

	/**
	 Saves a collection of installations *asynchronously* and publishes when complete.
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
	 - important: If an object saved has the same objectId as current, it will automatically update the current.
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
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
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
				case .success(let installations):
					promise(.success(installations))
				case .failure(let error):
					promise(.failure(error))
				}
			}
		}
	}

	/**
	 Creates a collection of installations *asynchronously* and publishes when complete.
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
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
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
				case .success(let installations):
					promise(.success(installations))
				case .failure(let error):
					promise(.failure(error))
				}
			}
		}
	}

	/**
	 Replaces a collection of installations *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
	 successful or a `ParseError` if it failed.
	 - important: If an object replaced has the same objectId as current, it will automatically replace the current.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
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
				case .success(let installations):
					promise(.success(installations))
				case .failure(let error):
					promise(.failure(error))
				}
			}
		}
	}

	/**
	 Updates a collection of installations *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with the object if a save was
	 successful or a `ParseError` if it failed.
	 - important: If an object updated has the same objectId as current, it will automatically update the current.
	 - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
	 objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
	 the transactions can fail.
	 - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
	 desires a different policy, it should be inserted in `options`.
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
				case .success(let installations):
					promise(.success(installations))
				case .failure(let error):
					promise(.failure(error))
				}
			}
		}
	}

	/**
	 Deletes a collection of installations *asynchronously* and publishes when complete.
	 - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
	 is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
	 Defaults to 50.
	 - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
	 prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
	 - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - returns: A publisher that eventually produces an an array of Result enums with `nil` if a delete was
	 successful or a `ParseError` if it failed.
	 - important: If an object deleted has the same objectId as current, it will automatically update the current.
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
				case .success(let installations):
					promise(.success(installations))
				case .failure(let error):
					promise(.failure(error))
				}
			}
		}
	}
}

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
// MARK: Migrate from Objective-C SDK
public extension ParseInstallation {
    /**
     Deletes the Objective-C Keychain along with the Objective-C `ParseInstallation`
     from the Parse Server *asynchronously* and publishes when complete.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - warning: It is recommended to only use this method after a succesfful migration. Calling this
     method will destroy the entire Objective-C Keychain and `ParseInstallation` on the Parse
     Server.
    */
    static func deleteObjCKeychainPublisher(
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            Self.deleteObjCKeychain(
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
#endif
