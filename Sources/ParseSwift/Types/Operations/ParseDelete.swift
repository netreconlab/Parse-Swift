//
//  ParseDelete.swift
//  Parse
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2017 Parse. All rights reserved.
//

import Foundation

/**
 An operation that deletes a field.
 */
public struct ParseDelete: ParseOperationable {
    public var __op: ParseOperationCommand = .delete // swiftlint:disable:this identifier_name

    /// Create an instance.
    public init() { }
}
