//
//  ParseLiveQuery.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/2/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/**
 The `ParseLiveQuery` class enables two-way communication to a Parse Live Query
 Server.
 
 In most cases, you should not call this class directly as a LiveQuery can be indirectly
 created from `Query` using:
 ```swift
 // If "Message" is a "ParseObject"
 let myQuery = Message.query("from" == "parse")
 guard let subscription = try await myQuery.subscribe() else {
     "Error subscribing..."
     return
 }
 subscription.handleSubscribe { subscribedQuery, isNew in

     //Handle the subscription however you like.
     if isNew {
         print("Successfully subscribed to new query \(subscribedQuery)")
     } else {
         print("Successfully updated subscription to new query \(subscribedQuery)")
     }
 }
 ```
 The above creates a `ParseLiveQuery` using either the `liveQueryServerURL` (if it has been set)
 or `serverURL` when using `ParseSwift.initialize`. All additional queries will be
 created in the same way. The times you will want to initialize a new `ParseLiveQuery` instance
 are:
 1. If you want to become a `ParseLiveQueryDelegate` to respond to authentification challenges
 and/or receive metrics and error messages for a `ParseLiveQuery`client.
 2. You have specific LiveQueries that need to subscribe to a server that have a different url than
 the default.
 3. You want to change the default url for all LiveQuery connections when the app is already
 running. Initializing new instances will create a new task/connection to the `ParseLiveQuery` server.
 When an instance is deinitialized it will automatically close it is connection gracefully.
 */
public class ParseLiveQuery: NSObject, @unchecked Sendable {

    /// Have all `ParseLiveQuery` authentication challenges delegated to you. There can only
    /// be one of these for all `ParseLiveQuery` connections. The default is to
    /// delegate to the `authentication` call block passed to `ParseSwift.initialize`
    /// or if there is not one, delegate to the OS. Conforms to `ParseLiveQueryDelegate`.
    public var authenticationDelegate: ParseLiveQueryDelegate? {
		get {
			authenticationLock.lock()
			defer { authenticationLock.unlock() }
			return _authenticationDelegate
		}
		set {
			authenticationLock.lock()
			defer { authenticationLock.unlock() }
			_authenticationDelegate = newValue
			if newValue != nil {
				URLSession.liveQuery.authenticationDelegate = self
			} else {
				if let delegate = URLSession.liveQuery.authenticationDelegate as? ParseLiveQuery {
					if delegate == self {
						URLSession.liveQuery.authenticationDelegate = nil
					}
				}
			}
		}
    }

    /// Have `ParseLiveQuery` connection metrics, errors, etc delegated to you. A delegate
    /// can be assigned to individual connections. Conforms to `ParseLiveQueryDelegate`.
	public var receiveDelegate: ParseLiveQueryDelegate? {
		get {
			receiveLock.lock()
			defer { receiveLock.unlock() }
			return _receiveDelegate
		}
		set {
			receiveLock.lock()
			defer { receiveLock.unlock() }
			_receiveDelegate = newValue
		}
	}

    /// The connection status of LiveQuery
    public enum ConnectionStatus: Comparable {
        /// The socket is not established.
        case socketNotEstablished
        /// The socket is established, but neither connecting or connected.
        case socketEstablished
        /// The socket is currently disconnected.
        case disconnected
        /// The socket is currently connecting.
        case connecting
        /// The socket is currently connected.
        case connected

