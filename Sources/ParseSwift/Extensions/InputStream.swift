//
//  InputStream.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/10/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension InputStream: @unchecked @retroactive Sendable {}
