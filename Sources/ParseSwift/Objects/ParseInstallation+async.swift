//
//  ParseInstallation+async.swift
//  ParseInstallation+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension ParseInstallation {

    // MARK: Async/Await
    /**
     Fetches the `ParseInstallation` *aynchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns saved `ParseInstallation`.
     - throws: An error of type `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func fetch(includeKeys: [String]? = nil,
                                  options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.fetch(includeKeys: includeKeys,
                       options: options,
                       completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Saves the `ParseInstallation` *asynchronously*.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns saved `ParseInstallation`.
     - throws: An error of type `ParseError`.
     - important: If an object saved has the same objectId as current, it will automatically update the current.
     - warning: If you are using `ParseConfiguration.isRequiringCustomObjectIds = true`
     and plan to generate all of your `objectId`'s on the client-side then you should leave
     `ignoringCustomObjectIdConfig = false`. Setting
     `ParseConfiguration.isRequiringCustomObjectIds = true` and
     `ignoringCustomObjectIdConfig = true` means the client will generate `objectId`'s
     and the server will generate an `objectId` only when the client does not provide one. This can
     increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func save(ignoringCustomObjectIdConfig: Bool = false,
                                 options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.save(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
                      options: options,
                      completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Creates the `ParseInstallation` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns saved `ParseInstallation`.
     - throws: An error of type `ParseError`.
    */
    @discardableResult func create(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.create(options: options,
                        completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Replaces the `ParseInstallation` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns saved `ParseInstallation`.
     - throws: An error of type `ParseError`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
    */
    @discardableResult func replace(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.replace(options: options,
                         completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Updates the `ParseInstallation` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns saved `ParseInstallation`.
     - throws: An error of type `ParseError`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
    */
    @discardableResult internal func update(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.update(options: options,
                        completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Deletes the `ParseInstallation` *asynchronously*.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns saved `ParseInstallation`.
     - throws: An error of type `ParseError`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
    */
    func delete(options: API.Options = []) async throws {
		try await withCheckedThrowingContinuation { continuation in
			self.delete(options: options, completion: { continuation.resume(with: $0) })
		}
    }

    /**
     Copy the `ParseInstallation` *asynchronously* based on the `objectId`.
     On success, this saves the `ParseInstallation` to the keychain, so you can retrieve
     the current installation using *current*.

     - parameter objectId: The **id** of the `ParseInstallation` to become.
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
    @discardableResult static func become(_ objectId: String,
                                          copyEntireInstallation: Bool = true,
                                          options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            Self.become(objectId,
                        copyEntireInstallation: copyEntireInstallation,
                        options: options,
                        completion: { continuation.resume(with: $0) })
        }
    }
}

// MARK: Batch Support
public extension Sequence where Element: ParseInstallation {
    /**
     Fetches a collection of installations *aynchronously* with the current data from the server and sets
     an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object fetched has the same objectId as current, it will automatically update the current.
    */
    @discardableResult func fetchAll(
		includeKeys: [String]? = nil,
		options: API.Options = []
	) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.fetchAll(includeKeys: includeKeys,
                          options: options,
                          completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Saves a collection of installations *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
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
     increase the probability of colliding `objectId`'s as the client and server `objectId`'s may be generated using
     different algorithms. This can also lead to overwriting of `ParseObject`'s by accident as the
     client-side checks are disabled. Developers are responsible for handling such cases.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func saveAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		ignoringCustomObjectIdConfig: Bool = false,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main
	) async throws -> [(Result<Self.Element, ParseError>)] {
		let method = Method.save
		let objects = try await batchCommand(
			method: method,
			batchLimit: limit,
			transaction: transaction,
			ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig,
			options: options,
			callbackQueue: callbackQueue
		)
		try? await Self.Element.updatePrimitiveStorage(
			objects.compactMap { try? $0.get() }
		)
		return objects
    }

    /**
     Creates a collection of installations *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func createAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main
	) async throws -> [(Result<Self.Element, ParseError>)] {
		let method = Method.create
		let objects = try await batchCommand(
			method: method,
			batchLimit: limit,
			transaction: transaction,
			options: options,
			callbackQueue: callbackQueue
		)
		try? await Self.Element.updatePrimitiveStorage(
			objects.compactMap { try? $0.get() }
		)
		return objects
    }

    /**
     Replaces a collection of installations *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object replaced has the same objectId as current, it will automatically replace the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    @discardableResult func replaceAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main
	) async throws -> [(Result<Self.Element, ParseError>)] {
		let method = Method.replace
		let objects = try await batchCommand(
			method: method,
			batchLimit: limit,
			transaction: transaction,
			options: options,
			callbackQueue: callbackQueue
		)
		try? await Self.Element.updatePrimitiveStorage(
			objects.compactMap { try? $0.get() }
		)
		return objects
    }

    /**
     Updates a collection of installations *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - returns: Returns an array of Result enums with the object if a save was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
     - important: If an object updated has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    internal func updateAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main
	) async throws -> [(Result<Self.Element, ParseError>)] {
		let method = Method.update
		let objects = try await batchCommand(
			method: method,
			batchLimit: limit,
			transaction: transaction,
			options: options,
			callbackQueue: callbackQueue
		)
		try? await Self.Element.updatePrimitiveStorage(
			objects.compactMap { try? $0.get() }
		)
		return objects
    }

    /**
     Deletes a collection of installations *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - returns: Returns and array of `(Result<Void, ParseError>)`.
     - throws: An error of type `ParseError`.
     - important: If an object deleted has the same objectId as current, it will automatically update the current.
     - warning: If `transaction = true`, then `batchLimit` will be automatically be set to the amount of the
     objects in the transaction. The developer should ensure their respective Parse Servers can handle the limit or else
     the transactions can fail.
    */
    @discardableResult func deleteAll(
		batchLimit limit: Int? = nil,
		transaction: Bool = configuration.isUsingTransactions,
		options: API.Options = [],
		callbackQueue: DispatchQueue = .main
	) async throws -> [(Result<Void, ParseError>)] {
		var options = options
		options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
		let updatedOptions = options

		let commands = try map({ try $0.deleteCommand() })
		let batchLimit = limit ?? ParseConstants.batchLimit
		try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
		let batches = BatchUtils.splitArray(
			commands,
			valuesPerSegment: batchLimit
		)

		let returnBatch = try await withThrowingTaskGroup(
			of: ParseObjectBatchResponseNoBody<NoBody>.self,
			returning: [(Result<Void, ParseError>)].self
		) { group in
			for batch in batches {
				group.addTask {
					try await API.Command<Self.Element, ParseError?>
						.batch(commands: batch, transaction: transaction)
						.execute(
							options: updatedOptions,
							callbackQueue: callbackQueue
						)
				}
			}
			return try await group.reduce(into: [(Result<Void, ParseError>)]()) { partialResult, batch in
				partialResult.append(contentsOf: batch)
			}
		}
		try? await Self.Element.updatePrimitiveStorage(
			Array(self),
			deleting: true
		)
		return returnBatch
    }
}

// MARK: Helper Methods (Internal)
internal extension ParseInstallation {

    func command(method: Method,
                 ignoringCustomObjectIdConfig: Bool = false,
                 options: API.Options,
                 callbackQueue: DispatchQueue) async throws -> Self {
        let (savedChildObjects, savedChildFiles) = try await self.ensureDeepSave(options: options)
        do {
            let command: API.Command<Self, Self>!
            switch method {
            case .save:
                command = try await self.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
            case .create:
                command = try await self.createCommand()
            case .replace:
                command = try self.replaceCommand()
            case .update:
                command = try self.updateCommand()
            }
            let saved = try await command
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         childObjects: savedChildObjects,
                         childFiles: savedChildFiles)
            try? await Self.updatePrimitiveStorage([saved])
            return saved
        } catch {
            throw error as? ParseError ?? ParseError(swift: error)
        }
    }
}

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
// MARK: Migrate from Objective-C SDK
public extension ParseInstallation {
    /**
     Deletes the Objective-C Keychain along with the Objective-C `ParseInstallation`
     from the Parse Server *asynchronously*.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns saved `ParseInstallation`.
     - throws: An error of type `ParseError`.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
     - warning: When initializing the Swift SDK, `migratingFromObjcSDK` should be set to **false**
     when calling this method.
     - warning: It is recommended to only use this method after a succesfful migration. Calling this
     method will destroy the entire Objective-C Keychain and `ParseInstallation` on the Parse
     Server. This method assumes **PFInstallation.installationId** is saved to the Keychain. If the
     **installationId** is not saved to the Keychain, this method will not work.
    */
    static func deleteObjCKeychain(options: API.Options = []) async throws {
		try await withCheckedThrowingContinuation { continuation in
			Self.deleteObjCKeychain(options: options, completion: { continuation.resume(with: $0) })
		}
    }
}
#endif
