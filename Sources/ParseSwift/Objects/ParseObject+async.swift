//
//  ParseObject+async.swift
//  ParseObject+async
//
//  Created by Corey Baker on 8/6/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public extension ParseObject {

    // MARK: Async/Await
    /**
     Fetches the `ParseObject` *aynchronously* with the current data from the server.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the fetched `ParseObject`.
     - throws: An error of type `ParseError`.
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
     Saves the `ParseObject` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseObject`.
     - throws: An error of type `ParseError`.
    */
    @discardableResult func save(options: API.Options = []) async throws -> Self {
        try await save(ignoringCustomObjectIdConfig: false, options: options)
    }

    /**
     Saves the `ParseObject` *asynchronously*.
     - parameter ignoringCustomObjectIdConfig: Ignore checking for `objectId`
     when `ParseConfiguration.isRequiringCustomObjectIds = true` to allow for mixed
     `objectId` environments. Defaults to false.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseObject`.
     - throws: An error of type `ParseError`.
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
     Creates the `ParseObject` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseObject`.
     - throws: An error of type `ParseError`.
    */
    @discardableResult func create(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.create(options: options,
                        completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Replaces the `ParseObject` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseObject`.
     - throws: An error of type `ParseError`.
    */
    @discardableResult func replace(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.replace(options: options,
                         completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Updates the `ParseObject` *asynchronously*.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns the saved `ParseObject`.
     - throws: An error of type `ParseError`.
    */
    @discardableResult internal func update(options: API.Options = []) async throws -> Self {
        try await withCheckedThrowingContinuation { continuation in
            self.update(options: options,
                        completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Deletes the `ParseObject` *asynchronously*.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - throws: An error of type `ParseError`.
    */
    func delete(options: API.Options = []) async throws {
		try await withCheckedThrowingContinuation { continuation in
			self.delete(options: options,
						completion: { continuation.resume(with: $0) })
		}
    }
}

public extension Sequence where Element: ParseObject {
    /**
     Fetches a collection of objects *aynchronously* with the current data from the server and sets
     an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a fetch was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
    */
    @discardableResult func fetchAll(includeKeys: [String]? = nil,
                                     options: API.Options = []) async throws -> [(Result<Self.Element, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.fetchAll(includeKeys: includeKeys,
                          options: options,
                          completion: { continuation.resume(with: $0) })
        }
    }

    /**
     Saves a collection of objects *asynchronously*.
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
		return objects
    }

    /**
     Creates a collection of objects *asynchronously*.
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
		return objects
    }

    /**
     Replaces a collection of objects *asynchronously*.
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
		return objects
    }

    /**
     Updates a collection of objects *asynchronously*.
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
	@discardableResult internal func updateAll(
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
		return objects
    }

    /**
     Deletes a collection of objects *asynchronously*.
     - parameter batchLimit: The maximum number of objects to send in each batch. If the amount of items to be batched
     is greater than the `batchLimit`, the objects will be sent to the server in waves up to the `batchLimit`.
     Defaults to 50.
     - parameter transaction: Treat as an all-or-nothing operation. If some operation failure occurs that
     prevents the transaction from completing, then none of the objects are committed to the Parse Server database.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
	 - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - returns: Returns `nil` if the delete successful or a `ParseError` if it failed.
     - throws: An error of type `ParseError`.
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
		let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
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
		return returnBatch
    }
}

// MARK: Helper Methods (Internal)
internal extension ParseObject {

    // swiftlint:disable:next function_body_length
    func ensureDeepSave(options: API.Options = [],
                        isShouldReturnIfChildObjectsFound: Bool = false) async throws -> ([String: PointerType],
                                                                                          [String: ParseFile]) {

        var options = options
        // Remove any caching policy added by the developer as fresh data
        // from the server is needed.
        options.remove(.cachePolicy(.reloadIgnoringLocalCacheData))
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
        var objectsFinishedSaving = [String: PointerType]()
        var filesFinishedSaving = [String: ParseFile]()
        let defaultACL = try? await ParseACL.defaultACL()
        do {
            let object = try ParseCoding
				.parseEncoder()
                .encode(
					self,
					acl: defaultACL,
					collectChildren: true,
					objectsSavedBeforeThisOne: nil,
					filesSavedBeforeThisOne: nil
				)
            var waitingToBeSaved = object.unsavedChildren
            if isShouldReturnIfChildObjectsFound &&
                waitingToBeSaved.count > 0 {
                let error = ParseError(code: .otherCause,
                                       message: """
When using transactions, all child ParseObjects have to originally
be saved to the Parse Server. Either save all child objects first
or disable transactions for this call.
""")
                throw error
            }
            while waitingToBeSaved.count > 0 {
                var savableObjects = [ParseEncodable]()
                var savableFiles = [ParseFile]()
                var nextBatch = [ParseEncodable]()
                try waitingToBeSaved.forEach { parseType in
                    if let parseFile = parseType as? ParseFile {
                        // ParseFiles can be saved now
                        savableFiles.append(parseFile)
                    } else if let parseObject = parseType as? Objectable {
                        // This is a ParseObject
                        let waitingObjectInfo = try ParseCoding
                            .parseEncoder()
                            .encode(
								parseObject,
								acl: defaultACL,
								batching: false,
								collectChildren: true,
								objectsSavedBeforeThisOne: objectsFinishedSaving,
								filesSavedBeforeThisOne: filesFinishedSaving
							)
                        if waitingObjectInfo.unsavedChildren.count == 0 {
                            // If this ParseObject has no additional children, it can be saved now
                            savableObjects.append(parseObject)
                        } else {
                            // Else this ParseObject needs to wait until it is children are saved
                            nextBatch.append(parseObject)
                        }
                    }
                }
                waitingToBeSaved = nextBatch
                if waitingToBeSaved.count > 0 &&
                    savableObjects.count == 0 &&
                    savableFiles.count == 0 {
                    throw ParseError(code: .otherCause,
                                     message: "Found a circular dependency in ParseObject.")
                }
                if savableObjects.count > 0 {
                    let savedChildObjects = try await self.saveAll(objects: savableObjects,
                                                                   objectsSavedBeforeThisOne: objectsFinishedSaving,
                                                                   filesSavedBeforeThisOne: filesFinishedSaving,
                                                                   options: options)
                    let savedChildPointers = try savedChildObjects.compactMap { try $0.get() }
                    for (index, object) in savableObjects.enumerated() {
                        let hash = try BaseObjectable.createHash(object)
                        objectsFinishedSaving[hash] = savedChildPointers[index]
                    }
                }
                for savableFile in savableFiles {
                    filesFinishedSaving[savableFile.id] = try await savableFile.save(options: options)
                }
            }
            return (objectsFinishedSaving, filesFinishedSaving)
        } catch {
            throw error as? ParseError ?? ParseError(swift: error)
        }
    }

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
            return try await command
                .execute(options: options,
                         callbackQueue: callbackQueue,
                         childObjects: savedChildObjects,
                         childFiles: savedChildFiles)
        } catch {
            throw error as? ParseError ?? ParseError(swift: error)
        }
    }
}

// MARK: Batch Support
internal extension Sequence where Element: ParseObject {
    // swiftlint:disable:next function_body_length
    func batchCommand(
		method: Method,
		batchLimit limit: Int?,
		transaction: Bool,
		ignoringCustomObjectIdConfig: Bool = false,
		options: API.Options,
		callbackQueue: DispatchQueue
	) async throws -> [(Result<Element, ParseError>)] {
        var options = options
        options.insert(.cachePolicy(.reloadIgnoringLocalCacheData))
		let updatedOptions = options

        var childObjects = [String: PointerType]()
        var childFiles = [String: ParseFile]()
        var commands = [API.Command<Self.Element, Self.Element>]()
        let objects = map { $0 }
        for object in objects {
            let (savedChildObjects, savedChildFiles) = try await object
                .ensureDeepSave(
					options: updatedOptions,
					isShouldReturnIfChildObjectsFound: transaction
				)
            try savedChildObjects.forEach {(key, value) in
                guard childObjects[key] == nil else {
                    throw ParseError(code: .otherCause,
                                     message: "Found a circular dependency in ParseObject.")
                }
                childObjects[key] = value
            }
            try savedChildFiles.forEach {(key, value) in
                guard childFiles[key] == nil else {
                    throw ParseError(code: .otherCause,
                                     message: "Found a circular dependency in ParseObject.")
                }
                childFiles[key] = value
            }
            do {
                switch method {
                case .save:
                    commands.append(
                        try await object.saveCommand(ignoringCustomObjectIdConfig: ignoringCustomObjectIdConfig)
                    )
                case .create:
                    commands.append(try await object.createCommand())
                case .replace:
                    commands.append(try object.replaceCommand())
                case .update:
                    commands.append(try object.updateCommand())
                }
            } catch {
                throw error as? ParseError ?? ParseError(swift: error)
            }
        }

		let finalChildObjects = childObjects
		let finalChildFiles = childFiles
		let batchLimit = limit != nil ? limit! : ParseConstants.batchLimit
		try canSendTransactions(transaction, objectCount: commands.count, batchLimit: batchLimit)
		let batches = BatchUtils.splitArray(commands, valuesPerSegment: batchLimit)

		let returnBatch = try await withThrowingTaskGroup(
			of: [Result<Self.Element, ParseError>].self,
			returning: [(Result<Self.Element, ParseError>)].self
		) { group in
			for batch in batches {
				group.addTask {
					try await API.Command<Self.Element, Self.Element>
						.batch(commands: batch, transaction: transaction)
						.execute(
							options: updatedOptions,
							batching: true,
							callbackQueue: callbackQueue,
							childObjects: finalChildObjects,
							childFiles: finalChildFiles
						)
				}
			}
			return try await group.reduce(into: [(Result<Self.Element, ParseError>)]()) { partialResult, batch in
				partialResult.append(contentsOf: batch)
			}
		}

		return returnBatch
    }
}

// MARK: Savable Encodable Version
internal extension ParseEncodable {
    func saveAll(objects: [ParseEncodable],
                 transaction: Bool = configuration.isUsingTransactions,
                 objectsSavedBeforeThisOne: [String: PointerType]?,
                 filesSavedBeforeThisOne: [String: ParseFile]?,
                 options: API.Options = [],
                 callbackQueue: DispatchQueue = .main) async throws -> [(Result<PointerType, ParseError>)] {
        try await API.NonParseBodyCommand<AnyCodable, PointerType>
            .batch(objects: objects,
                   transaction: transaction,
                   objectsSavedBeforeThisOne: objectsSavedBeforeThisOne,
                   filesSavedBeforeThisOne: filesSavedBeforeThisOne)
            .execute(options: options,
                     callbackQueue: callbackQueue)
    }
}
