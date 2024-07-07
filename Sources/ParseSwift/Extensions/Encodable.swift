//
//  Encodable.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/4/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

internal extension Encodable {
    func isEqual(_ other: Encodable?) -> Bool {
        guard let lhsData = try? ParseCoding
            .parseEncoder()
            .encode(
                self,
                acl: nil
            ),
              let other = other,
              let rhsData = try? ParseCoding
            .parseEncoder()
            .encode(
                other,
                acl: nil
            ) else {
            return false
        }
        let lhsString = String(decoding: lhsData, as: UTF8.self)
        let rhsString = String(decoding: rhsData, as: UTF8.self)
        return lhsString == rhsString
    }
}
