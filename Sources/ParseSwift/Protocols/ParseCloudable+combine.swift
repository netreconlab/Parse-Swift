//
//  ParseCloudable+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
import Combine

public extension ParseCloudable {

    // MARK: Combine

    /**
     Calls a Cloud Code function *asynchronously* and returns a result of its execution.
     Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func runFunctionPublisher(
		options: API.Options = []
	) -> Future<ReturnType, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.runFunction(
				options: options
			) { result in
				switch result {
				case .success(let functionReturn):
					promise(.success(functionReturn))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Starts a Cloud Code Job *asynchronously* and returns a result with the jobStatusId of the job.
     Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func startJobPublisher(
		options: API.Options = []
	) -> Future<ReturnType, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.startJob(
				options: options
			) { result in
				switch result {
				case .success(let functionReturn):
					promise(.success(functionReturn))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

#endif
