//
//  ParseOperationIncrement.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 An operation that increments a field.
 - note: A field can be incremented/decremented by a positive/negative value.
 */
public struct ParseOperationIncrement: ParseOperationable {
    public var __op: ParseOperationCommand = .increment // swiftlint:disable:this identifier_name
    /// The amount to increment/decrement by.
    var amount: Int

    /**
     Create an instance with an array of `ParseObject`'s.
     - parameter amount: The amount to increment/decrement by.
     */
    public init(amount: Int) {
        self.amount = amount
    }
}
