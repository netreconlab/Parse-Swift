//
//  ParseAddRelation.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/17/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 An operation that adds new relations to an array field.
 */
public struct ParseAddRelation<T>: ParseRelationOperationable where T: ParseObject {
    public var __op: ParseOperationCommand = .addRelation // swiftlint:disable:this identifier_name
    /// The array of `ParseObject` pointers related to the operation.
    public var objects: [Pointer<T>]

    /**
     Create an instance with an array of `ParseObject`'s.
     - parameter objects: The array of `ParseObject`'s to add.
     */
    public init(objects: [T]) throws {
        self.objects = try objects.compactMap { try $0.toPointer() }
    }
}
