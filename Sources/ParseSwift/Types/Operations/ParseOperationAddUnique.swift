//
//  ParseOperationAddUnique.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 An operation that adds unique objects to an array field.
 */
public struct ParseOperationAddUnique<T>: ParseOperationable where T: Codable & Hashable {
    public var __op: ParseOperationCommand = .addUnique // swiftlint:disable:this identifier_name
    /// The array of objects related to the operation.
    public var objects: Set<T>

    /**
     Create an instance with an array of `ParseObject`'s.
     - parameter objects: The array of objects to add.
     */
    public init(objects: [T]) {
        self.objects = Set(objects)
    }
}
