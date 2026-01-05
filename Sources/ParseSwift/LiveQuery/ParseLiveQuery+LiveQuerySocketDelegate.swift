//
//  ParseLiveQuery+LiveQuerySocketDelegate.swift
//  ParseSwift
//
//  Created by Corey Baker on 12/29/25.
//  Copyright © 2025 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: Delegate
extension ParseLiveQuery: LiveQuerySocketDelegate {

    func status(_ status: LiveQuerySocket.Status,
                closeCode: URLSessionWebSocketTask.CloseCode? = nil,
                reason: Data? = nil) async {
        switch status {

        case .open:
            await self.setStatus(.socketEstablished)
            Task {
                try? await self.open(isUserWantsToConnect: false)
            }
        case .closed:
			self.receiveDelegate?.closedSocket(closeCode, reason: reason)
            await self.setStatus(.socketNotEstablished)
            if !self.isDisconnectedByUser {
                // Try to reconnect
                Task {
                    try? await self.open(isUserWantsToConnect: false)
                }
            }
        }
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    func received(_ data: Data) async {
        if let redirect = try? ParseCoding.jsonDecoder().decode(RedirectResponse.self, from: data) {
            if redirect.op == .redirect {
                self.url = redirect.url
                if self.status == .connected {
                    await self.close()
                    // Try to reconnect
                    try? await self.resumeTask()
                }
            }
            return
        }

        // Check if this is an error response
        if let error = try? ParseCoding.jsonDecoder().decode(ErrorResponse.self, from: data) {
            if !error.reconnect {
                // Treat this as a user disconnect because the server does not want to hear from us anymore
                await self.close()
            }
            guard let parseError = try? ParseCoding.jsonDecoder().decode(ParseError.self, from: data) else {
                // Turn LiveQuery error into ParseError
                let parseError = ParseError(code: .otherCause,
                                            // swiftlint:disable:next line_length
                                            message: "ParseLiveQuery Error: code: \(error.code), message: \(error.message)")
				self.receiveDelegate?.received(parseError)
                return
            }
			self.receiveDelegate?.received(parseError)
            return
        } else if self.status != .connected {
            // Check if this is a connected response
            guard let response = try? ParseCoding.jsonDecoder().decode(ConnectionResponse.self, from: data),
                  response.op == .connected else {
                // If not connected, should not receive anything other than a connection response
                guard let outOfOrderMessage = try? ParseCoding
                        .jsonDecoder()
                        .decode(AnyCodable.self, from: data) else {
                    let error = ParseError(code: .otherCause,
                                           // swiftlint:disable:next line_length
                                           message: "ParseLiveQuery Error: Received message out of order, but could not decode it")
					self.receiveDelegate?.received(error)
                    return
                }
                let error = ParseError(code: .otherCause,
                                       // swiftlint:disable:next line_length
                                       message: "ParseLiveQuery Error: Received message out of order: \(outOfOrderMessage)")
				self.receiveDelegate?.received(error)
                return
            }
            self.clientId = response.clientId
            await self.setStatus(.connected)
        } else {

            if let preliminaryMessage = try? ParseCoding.jsonDecoder()
                        .decode(PreliminaryMessageResponse.self,
                                from: data) {

                if preliminaryMessage.clientId != self.clientId {
                    let error = ParseError(code: .otherCause,
                                           // swiftlint:disable:next line_length
                                           message: "ParseLiveQuery Error: Received a message from a server who sent clientId \(preliminaryMessage.clientId) while it should be \(String(describing: self.clientId)). Not accepting message...")
					self.receiveDelegate?.received(error)
                    return
                }

                if let installationId = try? await BaseParseInstallation.current().installationId {
                    if installationId != preliminaryMessage.installationId {
                        let error = ParseError(code: .otherCause,
                                               // swiftlint:disable:next line_length
                                               message: "ParseLiveQuery Error: Received a message from a server who sent an installationId of \(String(describing: preliminaryMessage.installationId)) while it should be \(installationId). Not accepting message...")
						self.receiveDelegate?.received(error)
                        return
                    }
                }

                let subscriptions = await self.subscriptions.getCurrent()
                let pending = await self.subscriptions.getPending()
                switch preliminaryMessage.op {
                case .subscribed:
                    guard let subscribed = pending
                        .first(where: { $0.0.value == preliminaryMessage.requestId }) else {
                        let error = ParseError(code: .otherCause,
                                               // swiftlint:disable:next line_length
                                               message: "ParseLiveQuery Error: Received a subscription with requestId: \(preliminaryMessage.requestId) from a server, but this is not a pending subscription.")
						self.receiveDelegate?.received(error)
                        return
                    }
                    let requestId = RequestId(value: preliminaryMessage.requestId)
                    let isNew: Bool
                    if subscriptions[requestId] != nil {
                        isNew = false
                    } else {
                        isNew = true
                    }
                    await self.subscriptions.updateCurrent([subscribed.0: subscribed.1])
                    await self.subscriptions.removePending([subscribed.0])
                    self.notificationQueue.async {
                        subscribed.1.subscribeHandlerClosure?(isNew)
                    }
                case .unsubscribed:
                    let requestId = RequestId(value: preliminaryMessage.requestId)
                    guard let subscription = subscriptions[requestId] else {
                        return
                    }
                    await self.subscriptions.removeCurrent([requestId])
                    await self.subscriptions.removePending([requestId])
                    self.notificationQueue.async {
                        subscription.unsubscribeHandlerClosure?()
                    }
                case .create, .update, .delete, .enter, .leave:
                    let requestId = RequestId(value: preliminaryMessage.requestId)
                    guard let subscription = subscriptions[requestId] else {
                        return
                    }
                    self.notificationQueue.async {
                        subscription.eventHandlerClosure?(data)
                    }
                default:
                    let error = ParseError(code: .otherCause,
                                           message: "ParseLiveQuery Error: Hit an undefined state.")
					self.receiveDelegate?.received(error)
                }

            } else {
                let error = ParseError(code: .otherCause,
                                       message: "ParseLiveQuery Error: Hit an undefined state.")
				self.receiveDelegate?.received(error)
            }
        }
    }

	func receivedError(_ error: Error) {
		Task {
			if await !isPosixError(error) {
				if await !isURLError(error) {
					self.receiveDelegate?.received(error)
				}
			}
		}
	}

	func isPosixError(_ error: Error) async -> Bool {
		guard let posixError = error as? POSIXError else {
			self.receiveDelegate?.received(error)
			return false
		}
		if posixError.code == .ENOTCONN {
			await self.setStatus(.socketNotEstablished)
			do {
				try await open(isUserWantsToConnect: false)
			} catch {
				self.receiveDelegate?.received(error)
			}
		} else {
			self.receiveDelegate?.received(error)
		}
		return true
	}

	func isURLError(_ error: Error) async -> Bool {
		guard let urlError = error as? URLError else {
			self.receiveDelegate?.received(error)
			return false
		}
		if [-1001, -1005, -1011].contains(urlError.errorCode) {
			await self.setStatus(.socketNotEstablished)
			do {
				try await open(isUserWantsToConnect: false)
			} catch {
				self.receiveDelegate?.received(error)
			}
		} else {
			self.receiveDelegate?.received(error)
		}
		return true
	}

	func receivedUnsupported(
		_ data: Data?,
		socketMessage: URLSessionWebSocketTask.Message?
	) {
		self.receiveDelegate?.receivedUnsupported(data, socketMessage: socketMessage)
	}

	func received(
		challenge: URLAuthenticationChallenge,

		completionHandler: @escaping @Sendable (
			URLSession.AuthChallengeDisposition,

			URLCredential?
		) -> Void
	) {
		if let delegate = self.authenticationDelegate {
			delegate.received(challenge, completionHandler: completionHandler)
		} else if let parseAuthentication = Parse.sessionDelegate.authentication {
			parseAuthentication(challenge, completionHandler)
		} else {
			completionHandler(.performDefaultHandling, nil)
		}
	}

#if !os(watchOS)
	func received(_ metrics: URLSessionTaskTransactionMetrics) {
		self.receiveDelegate?.received(metrics)
    }
    #endif
}
#endif
