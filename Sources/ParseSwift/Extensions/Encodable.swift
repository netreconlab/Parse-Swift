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
              let lhsString = String(data: lhsData, encoding: .utf8),
              let other = other,
              let rhsData = try? ParseCoding
            .parseEncoder()
            .encode(
                other,
                acl: nil
            ),
              let rhsString = String(
                data: rhsData,
                encoding: .utf8
              ) else {
            return false
        }
        return lhsString == rhsString
    }
}
