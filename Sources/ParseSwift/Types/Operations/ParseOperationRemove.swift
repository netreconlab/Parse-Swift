//
//  ParseOperationRemove.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 An operation that removes a set of objects from a field.
 */
public struct ParseOperationRemove<T>: ParseOperationable where T: Codable & Sendable {
    public var __op: ParseOperationCommand = .remove // swiftlint:disable:this identifier_name
    /// The array of objects related to the operation.
    public let objects: [T]

    /**
     Create an instance with an array of objects.
     - parameter objects: The array of objects to remove.
     */
    public init(objects: [T]) {
        self.objects = objects
    }
}
