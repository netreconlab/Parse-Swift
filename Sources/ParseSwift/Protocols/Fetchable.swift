//
//  Fetchable.swift
//  ParseSwift
//
//  Created by Florent Vilmart on 17-07-24.
//  Copyright © 2020 Parse. All rights reserved.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

public protocol Fetchable: Decodable {
    associatedtype FetchingType

    func fetch(includeKeys: [String]?, options: API.Options) async throws -> FetchingType
    func fetch() async throws -> FetchingType
}

public extension Fetchable {
    func fetch() async throws -> FetchingType {
        try await fetch(includeKeys: nil, options: [])
    }
}