        public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs == .socketNotEstablished && rhs != .socketNotEstablished ||
            lhs == .socketEstablished && (rhs != .socketEstablished && rhs != .socketNotEstablished) ||
            // swiftlint:disable:next line_length
            lhs == .disconnected && (rhs != .disconnected && rhs != .socketEstablished && rhs != .socketNotEstablished) ||
            // swiftlint:disable:next line_length
            lhs == .connecting && (rhs != .connecting && rhs != .disconnected && rhs != .socketEstablished && rhs != .socketNotEstablished)
        }
    }

	/// The current status of the LiveQuery socket.
	public internal(set) var status: ConnectionStatus = .socketNotEstablished
	/// Current LiveQuery client.
	nonisolated(unsafe) public private(set) static var client: ParseLiveQuery?

	private let authenticationLock = NSLock()
	private let receiveLock = NSLock()
	private weak var _authenticationDelegate: ParseLiveQueryDelegate?
	private weak var _receiveDelegate: ParseLiveQueryDelegate?
	nonisolated(unsafe) static var isConfiguring: Bool = false

    let notificationQueue: DispatchQueue
    var task: URLSessionWebSocketTask!
    var url: URL!
    var clientId: String!
    var attempts: Int = 1 {
        willSet {
            if newValue >= Parse.configuration.liveQueryMaxConnectionAttempts + 1 &&
                !Parse.configuration.isTestingLiveQueryDontCloseSocket {
                let error = ParseError(code: .otherCause,
                                       message: """
ParseLiveQuery Error: Reached max attempts of
\(Parse.configuration.liveQueryMaxConnectionAttempts).
Not attempting to open ParseLiveQuery socket anymore
""")

				self.receiveDelegate?.received(error)

                Task {
                    await close() // Quit trying to reconnect
                }
            }
        }
    }
    var isDisconnectedByUser = false
    let subscriptions = Subscriptions()

    /**
     - parameter serverURL: The URL of the `ParseLiveQuery` Server to connect to.
     Defaults to `nil` in which case, it will use the URL passed in
     `ParseSwift.initialize(...liveQueryServerURL: URL)`. If no URL was passed,
     this assumes the current Parse Server URL is also the LiveQuery server.
     - parameter isDefault: Set this `ParseLiveQuery` client as the default client for all LiveQuery connections.
     Defaults value of false.
     - parameter notificationQueue: The queue to return to for all delegate notifications. Default value of .main.
	 */
    public init(
		serverURL: URL? = nil,
		isDefault: Bool = false,
		notificationQueue: DispatchQueue = .main
	) async throws {
        self.notificationQueue = notificationQueue
		super.init()
        if let serverURL = serverURL {
            url = serverURL
        } else if let liveQueryConfigURL = Parse.configuration.liveQuerysServerURL {
            url = liveQueryConfigURL
        } else {
            url = Parse.configuration.serverURL
        }

        guard var components = URLComponents(url: url,
                                             resolvingAgainstBaseURL: false) else {
            let error = ParseError(code: .otherCause,
                                   message: "ParseLiveQuery Error: Could not create components from url: \(url!)")
			throw error
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        components.percentEncodedQuery = components.percentEncodedQuery?
            .replacingOccurrences(
                of: "+",
                with: "%2B"
            )
        url = components.url
        self.task = await URLSession.liveQuery.createTask(
			self.url,
			taskDelegate: self
		)
        try await self.resumeTask()
        if isDefault {
            Self.defaultClient = self
            Self.isConfiguring = false
        }
    }

    /// Gracefully disconnects from the ParseLiveQuery Server.
    deinit {
        _authenticationDelegate = nil
        _receiveDelegate = nil
        if Self.client == self {
            Self.isConfiguring = false
        }
    }

    static func yieldIfNotConfigured() async {
        guard !isConfiguring else {
            await Task.yield()
            await yieldIfNotConfigured()
            return
        }
    }

    static func configure() async throws {
        guard Self.client == nil else {
            return
        }
        guard !isConfiguring else {
            await yieldIfNotConfigured()
            return
        }
        isConfiguring = true
        try await yieldIfNotInitialized()
        Self.defaultClient = try await ParseLiveQuery(isDefault: true)
    }

    static func client() async throws -> ParseLiveQuery {
        try await configure()
        guard let client = Self.client else {
            throw ParseError(code: .otherCause, message: "Missing LiveQuery client")
        }
        return client
    }

    func setStatus(_ status: ConnectionStatus) async {
        switch status {
        case .socketNotEstablished:
            clientId = nil
            self.status = .socketNotEstablished
        case .socketEstablished:
            self.status = .socketEstablished
        case .disconnected:
            clientId = nil
            if status >= self.status {
                self.status = status
            } else {
                self.status = .socketNotEstablished
            }
        case .connecting:
            if status >= self.status {
                self.status = status
            } else {
                self.status = .socketNotEstablished
            }
        case .connected:
            if status >= self.status,
               let task = self.task {
                attempts = 1

                // Resubscribe to all subscriptions by moving them in front of pending
                var tempPendingSubscriptions = [(RequestId, SubscriptionRecord)]()
                let subscriptions = await self.subscriptions.getCurrent()
                subscriptions.forEach { (key, value) in
                    tempPendingSubscriptions.append((key, value))
                }
                await self.subscriptions.removeAll()
                let pending = await self.subscriptions.getPending()
                tempPendingSubscriptions.append(contentsOf: pending)
                await self.subscriptions.removeAllPending()
                await self.subscriptions.updatePending(tempPendingSubscriptions)

                // Send all pending messages in order
                for tempPendingSubscription in tempPendingSubscriptions {
                    let messageToSend = tempPendingSubscription
                    Task {
                        try? await URLSession.liveQuery.send(messageToSend.1.messageData, task: task)
                    }
                }
                self.status = status
            } else {
                self.status = .socketNotEstablished
            }
        }
    }
}

