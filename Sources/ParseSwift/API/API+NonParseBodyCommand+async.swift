//
//  API+NonParseBodyCommand+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/17/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension API.NonParseBodyCommand {
    // MARK: Asynchronous Execution
    func execute(options: API.Options,
                 callbackQueue: DispatchQueue,
                 allowIntermediateResponses: Bool = false) async throws -> U {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                await self.execute(options: options,
                                   callbackQueue: callbackQueue,
                                   allowIntermediateResponses: allowIntermediateResponses,
                                   completion: { continuation.resume(with: $0) })
            }
        }
    }
}
