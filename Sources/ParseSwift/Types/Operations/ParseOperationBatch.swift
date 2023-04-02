//
//  ParseOperationBatch.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/1/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 An operation that batches multiple operations on a field.
 - warning: The developer must ensure that the respective Parse Server supports the
 set of batch operations and that the operations are compatable with the field type.
 - note: It is known that `ParseOperationAddRelation` and
 `ParseOperationRemoveRelation` are the only two types of operations that
 can be batched together on Parse Server <= 6.0.0.
 */
public struct ParseOperationBatch: ParseOperationable {
    public var __op: ParseOperationCommand = .batch // swiftlint:disable:this identifier_name
    internal var operations: [AnyCodable]

    /**
     Create an instance with an array of `ParseOperationable` operations of the same type.
     - parameter operations: The array of `ParseOperationable` operations to batch.
     - note: To append `ParseOperationable` operations of a different type, use `appendOperations()`
     after creating an instance of `ParseOperationBatch`.
     */
    public init<T>(operations: [T]) where T: ParseOperationable {
        self.operations = operations.map { AnyCodable($0) }
    }

    /**
     Append an array of `ParseOperationable` operations.
     - parameter operations: The array of `ParseOperationable` operations to append.
     - returns: An instance of `ParseOperationBatch` for easy chaining.
     - note: The respective type of `ParseOperationable` has to be consistant per unique call
     of `appendOperations()` (basically the array cannot be mixed). To append
     `ParseOperationable` operations of a different type, call `appendOperations()` for each type.
     */
    public func appendOperations<T>(operations: [T]) -> Self where T: ParseOperationable {
        var mutableBatch = self
        mutableBatch.operations.append(contentsOf: operations.map { AnyCodable($0) })
        return mutableBatch
    }

    enum CodingKeys: String, CodingKey {
        case __op
        case operations = "ops"
    }
}
