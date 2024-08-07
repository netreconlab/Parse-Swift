//
//  ParseHookParametable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 Conforming to `ParseHookParametable` allows types that can be created
 to decode parameters in `ParseHookFunctionRequest`'s.
 */
public protocol ParseHookParametable: ParseTypeable {}
