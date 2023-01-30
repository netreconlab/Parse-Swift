//
//  LiveQuerySocket+async.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/29/23.
//  Copyright © 2023 Network Reconnaissance Lab. All rights reserved.
//

import Foundation

extension LiveQuerySocket {
    // MARK: Connection - Async/Await

    func connect(_ task: URLSessionWebSocketTask) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            self.connect(task) { error in
                guard let error = error else {
                    continuation.resume(with: .success(()))
                    return
                }
                continuation.resume(with: .failure(error))
            }
        }
    }

    func send(_ data: Data, task: URLSessionWebSocketTask) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            self.send(data, task: task) { error in
                guard let error = error else {
                    continuation.resume(with: .success(()))
                    return
                }
                continuation.resume(with: .failure(error))
            }
        }
    }
}