// MARK: Client Intents
extension ParseLiveQuery {

    func resumeTask() async throws {
        switch self.task.state {
        case .suspended:
            await URLSession.liveQuery.receive(task)
            self.task.resume()
        case .completed, .canceling:
            let oldTask = self.task
            self.task = await URLSession.liveQuery.createTask(
				self.url,
				taskDelegate: self
			)
            self.task.resume()
            if let oldTask = oldTask {
                await URLSession.liveQuery.removeTask(oldTask)
            }
        case .running:
            try await self.open(isUserWantsToConnect: false)
        @unknown default:
            break
        }
    }

    func removePendingSubscription(_ requestId: Int) async {
        await subscriptions.removePending([RequestId(value: requestId)])
        await closeWebsocketIfNoSubscriptions()
    }

    func closeWebsocketIfNoSubscriptions() async {
        let isEmpty = await self.subscriptions.isEmpty()
        let isPendingEmpty = await self.subscriptions.isPendingEmpty()
        if isEmpty && isPendingEmpty {
            await self.close()
        }
    }

    /// The default `ParseLiveQuery` client for all LiveQuery connections.
	static public var defaultClient: ParseLiveQuery? {
        get {
            Self.client
        }
        set {
            Self.client = nil
            Self.client = newValue
        }
    }

    /// Check if a query has an active subscription on this `ParseLiveQuery` client.
    /// - parameter query: Query to verify.
    /// - returns: **true** if subscribed. **false** otherwise.
    /// - throws: An error of type `ParseError`.
    public func isSubscribed<T: ParseObject>(_ query: Query<T>) async throws -> Bool {
        let queryData = try ParseCoding.jsonEncoder().encode(query)
        let subscriptions = await self.subscriptions.getCurrent()
        return subscriptions.contains(where: { (_, value) -> Bool in
            if queryData == value.queryData {
                return true
            } else {
                return false
            }
        })
    }

    /// Check if a query has a pending subscription on this `ParseLiveQuery` client.
    /// - parameter query: Query to verify.
    /// - returns: **true** if query is a pending subscription. **false** otherwise.
    /// - throws: An error of type `ParseError`.
    public func isPendingSubscription<T: ParseObject>(_ query: Query<T>) async throws -> Bool {
        let queryData = try ParseCoding.jsonEncoder().encode(query)
        let pending = await self.subscriptions.getPending()
        return pending.contains(where: { (_, value) -> Bool in
            if queryData == value.queryData {
                return true
            } else {
                return false
            }
        })
    }

    /// Remove a pending subscription on this `ParseLiveQuery` client.
    /// - parameter query: Query to remove.
    /// - throws: An error of type `ParseError`.
    public func removePendingSubscription<T: ParseObject>(_ query: Query<T>) async throws {
        let queryData = try ParseCoding.jsonEncoder().encode(query)
        let pending = await self.subscriptions.getPending()
        let pendingToRemove = pending.compactMap { (requestId, value) -> RequestId? in
            if queryData == value.queryData {
                return requestId
            } else {
                return nil
            }
        }
        await self.subscriptions.removePending(pendingToRemove)
        await self.closeWebsocketIfNoSubscriptions()
    }
}

// MARK: Connection
extension ParseLiveQuery {

