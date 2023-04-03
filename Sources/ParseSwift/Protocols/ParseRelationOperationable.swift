//
//  ParseRelationOperationable.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/1/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

public protocol ParseRelationOperationable: ParseOperationable {
    associatedtype Object: ParseObject
    var __op: ParseOperationCommand { get set } // swiftlint:disable:this identifier_name
    var objects: [Pointer<Object>] { get set }
}
