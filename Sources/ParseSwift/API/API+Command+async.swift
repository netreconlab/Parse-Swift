//
//  API+Command+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/17/22.
//  Copyright © 2022 Parse Community. All rights reserved.
//

#if compiler(>=5.5.2) && canImport(_Concurrency)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API.Command {
    // MARK: Asynchronous Execution
    func execute(options: API.Options,
                 batching: Bool = false,
                 callbackQueue: DispatchQueue,
                 notificationQueue: DispatchQueue? = nil,
                 childObjects: [String: PointerType]? = nil,
                 childFiles: [UUID: ParseFile]? = nil,
                 allowIntermediateResponses: Bool = false,
                 uploadProgress: ((URLSessionTask, Int64, Int64, Int64) -> Void)? = nil,
                 downloadProgress: ((URLSessionDownloadTask, Int64, Int64, Int64) -> Void)? = nil) async throws -> U {
        try await withCheckedThrowingContinuation { continuation in
            self.executeAsync(options: options,
                              batching: batching,
                              callbackQueue: callbackQueue,
                              notificationQueue: notificationQueue,
                              childObjects: childObjects,
                              childFiles: childFiles,
                              allowIntermediateResponses: allowIntermediateResponses,
                              uploadProgress: uploadProgress,
                              downloadProgress: downloadProgress,
                              completion: continuation.resume)
        }
    }
}
#endif
