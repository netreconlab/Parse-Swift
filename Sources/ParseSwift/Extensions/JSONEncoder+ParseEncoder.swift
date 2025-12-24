//
//  JSONEncoder+ParseEncoder.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/22/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// swiftlint:disable line_length

#if canImport(Darwin)
extension JSONEncoder: @retroactive @unchecked Sendable {} // JSONEncoder Sendable conformance is not available before macOS 13.0/iOS 16.0/watchOS 9.0/tvOS 16.0 16.0
#endif
