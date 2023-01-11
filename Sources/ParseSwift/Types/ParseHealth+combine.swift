//
//  ParseHealth+combine.swift
//  ParseHealth+combine
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseHealth {

    // MARK: Combine

    /**
     Calls the health check function *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    static func checkPublisher(options: API.Options = []) -> AnyPublisher<Status, ParseError> {
        let subject = PassthroughSubject<Status, ParseError>()
        Self.check(options: options) { result in
            switch result {
            case .success(let status):
                subject.send(status)
                if status == .ok {
                    subject.send(completion: .finished)
                }
            case .failure(let error):
                subject.send(completion: .failure(error))
            }
        }
        return subject.eraseToAnyPublisher()
    }
}

#endif
