//
//  ParseIncrementDouble.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/1/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 An operation that increments a field.
 - note: A field can be incremented/decremented by a positive/negative value.
 */
public struct ParseIncrementDouble: ParseOperationable {
    public var __op: ParseOperationCommand = .increment // swiftlint:disable:this identifier_name
    /// The amount to increment/decrement by.
    var amount: Double

    /**
     Create an instance with an array of `ParseObject`'s.
     - parameter amount: The amount to increment/decrement by.
     */
    public init(amount: Double) {
        self.amount = amount
    }
}
