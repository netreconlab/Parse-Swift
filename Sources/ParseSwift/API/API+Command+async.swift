//
//  API+Command+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/17/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

internal extension API.Command {

    // MARK: URL Preperation
    func prepareURLRequest(options: API.Options,
                           batching: Bool = false,
                           childObjects: [String: PointerType]? = nil,
                           childFiles: [UUID: ParseFile]? = nil) async -> Result<URLRequest, ParseError> {
        await withCheckedContinuation { continuation in
            self.prepareURLRequest(options: options,
                                         batching: batching,
                                         childObjects: childObjects,
                                         childFiles: childFiles,
                                         completion: continuation.resume)
        }
    }

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
            Task {
                await self.execute(options: options,
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
}
