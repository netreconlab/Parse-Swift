//
//  AnyHashable.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/28/25.
//

import Foundation

#if compiler(>=6.0)
extension AnyHashable: @unchecked @retroactive Sendable {}
#else
extension AnyHashable: @unchecked Sendable {}
#endif
