//
//  LiveQuerySocket.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class LiveQuerySocket: NSObject {
    private var session: URLSession!
    var tasks = SocketTasks()
    weak var authenticationDelegate: LiveQuerySocketDelegate?

    override init() {
        super.init()
        session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }

    func createTask(_ url: URL, taskDelegate: LiveQuerySocketDelegate) async -> URLSessionWebSocketTask {
        let task = session.webSocketTask(with: url)
        await tasks.updateDelegates([task: taskDelegate])
        await receive(task)
        return task
    }

    func removeTask(_ task: URLSessionWebSocketTask) async {
        await tasks.removeReceivers([task])
        await tasks.removeDelegates([task])
    }

    func closeAll() async {
        let delegates = await tasks.getDelegates()
        for (_, client) in delegates {
            await client.close()
        }
    }
}

// MARK: Status
extension LiveQuerySocket {
    enum Status: String {
        case open
        case closed
    }
}

// MARK: Connect
extension LiveQuerySocket {
    func connect(_ task: URLSessionWebSocketTask) async throws {
        let encoded = try ParseCoding.jsonEncoder()
            .encode(await StandardMessage(operation: .connect,
                                          additionalProperties: true))
        guard let encodedAsString = String(data: encoded, encoding: .utf8) else {
            throw ParseError(code: .otherCause,
                             message: "Could not encode connect message: \(encoded)")
        }
        try await task.send(.string(encodedAsString))
        await self.receive(task)
    }
}

// MARK: Send
extension LiveQuerySocket {
    func send(_ data: Data, task: URLSessionWebSocketTask) async throws {
        guard let encodedAsString = String(data: data, encoding: .utf8) else {
            throw ParseError(code: .otherCause,
                             message: "Could not encode data as string: \(data)")
        }
        try await task.send(.string(encodedAsString))
    }
}

// MARK: Receive
extension LiveQuerySocket {

    func receive(_ task: URLSessionWebSocketTask) async {
        let receivers = await tasks.getReceivers()
        guard receivers[task] == nil else {
            // Receive has already been called for this task
            return
        }
        await tasks.updateReceivers([task: true])
        task.receive { result in
            Task {
                await self.tasks.removeReceivers([task])
                let delegates = await self.tasks.getDelegates()
                switch result {
                case .success(.string(let message)):
                    if let data = message.data(using: .utf8) {
                        Task {
                            await delegates[task]?.received(data)
                        }
                    } else {
                        let parseError = ParseError(code: .otherCause,
                                                    message: "Could not encode LiveQuery string as data")
                        delegates[task]?.receivedError(parseError)
                    }
                    await self.receive(task)
                case .success(.data(let data)):
                    delegates[task]?.receivedUnsupported(data, socketMessage: nil)
                    await self.receive(task)
                case .success(let message):
                    delegates[task]?.receivedUnsupported(nil, socketMessage: message)
                    await self.receive(task)
                case .failure(let error):
                    delegates[task]?.receivedError(error)
                }
            }
        }
    }
}

// MARK: Ping
extension LiveQuerySocket {

    func sendPing(_ task: URLSessionWebSocketTask, pongReceiveHandler: @escaping (Error?) -> Void) {
        task.sendPing(pongReceiveHandler: pongReceiveHandler)
    }
}

// MARK: URLSession
extension URLSession {
    static let liveQuery = LiveQuerySocket()
}

// MARK: URLSessionWebSocketDelegate
extension LiveQuerySocket: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didOpenWithProtocol protocol: String?) {
        Task {
            let delegates = await tasks.getDelegates()
            await delegates[webSocketTask]?.status(.open,
                                                   closeCode: nil,
                                                   reason: nil)
        }
    }

    func urlSession(_ session: URLSession,
                    webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
                    reason: Data?) {
        Task {
            let delegates = await tasks.getDelegates()
            await delegates[webSocketTask]?.status(.closed,
                                                   closeCode: closeCode,
                                                   reason: reason)
        }
    }

    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if let authenticationDelegate = authenticationDelegate {
            authenticationDelegate.received(challenge: challenge, completionHandler: completionHandler)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

    #if !os(watchOS)
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didFinishCollecting metrics: URLSessionTaskMetrics) {
        if let socketTask = task as? URLSessionWebSocketTask,
           let transactionMetrics = metrics.transactionMetrics.last {
            Task {
                let delegates = await tasks.getDelegates()
                delegates[socketTask]?.received(transactionMetrics)
            }
        }
    }
    #endif
}
#endif
