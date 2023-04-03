//
//  ParseOperationCommand.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/21/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/// Represents all supported Parse operation commands.
public enum ParseOperationCommand: String, Codable {
    /// The add command.
    case add = "Add"
    /// The add relation command.
    case addRelation = "AddRelation"
    /// The add unique command.
    case addUnique = "AddUnique"
    /// The batch command.
    case batch = "Batch"
    /// The delete command.
    case delete = "Delete"
    /// The increment command.
    case increment = "Increment"
    /// The remove command.
    case remove = "Remove"
    /// The remove relation command.
    case removeRelation = "RemoveRelation"
}
