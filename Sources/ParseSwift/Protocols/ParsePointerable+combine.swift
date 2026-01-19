//
//  ParsePointerable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/8/24.
//  Copyright © 2024 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import Combine

// MARK: Batch Support
public extension Sequence where Element: ParsePointerObject {

    /**
     Fetches a collection of objects *aynchronously* with the current data from the server and sets
     an error if one occurs. Publishes when complete.
     - parameter includeKeys: The name(s) of the key(s) to include that are
     `ParseObject`s. Use `["*"]` to include all keys one level deep. This is similar to `include` and
     `includeAll` for `Query`.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces an an array of Result enums with the object if a fetch was
     successful or a `ParseError` if it failed.
    */
    func fetchAllPublisher(
        includeKeys: [String]? = nil,
        options: API.Options = []
	) -> Future<[(Result<Self.Element.Object, ParseError>)], ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetchAll(
                includeKeys: includeKeys,
                options: options
            ) { result in
				switch result {
				case .success(let object):
					promise(.success(object))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

}

#endif
