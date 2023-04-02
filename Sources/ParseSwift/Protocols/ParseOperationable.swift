//
//  ParseOperationable.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/1/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/// A protocol that allows a type to be a Parse operation.
public protocol ParseOperationable: Codable,
                                    CustomDebugStringConvertible,
                                    CustomStringConvertible {
    /// The operation command for this operation.
    var __op: ParseOperationCommand { get } // swiftlint:disable:this identifier_name
}

// MARK: CustomDebugStringConvertible
public extension ParseOperationable {
    var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "()"
        }

        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
public extension ParseOperationable {
    var description: String {
        debugDescription
    }
}
