//
//  ParseOperation.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 A `ParseOperation` represents a modification to a value in a `ParseObject`.
 For example, setting, deleting, or incrementing a value are all `ParseOperation`'s.
 `ParseOperation` themselves can be considered to be immutable.
 
 In most cases, you do not need to create an instance of `ParseOperation` directly as it can be
 indirectly created from any `ParseObject` by using the respective `operation` property.
 */
public struct ParseOperation<T>: Savable,
                                 CustomDebugStringConvertible,
                                 CustomStringConvertible where T: ParseObject {

    var target: T
    var operations = [String: Codable]()
    var keysToNull = Set<String>()

    public init(target: T) {
        self.target = target
    }

    /**
     Specifies if this object related to the operation has been saved.
     - returns: Returns **true** if this object is saved, **false** otherwise.
     - throws: An error of `ParseError` type.
     */
    public func isSaved() async throws -> Bool {
        try await target.isSaved()
    }

    /**
     An operation that sets a field's value.
     - Parameters:
        - keyPath: The respective `KeyPath` of the object.
        - value: The value to set the `KeyPath` to.
        - returns: The updated operations.
     - warning: Do not combine operations using this method with other operations that
     do not use this method to **set** all operations. If you need to combine multiple types
     of operations such as: add, increment, forceSet, etc., use
     `func set<W>(_ key: (String, WritableKeyPath<T, W?>), value: W?)`
     instead.
     */
    public func set<W>(_ keyPath: WritableKeyPath<T, W?>,
                       to value: W) throws -> Self where W: Encodable & Equatable {
        guard operations.isEmpty,
              keysToNull.isEmpty else {
            throw ParseError(code: .otherCause,
                             message: """
                                Cannot combine other operations such as: add, increment,
                                forceSet, etc., with this method. Use the \"set\" method that takes
                                the (String, WritableKeyPath) tuple as an argument instead to
                                combine multiple types of operations.
                                """)
        }
        var mutableOperation = self
        mutableOperation.target = mutableOperation.target.set(keyPath, to: value)
        return mutableOperation
    }

    /**
     An operation that sets a field's value if it has changed from its previous value.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - value: The value to set the `KeyPath` to.
        - returns: The updated operations.
     - Note: Set the value to "nil" if you want it to be "null" on the Parse Server.
     */
    public func set<W>(_ key: (String, WritableKeyPath<T, W?>),
                       to value: W?) -> Self where W: Codable & Equatable {
        var mutableOperation = self
        if value == nil &&
            target[keyPath: key.1] != nil {
            mutableOperation.keysToNull.insert(key.0)
            mutableOperation.target[keyPath: key.1] = value
        } else if target[keyPath: key.1] != value {
            mutableOperation.operations[key.0] = value
            mutableOperation.target[keyPath: key.1] = value
        }
        return mutableOperation
    }

    /**
     An operation that force sets a field's value.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - value: The value to set the `KeyPath` to.
        - returns: The updated operations.
     - Note: Set the value to "nil" if you want it to be "null" on the Parse Server.
     */
    public func forceSet<W>(_ key: (String, WritableKeyPath<T, W?>),
                            value: W?) -> Self where W: Codable {
        forceSet(key, to: value)
    }

    /**
     An operation that force sets a field's value.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - value: The value to set the `KeyPath` to.
        - returns: The updated operations.
     - Note: Set the value to "nil" if you want it to be "null" on the Parse Server.
     */
    public func forceSet<W>(_ key: (String, WritableKeyPath<T, W?>),
                            to value: W?) -> Self where W: Codable {
        var mutableOperation = self
        if value != nil {
            mutableOperation.operations[key.0] = value
        } else {
            mutableOperation.keysToNull.insert(key.0)
        }
        mutableOperation.target[keyPath: key.1] = value
        return mutableOperation
    }

    /**
     An operation that increases a numeric field's value by a given amount.
     - Parameters:
        - key: The key of the object.
        - amount: How much to increment/decrement by.
        - returns: The updated operations.
     - note: A field can be incremented/decremented by a positive/negative value.
     */
    public func increment(_ key: String, by amount: Int) -> Self {
        var mutableOperation = self
        mutableOperation.operations[key] = ParseOperationIncrement(amount: amount)
        return mutableOperation
    }

    /**
     An operation that increases a numeric field's value by a given amount.
     - Parameters:
        - key: The key of the object.
        - amount: How much to increment/decrement by.
        - returns: The updated operations.
     - note: A field can be incremented/decremented by a positive/negative value.
     */
    public func increment(_ key: String, by amount: Double) -> Self {
        var mutableOperation = self
        mutableOperation.operations[key] = ParseOperationIncrementDouble(amount: amount)
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field,
     only if it was not already present.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addUnique<W>(_ key: String, objects: [W]) -> Self where W: Codable, W: Hashable {
        var mutableOperation = self
        mutableOperation.operations[key] = ParseOperationAddUnique(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field,
     only if it was not already present.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addUnique<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                             objects: [V]) -> Self where V: Codable, V: Hashable {
        var mutableOperation = self
        mutableOperation.operations[key.0] = ParseOperationAddUnique(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        mutableOperation.target[keyPath: key.1] = Array(Set<V>(values))
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func add<W>(_ key: String, objects: [W]) -> Self where W: Codable {
        var mutableOperation = self
        mutableOperation.operations[key] = ParseOperationAdd(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new element to an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func add<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                       objects: [V]) -> Self where V: Codable {
        var mutableOperation = self
        mutableOperation.operations[key.0] = ParseOperationAdd(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        mutableOperation.target[keyPath: key.1] = values
        return mutableOperation
    }

    /**
     An operation that adds a new relation to an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addRelation<W>(_ key: String, objects: [W]) throws -> Self where W: ParseObject {
        var mutableOperation = self
        mutableOperation.operations[key] = try ParseOperationAddRelation(objects: objects)
        return mutableOperation
    }

    /**
     An operation that adds a new relation to an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func addRelation<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                               objects: [V]) throws -> Self where V: ParseObject {
        var mutableOperation = self
        mutableOperation.operations[key.0] = try ParseOperationAddRelation(objects: objects)
        var values = target[keyPath: key.1] ?? []
        values.append(contentsOf: objects)
        mutableOperation.target[keyPath: key.1] = values
        return mutableOperation
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func remove<W>(_ key: String, objects: [W]) -> Self where W: Codable {
        var mutableOperation = self
        mutableOperation.operations[key] = ParseOperationRemove(objects: objects)
        return mutableOperation
    }

    /**
     An operation that removes every instance of an element from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func remove<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                          objects: [V]) -> Self where V: Codable, V: Hashable {
        var mutableOperation = self
        mutableOperation.operations[key.0] = ParseOperationRemove(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values ?? [])
        objects.forEach {
            set.remove($0)
        }
        mutableOperation.target[keyPath: key.1] = Array(set)
        return mutableOperation
    }

    /**
     An operation that removes every instance of a relation from
     an array field.
     - Parameters:
        - key: The key of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func removeRelation<W>(_ key: String, objects: [W]) throws -> Self where W: ParseObject {
        var mutableOperation = self
        mutableOperation.operations[key] = try ParseOperationRemoveRelation(objects: objects)
        return mutableOperation
    }

    /**
     An operation that removes every instance of a relation from
     an array field.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - objects: The field of objects.
        - returns: The updated operations.
     */
    public func removeRelation<V>(_ key: (String, WritableKeyPath<T, [V]?>),
                                  objects: [V]) throws -> Self where V: ParseObject {
        var mutableOperation = self
        mutableOperation.operations[key.0] = try ParseOperationRemoveRelation(objects: objects)
        let values = target[keyPath: key.1]
        var set = Set<V>(values ?? [])
        objects.forEach {
            set.remove($0)
        }
        mutableOperation.target[keyPath: key.1] = Array(set)
        return mutableOperation
    }

    /**
     An operation that batches an array of operations on a particular field.
     - Parameters:
        - key: The key of the object.
        - operations: The batch of operations to complete on the `key`.
        - returns: The updated operations.
     - warning: The developer must ensure that the respective Parse Server supports the
     set of batch operations and that the operations are compatable with the field type.
     - note: It is known that `ParseOperationAddRelation` and
     `ParseOperationRemoveRelation` are the only two types of operations that
     can be batched together on Parse Server <= 6.0.0.
     */
    public func batch(_ key: String, operations batch: ParseOperationBatch) -> Self {
        var mutableOperation = self
        mutableOperation.operations[key] = batch
        return mutableOperation
    }

    /**
     An operation where a field is deleted from the object.
     - parameter key: The key of the object.
     - returns: The updated operations.
     */
    public func unset(_ key: String) -> Self {
        var mutableOperation = self
        mutableOperation.operations[key] = ParseOperationDelete()
        return mutableOperation
    }

    /**
     An operation where a field is deleted from the object.
     - Parameters:
        - key: A tuple consisting of the key and the respective `KeyPath` of the object.
        - returns: The updated operations.
     */
    public func unset<V>(_ key: (String, WritableKeyPath<T, V?>)) -> Self where V: Codable {
        var mutableOperation = self
        mutableOperation.operations[key.0] = ParseOperationDelete()
        mutableOperation.target[keyPath: key.1] = nil
        return mutableOperation
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: RawCodingKey.self)
        try operations.forEach { key, value in
            let encoder = container.superEncoder(forKey: .key(key))
            try value.encode(to: encoder)
        }
        try keysToNull.forEach { key in
            let encoder = container.superEncoder(forKey: .key(key))
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
}

// MARK: Savable
extension ParseOperation {

    /**
     Saves the operations on the `ParseObject` *asynchronously* and executes the given callback block.

     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter callbackQueue: The queue to return to after completion. Default value of .main.
     - parameter completion: The block to execute.
     It should have the following argument signature: `(Result<T, ParseError>)`.
    */
    public func save(
        options: API.Options = [],
        callbackQueue: DispatchQueue = .main,
        completion: @escaping (Result<T, ParseError>) -> Void
    ) {
        guard target.objectId != nil else {
            let error = ParseError(code: .missingObjectId,
                                   message: "ParseObject is not saved.")
            callbackQueue.async {
                completion(.failure(error))
            }
            return
        }
        guard target.originalData == nil else {
            guard operations.isEmpty,
                  keysToNull.isEmpty else {
                let error = ParseError(code: .otherCause,
                                       message: """
                                            Cannot combine operations with the \"set\" method that uses
                                            just the KeyPath with other operations such as: add, increment,
                                            forceSet, etc., that use the KeyPath and/or key String. Use the
                                            \"set\" method that takes the (String, WritableKeyPath) tuple
                                            as an argument instead to combine multiple types of operations.
                                        """)
                callbackQueue.async {
                    completion(.failure(error))
                }
                return
            }
            target.save(options: options,
                        callbackQueue: callbackQueue,
                        completion: completion)
            return
        }
        Task {
            await self.saveCommand().execute(options: options,
                                             callbackQueue: callbackQueue,
                                             completion: completion)
        }
    }

    func saveCommand() -> API.NonParseBodyCommand<ParseOperation<T>, T> {
        // MARK: Should be switched to ".PATCH" when server supports PATCH.
        API.NonParseBodyCommand(method: .PUT, path: target.endpoint, body: self) {
            try ParseCoding.jsonDecoder().decode(UpdateResponse.self, from: $0).apply(to: self.target)
        }
    }
}

// MARK: ParseOperation
public extension ParseObject {

    /// Create a new operation.
    var operation: ParseOperation<Self> {
        return ParseOperation(target: self)
    }
}

// MARK: CustomDebugStringConvertible
public extension ParseOperation {
    var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self) else {
            return "()"
        }
        let descriptionString = String(decoding: descriptionData, as: UTF8.self)
        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
public extension ParseOperation {
    var description: String {
        debugDescription
    }
}