    /// Manually establish a connection to the `ParseLiveQuery` Server.
    /// - parameter isUserWantsToConnect: Specifies if the user is calling this function. Defaults to **true**.
    /// - parameter completion: Returns `nil` if successful, an `Error` otherwise.
    public func open(isUserWantsToConnect: Bool = true,
                     completion: @escaping @Sendable (Error?) -> Void) {
        if isUserWantsToConnect {
            self.isDisconnectedByUser = false
        }
        if self.status == .connected ||
            self.isDisconnectedByUser {
            completion(nil)
            return
        }
        if self.status == .connecting {
            completion(nil)
            return
        }

        if self.status == .socketEstablished {
            Task {
                do {
                    try await URLSession.liveQuery.connect(self.task)
                    await self.setStatus(.connecting)
                    completion(nil)
                } catch {
                    completion(error)
                }
                return
            }
        } else {
            self.attempts += 1
            Task {
                let nanoSeconds = UInt64(Utility.reconnectInterval(attempts) * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoSeconds)

                try? await self.resumeTask()
                let error = ParseError(code: .otherCause,
                                       // swiftlint:disable:next line_length
                                       message: "ParseLiveQuery Error: attempted to open socket \(self.attempts) time(s)")
                completion(error)
            }
        }
    }

    /// Manually disconnect from the `ParseLiveQuery` Server.
    public func close() async {
        if self.status == .connected {
            self.task.cancel(with: .goingAway, reason: nil)
            self.isDisconnectedByUser = true
            let oldTask = self.task
            await self.setStatus(.socketNotEstablished)
            // Prepare new task for future use.
            self.task = await URLSession.liveQuery.createTask(
				self.url,
				taskDelegate: self
			)
            if let oldTask = oldTask {
                await URLSession.liveQuery.removeTask(oldTask)
            }
        }
    }

    /// Manually disconnect all sessions and subscriptions from the `ParseLiveQuery` Server.
    public func closeAll() async {
        await URLSession.liveQuery.closeAll()
    }

    /**
     Sends a ping frame from the client side, with a closure to receive the pong from the server endpoint.
     - parameter pongReceiveHandler: A closure called by the task when it receives the pong
     from the server. The closure receives an  `Error` that indicates a lost connection or other problem,
     or nil if no error occurred.
     */
    public func sendPing(pongReceiveHandler: @escaping @Sendable (Error?) -> Void) {
        if self.task.state == .running {
            URLSession.liveQuery.sendPing(task, pongReceiveHandler: pongReceiveHandler)
        } else {
            let error = ParseError(code: .otherCause,
                                   // swiftlint:disable:next line_length
                                   message: "ParseLiveQuery Error: socket status needs to be \"\(URLSessionTask.State.running.rawValue)\" before pinging server. Current status is \"\(self.task.state.rawValue)\". Try calling \"open()\" to change socket status.")
            pongReceiveHandler(error)
        }
    }

    func send(record: SubscriptionRecord, requestId: RequestId) async throws {
        await self.subscriptions.updatePending([(requestId, record)])
        Task {
            if self.status == .connected {
                try? await URLSession.liveQuery.send(record.messageData, task: self.task)
            } else {
                try await self.open()
            }
        }
    }
}

// MARK: SubscriptionRecord
extension ParseLiveQuery {
    struct SubscriptionRecord: Equatable, @unchecked Sendable {

        var messageData: Data
        var queryData: Data
        var subscriptionHandler: AnyObject
        var eventHandlerClosure: ((Data) -> Void)?
        var subscribeHandlerClosure: ((Bool) -> Void)?
        var unsubscribeHandlerClosure: (() -> Void)?

        init?<T: QuerySubscribable>(query: Query<T.Object>, message: SubscribeMessage<T.Object>, handler: T) {
            guard let queryData = try? ParseCoding.jsonEncoder().encode(query),
                  let encoded = try? ParseCoding.jsonEncoder().encode(message) else {
                return nil
            }
            self.queryData = queryData
            self.messageData = encoded
            self.subscriptionHandler = handler

            eventHandlerClosure = { event in
                try? handler.didReceive(event)
            }

            subscribeHandlerClosure = { (new) in
                handler.didSubscribe(new)
            }

            unsubscribeHandlerClosure = { () in
                handler.didUnsubscribe()
            }
        }

