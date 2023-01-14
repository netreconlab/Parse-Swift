//
//  ParseTypeable.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/19/22.
//  Copyright © 2022 Parse Community. All rights reserved.
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
        guard let descriptionData = try? ParseCoding.jsonEncoder().encode(self),
            let descriptionString = String(data: descriptionData, encoding: .utf8) else {
                return "()"
        }

        return "\(descriptionString)"
    }
}

// MARK: CustomStringConvertible
extension ParseTypeable {
    public var description: String {
        debugDescription
    }
}

extension ParseTypeable {
    static func createSynchronizationQueue(_ label: String) -> DispatchQueue {
        DispatchQueue(label: "parse.\(label).\(UUID().uuidString)",
                      qos: .default,
                      attributes: .concurrent,
                      autoreleaseFrequency: .inherit,
                      target: nil)
    }
}
