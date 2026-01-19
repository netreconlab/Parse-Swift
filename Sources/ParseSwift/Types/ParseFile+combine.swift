//
//  ParseFile+combine.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Combine

public extension ParseFile {

    // MARK: Combine
    /**
     Fetches a file with given url *synchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetch(
				options: options
			) { result in
				switch result {
				case .success(let file):
					promise(.success(file))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Fetches a file with given url *synchronously*. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it is progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     - note: The default cache policy for this method is `.reloadIgnoringLocalCacheData`. If a developer
     desires a different policy, it should be inserted in `options`.
    */
    func fetchPublisher(
		options: API.Options = [],
		progress: @escaping ((URLSessionDownloadTask,
                                              Int64, Int64, Int64) -> Void)
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.fetch(
				options: options
			) { result in
				switch result {
				case .success(let file):
					promise(.success(file))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     Publishes when complete.
     A name will be assigned to it by the server. If the file has not been downloaded, it will automatically
     be downloaded before saved.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
    */
    func savePublisher(
		options: API.Options = []
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.save(
				options: options
			) { result in
				switch result {
				case .success(let file):
					promise(.success(file))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Creates a file with given data *asynchronously* and executes the given callback block.
     A name will be assigned to it by the server. If the file has not been downloaded, it will automatically
     be downloaded before saved. Publishes when complete.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - parameter progress: A block that will be called when file updates it is progress.
     It should have the following argument signature: `(task: URLSessionDownloadTask,
     bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)`.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func savePublisher(
		options: API.Options = [],
		progress: (@Sendable (URLSessionTask, Int64, Int64, Int64) -> Void)? = nil
	) -> Future<Self, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.save(
				options: options,
				progress: progress
			) { result in
				switch result {
				case .success(let file):
					promise(.success(file))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }

    /**
     Deletes the file from the Parse Server. Publishes when complete.
     - requires: `.usePrimaryKey` has to be available. It is recommended to only
     use the primary key in server-side applications where the key is kept secure and not
     exposed to the public.
     - parameter options: A set of header options sent to the server. Defaults to an empty set.
     - returns: A publisher that eventually produces a single value and then finishes or fails.
     */
    func deletePublisher(
		options: API.Options = []
	) -> Future<Void, ParseError> {
        Future { promise in
			nonisolated(unsafe) let promise = promise
            self.delete(
				options: options
			) { result in
				switch result {
				case .success:
					promise(.success(()))
				case .failure(let error):
					promise(.failure(error))
				}
			}
        }
    }
}

#endif