        mutating func update<T: ParseObject>(query: Query<T>, message: SubscribeMessage<T>) throws {
            guard let queryData = try? ParseCoding.jsonEncoder().encode(query),
                  let encoded = try? ParseCoding.jsonEncoder().encode(message) else {
                throw ParseError(code: .otherCause, message: "ParseLiveQuery Error: Unable to update subscription.")
            }
            self.queryData = queryData
            self.messageData = encoded
        }

        static func == (lhs: SubscriptionRecord, rhs: SubscriptionRecord) -> Bool {
            lhs.messageData == rhs.messageData &&
            lhs.queryData == rhs.queryData
        }
    }
}

// MARK: Subscribing
extension ParseLiveQuery {

	func subscribe<T>(_ query: Query<T>) async throws -> Subscription<T> {
        try await subscribe(Subscription(query: query))
    }

    func subscribe<T>(_ query: Query<T>) async throws -> SubscriptionCallback<T> {
        try await subscribe(SubscriptionCallback(query: query))
    }

    public func subscribe<T>(_ handler: T) async throws -> T where T: QuerySubscribable {

        let requestId = await subscriptions.getRequestId()
        let message = await SubscribeMessage<T.Object>(operation: .subscribe,
                                                       requestId: requestId,
                                                       query: handler.query)
        guard let subscriptionRecord = SubscriptionRecord(
            query: handler.query,
            message: message,
            handler: handler
        ) else {
            throw ParseError(code: .otherCause, message: "ParseLiveQuery Error: Could not create subscription.")
        }

        try? await self.send(record: subscriptionRecord, requestId: requestId)
        return handler
    }
}

// MARK: Unsubscribing
extension ParseLiveQuery {

	func unsubscribe<T>(_ query: Query<T>) async throws where T: ParseObject {
        let unsubscribeQuery = try ParseCoding.jsonEncoder().encode(query)
        try await unsubscribe { $0.queryData == unsubscribeQuery }
    }

	func unsubscribe<T>(_ handler: T) async throws where T: QuerySubscribable {
        let unsubscribeQuery = try ParseCoding.jsonEncoder().encode(handler.query)
        try await unsubscribe { $0.queryData == unsubscribeQuery && $0.subscriptionHandler === handler }
    }

	func unsubscribe(matching matcher: @escaping (SubscriptionRecord) -> Bool) async throws {
        let subscriptions = await self.subscriptions.getCurrent()
        for (key, value) in subscriptions {
            // swiftlint:disable:next for_where
            if matcher(value) {
                let encoded = try ParseCoding
                    .jsonEncoder()
                    .encode(await StandardMessage(operation: .unsubscribe,
                                                  requestId: key))
                var updatedRecord = value
                updatedRecord.messageData = encoded
                try await self.send(record: updatedRecord, requestId: key)
                break
            }
        }
    }
}

// MARK: Updating
extension ParseLiveQuery {

	func update<T>(_ handler: T) async throws where T: QuerySubscribable {
        let subscriptions = await self.subscriptions.getCurrent()
        for (key, value) in subscriptions {
            // swiftlint:disable:next for_where
            if value.subscriptionHandler === handler {
                let message = await SubscribeMessage<T.Object>(operation: .update,
                                                               requestId: key,
                                                               query: handler.query)
                var updatedRecord = value
                try updatedRecord.update(query: handler.query, message: message)
                try await self.send(record: updatedRecord, requestId: key)
                break
            }
        }
    }
}

// MARK: ParseLiveQuery - Subscribe
public extension Query {

    #if canImport(Combine)

    /**
     Registers the query for live updates, using the default subscription handler,
     and the default `ParseLiveQuery` client. Suitable for `ObjectObserved`
     as the subscription can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     - returns: The subscription that has just been registered.
     - throws: An error of type `ParseError`.
     */
	func subscribe() async throws -> Subscription<ResultType> {
        try await ParseLiveQuery.client().subscribe(self)
    }

