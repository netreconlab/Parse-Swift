//
//  ParsePointerable+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/8/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

// MARK: Batch Support
public extension Sequence where Element: ParsePointerObject {

    /**
     Fetches a collection of objects *aynchronously* with the current data from the server and sets
     an error if one occurs.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: Returns an array of Result enums with the object if a fetch was successful or a
     `ParseError` if it failed.
     - throws: An error of type `ParseError`.
    */
    @discardableResult func fetchAll(
        includeKeys: [String]? = nil,
        options: API.Options = []
    ) async throws -> [(Result<Self.Element.Object, ParseError>)] {
        try await withCheckedThrowingContinuation { continuation in
            self.fetchAll(
                includeKeys: includeKeys,
                options: options,
                completion: { continuation.resume(with: $0) }
            )
        }
    }

}
