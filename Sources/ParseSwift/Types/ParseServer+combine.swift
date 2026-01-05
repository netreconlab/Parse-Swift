//
//  ParseServer+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseServer {

    // MARK: Combine

    /**
     Check the server health *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that performs type erasure by wrapping another publisher.
    */
    static func healthPublisher(options: API.Options = []) -> AnyPublisher<Status, ParseError> {
		nonisolated(unsafe) let subject = PassthroughSubject<Status, ParseError>()
        Self.health(options: options) { result in
            switch result {
            case .success(let status):
                subject.send(status)
                if status == .ok ||
                    status == .error {
                    subject.send(completion: .finished)
                }
            case .failure(let error):
                subject.send(completion: .failure(error))
            }
        }
        return subject.eraseToAnyPublisher()
    }

    /**
     Retrieves any information provided by the server *asynchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
    */
    static func informationPublisher(
		options: API.Options = []
	) -> Future<Information, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            Self.information(
				options: options
			) { result in
				switch result {
				case .success(let information):
					promise(.success(information))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

#endif
