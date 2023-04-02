//
//  ParseOperationable.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/1/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/// A protocol that allows a type to be a Parse operation.
public protocol ParseOperationable: Encodable {
    /// The operation command for this operation.
    var __op: ParseOperationCommand { get } // swiftlint:disable:this identifier_name
}
