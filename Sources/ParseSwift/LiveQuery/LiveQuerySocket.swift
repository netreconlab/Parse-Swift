//
//  LiveQuerySocket.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/31/20.
//  Copyright © 2020 Network Reconnaissance Lab. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class LiveQuerySocket: NSObject, @unchecked Sendable {
    private var session: URLSession!
	private let lock = NSLock()
    let tasks = SocketTasks()
	private weak var _authenticationDelegate: LiveQuerySocketDelegate?
	var authenticationDelegate: LiveQuerySocketDelegate? {
		get {
			lock.lock()
			defer { lock.unlock() }
			return _authenticationDelegate
		}
		set {
			lock.lock()
			defer { lock.unlock() }
			_authenticationDelegate = newValue
		}
	}

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
        try await yieldIfNotInitialized()
        let encoded = try ParseCoding.jsonEncoder()
            .encode(await StandardMessage(operation: .connect,
                                          // swiftlint:disable:next line_length
                                          additionalProperties: Parse.configuration.liveQueryConnectionAdditionalProperties))
        let encodedAsString = String(decoding: encoded, as: UTF8.self)
        try await task.send(.string(encodedAsString))
        await self.receive(task)
    }
}

// MARK: Send
extension LiveQuerySocket {
    func send(_ data: Data, task: URLSessionWebSocketTask) async throws {
        let encodedAsString = String(decoding: data, as: UTF8.self)
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
		let delegates = await self.tasks.getDelegates()
		do {

			if task.state == .suspended {
				task.resume()
			}
			let result = try await task.receive()
			await self.tasks.removeReceivers([task])

			switch result {
			case .string(let message):
				if let data = message.data(using: .utf8) {
					await delegates[task]?.received(data)
				} else {
					let parseError = ParseError(
						code: .otherCause,
						message: "Could not encode LiveQuery string as data"
					)
					delegates[task]?.receivedError(parseError)
				}
				await self.receive(task)
			case .data(let data):
				delegates[task]?.receivedUnsupported(data, socketMessage: nil)
				await self.receive(task)
			case let message:
				delegates[task]?.receivedUnsupported(nil, socketMessage: message)
				await self.receive(task)
			}

		} catch {
			await self.tasks.removeReceivers([task])
			delegates[task]?.receivedError(error)
		}
    }
}

// MARK: Ping
extension LiveQuerySocket {

    func sendPing(_ task: URLSessionWebSocketTask, pongReceiveHandler: @escaping @Sendable (Error?) -> Void) {
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

    func urlSession(
		_ session: URLSession,
		didReceive challenge: URLAuthenticationChallenge,
		completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
	) {
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
