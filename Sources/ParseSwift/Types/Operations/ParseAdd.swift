//
//  ParseAdd.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 An operation that adds new objects to an array field.
 */
public struct ParseAdd<T>: ParseOperationable where T: Encodable {
    public var __op: ParseOperationCommand = .add // swiftlint:disable:this identifier_name
    /// The array of objects related to the operation.
    public var objects: [T]

    /**
     Create an instance with an array of `ParseObject`'s.
     - parameter objects: The array of `ParseObject`'s.
     */
    public init(objects: [T]) {
        self.objects = objects
    }
}
