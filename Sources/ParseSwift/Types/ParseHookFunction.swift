//
//  ParseHookFunction.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/23/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 A generic Parse Hook Function type that can be used to create any Parse Hook Function.
 */
public struct ParseHookFunction: ParseHookFunctionable {
    public var functionName: String?
    public var url: URL?

    public init() {}
}
