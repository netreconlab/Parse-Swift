//
//  ParseBatch.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/1/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

internal struct ParseBatch<T>: ParseOperationable where T: ParseOperationable {
    var __op: ParseOperationCommand = .batch // swiftlint:disable:this identifier_name
    let operations: [T]

    enum CodingKeys: String, CodingKey {
        case __op
        case operations = "ops"
    }
}