    /**
     Registers the query for live updates, using the default subscription handler,
     and a specific `ParseLiveQuery` client. Suitable for `ObjectObserved`
     as the subscription can be used as a SwiftUI publisher. Meaning it can serve
     indepedently as a ViewModel in MVVM.
     - parameter client: A specific client.
     - returns: The subscription that has just been registered.
     - throws: An error of type `ParseError`.
     */
    func subscribe(_ client: ParseLiveQuery) async throws -> Subscription<ResultType> {
        try await client.subscribe(Subscription(query: self))
    }
    #endif

    /**
     Registers a query for live updates, using a custom subscription handler.
     - parameter handler: A custom subscription handler. 
     - returns: Your subscription handler, for easy chaining.
     - throws: An error of type `ParseError`.
    */
    static func subscribe<V: QuerySubscribable>(_ handler: V) async throws -> V {
        try await ParseLiveQuery.client().subscribe(handler)
    }

    /**
     Registers a query for live updates, using a custom subscription handler.
     - parameter handler: A custom subscription handler.
     - parameter client: A specific client.
     - returns: Your subscription handler, for easy chaining.
     - throws: An error of type `ParseError`.
    */
    static func subscribe<V: QuerySubscribable>(_ handler: V, client: ParseLiveQuery) async throws -> V {
        try await ParseLiveQuery.client().subscribe(handler)
    }

    /**
     Registers the query for live updates, using the default subscription handler
     and the default `ParseLiveQuery` client.
     - returns: The subscription that has just been registered.
     - throws: An error of type `ParseError`.
     */
    func subscribeCallback() async throws -> SubscriptionCallback<ResultType> {
        try await ParseLiveQuery.client().subscribe(SubscriptionCallback(query: self))
    }

    /**
     Registers the query for live updates, using the default subscription handler
     and a specific `ParseLiveQuery` client.
     - parameter client: A specific client.
     - returns: The subscription that has just been registered.
     - throws: An error of type `ParseError`.
     */
    func subscribeCallback(_ client: ParseLiveQuery) async throws -> SubscriptionCallback<ResultType> {
        try await client.subscribe(SubscriptionCallback(query: self))
    }
}

// MARK: ParseLiveQuery - Unsubscribe
public extension Query {
    /**
     Unsubscribes all current subscriptions for a given query on the default
     `ParseLiveQuery` client.
     - throws: An error of type `ParseError`.
     */
    func unsubscribe() async throws {
        try await ParseLiveQuery.client().unsubscribe(self)
    }

    /**
     Unsubscribes all current subscriptions for a given query on a specific
     `ParseLiveQuery` client.
     - parameter client: A specific client.
     - throws: An error of type `ParseError`.
     */
    func unsubscribe(client: ParseLiveQuery) async throws {
        try await client.unsubscribe(self)
    }

    /**
     Unsubscribes from a specific query-handler on the default
     `ParseLiveQuery` client.
     - parameter handler: The specific handler to unsubscribe from.
     - throws: An error of type `ParseError`.
     */
	func unsubscribe<V: QuerySubscribable>(_ handler: V) async throws {
        try await ParseLiveQuery.client().unsubscribe(handler)
    }

    /**
     Unsubscribes from a specific query-handler on a specific
     `ParseLiveQuery` client.
     - parameter handler: The specific handler to unsubscribe from.
     - parameter client: A specific client.
     - throws: An error of type `ParseError`.
     */
	func unsubscribe<V: QuerySubscribable>(_ handler: V, client: ParseLiveQuery) async throws {
        try await client.unsubscribe(handler)
    }
}

// MARK: ParseLiveQuery - Update
public extension Query {
    /**
     Updates an existing subscription with a new query on the default `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     - throws: An error of type `ParseError`.
     */
	func update<V: QuerySubscribable>(_ handler: V) async throws {
        try await ParseLiveQuery.client().update(handler)
    }

    /**
     Updates an existing subscription with a new query on a specific `ParseLiveQuery` client.
     Upon completing the registration, the subscribe handler will be called with the new query.
     - parameter handler: The specific handler to update.
     - parameter client: A specific client.
     - throws: An error of type `ParseError`.
     */
	func update<V: QuerySubscribable>(_ handler: V, client: ParseLiveQuery) async throws {
        try await client.update(handler)
    }
}
#endif
