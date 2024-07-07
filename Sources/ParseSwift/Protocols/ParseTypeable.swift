//
//  ParseTypeable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

/**
 A special type that is considered a Parse type.
 */
public protocol ParseTypeable: Codable,
                               Equatable,
                               CustomDebugStringConvertible,
                               CustomStringConvertible {}

// MARK: CustomDebugStringConvertible
extension ParseTypeable {
    public var debugDescription: String {
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self) else {
            return "()"
        }
        let descriptionString = String(decoding: descriptionData, as: UTF8.self)
        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
extension ParseTypeable {
    public var description: String {
        debugDescription
    }
}
