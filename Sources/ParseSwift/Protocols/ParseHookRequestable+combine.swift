//
//  ParseHookRequestable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/14/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine) && compiler(<6.0.0)
import Foundation
import Combine

public extension ParseHookRequestable {
    /**
     Fetches the complete `ParseUser`. Publishes when complete.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
	@available(*, deprecated, message: "Use async await instead. Will be removed in version 7.0.0.")
    func hydrateUserPublisher(options: API.Options = []) -> Future<Self, ParseError> {
        Future { promise in
            self.hydrateUser(options: options, completion: promise)
        }
    }
}
#endif
