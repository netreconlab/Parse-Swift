//
//  ParseLiveQueryTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/3/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//
#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
import XCTest
@testable import ParseSwift

// swiftlint:disable function_body_length type_body_length

class ParseLiveQueryTests: XCTestCase, @unchecked Sendable {
    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int = 0

        // custom initializer
        init() {}

        init(points: Int) {
            self.points = points
        }
    }

    class TestDelegate: NSObject, ParseLiveQueryDelegate, @unchecked Sendable {
		var error: ParseError? {
			get {
				lock.lock()
				defer { lock.unlock() }
				return _error
			}
			set {
				lock.lock()
				defer { lock.unlock() }
				_error = newValue
			}
		}
		var code: URLSessionWebSocketTask.CloseCode? {
			get {
				lock.lock()
				defer { lock.unlock() }
				return _code
			}
			set {
				lock.lock()
				defer { lock.unlock() }
				_code = newValue
			}
		}
		var reason: Data? {
			get {
				lock.lock()
				defer { lock.unlock() }
				return _reason
			}
			set {
				lock.lock()
				defer { lock.unlock() }
				_reason = newValue
			}
		}
		nonisolated(unsafe) var _error: ParseError?
		nonisolated(unsafe) var _code: URLSessionWebSocketTask.CloseCode?
		nonisolated(unsafe) var _reason: Data?
		let lock = NSLock()
        func received(_ error: Error) {
            if let error = error as? ParseError {
                self.error = error
            }
        }
        func closedSocket(_ code: URLSessionWebSocketTask.CloseCode?, reason: Data?) {
            self.code = code
            self.reason = reason
        }
    }

    override func setUp() async throws {
        try await super.setUp()
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(
			applicationId: "applicationId",
			clientKey: "clientKey",
			primaryKey: "primaryKey",
			maintenanceKey: "maintenanceKey",
			serverURL: url,
			liveQueryMaxConnectionAttempts: 1,
			testing: true,
			testLiveQueryDontCloseSocket: true
		)
        try await ParseLiveQuery.configure()
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
        await URLSession.liveQuery.closeAll()
        ParseLiveQuery.defaultClient = nil
    }

    func testWebsocketURL() async throws {
        guard let originalURL = URL(string: "http://localhost:1337/parse"),
            var components = URLComponents(url: originalURL,
                                             resolvingAgainstBaseURL: false) else {
            XCTFail("Should have retrieved URL components")
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        let webSocketURL = components.url

        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }

        XCTAssertEqual(client.url, webSocketURL)
        XCTAssertTrue(client.url.absoluteString.contains("ws"))

        let socketDelegates = await URLSession.liveQuery.tasks.delegates
        XCTAssertNotNil(socketDelegates[client.task])
    }

    func testInitializeWithNewURL() async throws {
        guard let originalURL = URL(string: "http://parse:1337/parse"),
            var components = URLComponents(url: originalURL,
                                             resolvingAgainstBaseURL: false) else {
            XCTFail("Should have retrieved URL components")
            return
        }
        components.scheme = (components.scheme == "https" || components.scheme == "wss") ? "wss" : "ws"
        let webSocketURL = components.url

        let client = try await ParseLiveQuery(serverURL: originalURL)

        guard let defaultClient = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to initialize a new client")
            return
        }

        XCTAssertEqual(client.url, webSocketURL)
        XCTAssertTrue(client.url.absoluteString.contains("ws"))
        XCTAssertNotEqual(client, defaultClient)
        let socketDelegates = await URLSession.liveQuery.tasks.delegates
        XCTAssertNotNil(socketDelegates[client.task])
    }

    func testInitializeNewDefault() async throws {

        let client = try await ParseLiveQuery(isDefault: true)
        guard let defaultClient = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to initialize a new client")
            return
        }

        XCTAssertTrue(client.url.absoluteString.contains("ws"))
        XCTAssertEqual(client, defaultClient)
        let socketDelegates = await URLSession.liveQuery.tasks.delegates
        XCTAssertNotNil(socketDelegates[client.task])
    }

    func testDeinitializingNewShouldNotEffectDefault() async throws {
        guard let defaultClient = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to initialize a new client")
            return
        }
        var client = try? await ParseLiveQuery()
        if let client = client {
            XCTAssertTrue(client.url.absoluteString.contains("ws"))
        } else {
            XCTFail("Should have initialized client and contained ws")
        }
        XCTAssertNotEqual(client, defaultClient)
        client = nil
        XCTAssertNotNil(ParseLiveQuery.defaultClient)
        let socketDelegates = await URLSession.liveQuery.tasks.delegates
        XCTAssertNotNil(socketDelegates[defaultClient.task])
    }

    func testBecomingSocketAuthDelegate() async throws {
        let delegate = TestDelegate()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertNil(URLSession.liveQuery.authenticationDelegate)
        client.authenticationDelegate = delegate
        guard let authDelegate = URLSession
                .liveQuery
                .authenticationDelegate as? ParseLiveQuery else {
            XCTFail("Should be able to cast")
            return
        }
        XCTAssertEqual(client, authDelegate)
        XCTAssertNotNil(URLSession.liveQuery.authenticationDelegate)
        client.authenticationDelegate = nil
        XCTAssertNil(URLSession.liveQuery.authenticationDelegate)
    }

    func testInitLiveQueryConnectionWithNoAdditional() async throws {
        XCTAssertTrue(Parse.configuration.liveQueryConnectionAdditionalProperties)
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        maintenanceKey: "maintenanceKey",
                                        serverURL: url,
                                        liveQueryConnectionAdditionalProperties: false,
                                        liveQueryMaxConnectionAttempts: 1,
                                        testing: true,
                                        testLiveQueryDontCloseSocket: true)
        XCTAssertFalse(Parse.configuration.liveQueryConnectionAdditionalProperties)
    }

    func testStandardMessageEncoding() async throws {
        guard let installationId = await BaseParseInstallation.currentContainer().installationId else {
            XCTFail("Should have installationId")
            return
        }
        // swiftlint:disable:next line_length
        let expected = "{\"applicationId\":\"applicationId\",\"clientKey\":\"clientKey\",\"installationId\":\"\(installationId)\",\"maintenanceKey\":\"maintenanceKey\",\"masterKey\":\"primaryKey\",\"op\":\"connect\"}"
        let message = await StandardMessage(operation: .connect, additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testStandardMessageNoAdditionalPropertiesEncoding() async throws {
        // swiftlint:disable:next line_length
        let expected = "{\"applicationId\":\"applicationId\",\"clientKey\":\"clientKey\",\"maintenanceKey\":\"maintenanceKey\",\"masterKey\":\"primaryKey\",\"op\":\"connect\"}"
        let message = await StandardMessage(operation: .connect)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testStandardMessageNotConnectionEncoding() async throws {
        guard let installationId = await BaseParseInstallation.currentContainer().installationId else {
            XCTFail("Should have installationId")
            return
        }
        // swiftlint:disable:next line_length
        let expected = "{\"applicationId\":\"applicationId\",\"clientKey\":\"clientKey\",\"installationId\":\"\(installationId)\",\"maintenanceKey\":\"maintenanceKey\",\"masterKey\":\"primaryKey\",\"op\":\"subscribe\"}"
        let message = await StandardMessage(operation: .subscribe, additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testStandardMessageNotConnectionNoAddEncoding() async throws {
        let expected = "{\"op\":\"subscribe\"}"
        let message = await StandardMessage(operation: .subscribe, additionalProperties: false)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testSubscribeMessageFieldsEncoding() async throws {
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"subscribe\",\"query\":{\"className\":\"GameScore\",\"fields\":[\"hello\",\"points\"],\"where\":{\"points\":{\"$gt\":9}}},\"requestId\":1}"
        let query = GameScore.query("points" > 9)
            .fields(["hello", "points"])
            .select(["hello", "talk"])
        let message = await SubscribeMessage(operation: .subscribe,
                                             requestId: RequestId(value: 1),
                                             query: query,
                                             additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testSubscribeMessageSelectEncoding() async throws {
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"subscribe\",\"query\":{\"className\":\"GameScore\",\"fields\":[\"hello\",\"points\"],\"where\":{\"points\":{\"$gt\":9}}},\"requestId\":1}"
        let query = GameScore.query("points" > 9)
            .select(["hello", "points"])
        let message = await SubscribeMessage(operation: .subscribe,
                                             requestId: RequestId(value: 1),
                                             query: query,
                                             additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testFieldKeys() async throws {
        let query = GameScore.query
        XCTAssertNil(query.keys)

        var query2 = GameScore.query.fields(["yolo"])
        XCTAssertEqual(query2.fields?.count, 1)
        XCTAssertEqual(query2.fields?.first, "yolo")

        query2 = query2.fields(["hello", "wow"])
        XCTAssertEqual(query2.fields?.count, 3)
        XCTAssertEqual(query2.fields, ["yolo", "hello", "wow"])
    }

    func testFieldKeysVariadic() async throws {
        let query = GameScore.query
        XCTAssertNil(query.keys)

        var query2 = GameScore.query.fields("yolo")
        XCTAssertEqual(query2.fields?.count, 1)
        XCTAssertEqual(query2.fields?.first, "yolo")

        query2 = query2.fields("hello", "wow")
        XCTAssertEqual(query2.fields?.count, 3)
        XCTAssertEqual(query2.fields, ["yolo", "hello", "wow"])
    }

    func testSubscribeMessageListenEncoding() async throws {
        // swiftlint:disable:next line_length
        let expected = "{\"op\":\"subscribe\",\"query\":{\"className\":\"GameScore\",\"watch\":[\"hello\",\"points\"],\"where\":{\"points\":{\"$gt\":9}}},\"requestId\":1}"
        let query = GameScore.query("points" > 9)
            .watch(["hello", "points"])
        let message = await SubscribeMessage(operation: .subscribe,
                                             requestId: RequestId(value: 1),
                                             query: query,
                                             additionalProperties: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testWatchKeys() async throws {
        var query = GameScore.query.watch(["yolo"])
        XCTAssertEqual(query.watch?.count, 1)
        XCTAssertEqual(query.watch?.first, "yolo")

        query = query.watch(["hello", "wow"])
        XCTAssertEqual(query.watch?.count, 3)
        XCTAssertEqual(query.watch, ["yolo", "hello", "wow"])
    }

    func testWatchKeysVariadic() async throws {
        var query = GameScore.query.watch("yolo")
        XCTAssertEqual(query.watch?.count, 1)
        XCTAssertEqual(query.watch?.first, "yolo")

        query = query.watch("hello", "wow")
        XCTAssertEqual(query.watch?.count, 3)
        XCTAssertEqual(query.watch, ["yolo", "hello", "wow"])
    }

    func testRedirectResponseDecoding() async throws {
        guard let url = URL(string: "http://parse.org") else {
            XCTFail("Should have url")
            return
        }
        let expected = "{\"op\":\"redirect\",\"url\":\"http:\\/\\/parse.org\"}"
        let message = RedirectResponse(op: .redirect, url: url)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testConnectionResponseDecoding() async throws {
        let expected = "{\"clientId\":\"yolo\",\"installationId\":\"naw\",\"op\":\"connected\"}"
        let message = ConnectionResponse(op: .connected, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testUnsubscribeResponseDecoding() async throws {
        let expected = "{\"clientId\":\"yolo\",\"installationId\":\"naw\",\"op\":\"connected\",\"requestId\":1}"
        let message = UnsubscribedResponse(op: .connected, requestId: 1, clientId: "yolo", installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testEventResponseDecoding() async throws {
        // swiftlint:disable:next line_length
        let expected = "{\"clientId\":\"yolo\",\"installationId\":\"naw\",\"object\":{\"points\":10},\"op\":\"connected\",\"requestId\":1}"
        let score = GameScore(points: 10)
        let message = EventResponse(op: .connected,
                                    requestId: 1,
                                    object: score,
                                    clientId: "yolo",
                                    installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testErrorResponseDecoding() async throws {
        let expected = "{\"code\":1,\"error\":\"message\",\"op\":\"error\",\"reconnect\":true}"
        let message = ErrorResponse(op: .error, code: 1, message: "message", reconnect: true)
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testPreliminaryResponseDecoding() async throws {
        let expected = "{\"clientId\":\"message\",\"installationId\":\"naw\",\"op\":\"subscribed\",\"requestId\":1}"
        let message = PreliminaryMessageResponse(op: .subscribed,
                                                 requestId: 1,
                                                 clientId: "message",
                                                 installationId: "naw")
        let encoded = try ParseCoding.jsonEncoder()
            .encode(message)
        let decoded = try XCTUnwrap(String(decoding: encoded, as: UTF8.self))
        XCTAssertEqual(decoded, expected)
    }

    func testSocketNotOpenState() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(client.status, .socketNotEstablished)
    }

    func testConnectedState() async throws {
        guard let client = ParseLiveQuery.defaultClient,
              let task = client.task else {
            XCTFail("Should be able to get client and task")
            return
        }
        await client.setStatus(.connected)
        client.attempts = 5
        client.clientId = "yolo"
        client.isDisconnectedByUser = false
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = await URLSession.liveQuery.tasks.receivers[task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        XCTAssertEqual(client.status, .connected)
        XCTAssertEqual(client.clientId, "yolo")
        XCTAssertEqual(client.attempts, 5)

        // Test too many attempts and close
        await client.setStatus(.connected)
        client.attempts = Parse.configuration.liveQueryMaxConnectionAttempts + 1
        client.clientId = "yolo"
        client.isDisconnectedByUser = false

        XCTAssertEqual(client.status, .connected)
        XCTAssertEqual(client.clientId, "yolo")
        XCTAssertEqual(client.attempts, Parse.configuration.liveQueryMaxConnectionAttempts + 1)
    }

    func testDisconnectedState() async throws {
        guard let client = ParseLiveQuery.defaultClient,
              let task = client.task else {
            XCTFail("Should be able to get client and task")
            return
        }
        await client.setStatus(.connected)
        client.clientId = "yolo"
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = await URLSession.liveQuery.tasks.receivers[task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        XCTAssertEqual(client.status, .connected)
        XCTAssertEqual(client.clientId, "yolo")
        await client.setStatus(.disconnected)
        XCTAssertNil(client.clientId)
    }

    func testSocketDisconnectedState() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.setStatus(.connected)
        client.clientId = "yolo"

        XCTAssertEqual(client.status, .connected)
        XCTAssertEqual(client.clientId, "yolo")
        await client.setStatus(.socketNotEstablished)
        XCTAssertNil(client.clientId)
    }

    func testUserClosedConnectionState() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.setStatus(.connected)
        client.clientId = "yolo"
        client.isDisconnectedByUser = false

        XCTAssertEqual(client.status, .connected)
        XCTAssertEqual(client.isDisconnectedByUser, false)
        XCTAssertEqual(client.clientId, "yolo")
        await client.close()

        XCTAssertEqual(client.status, .socketNotEstablished)
        XCTAssertNil(client.clientId)
        XCTAssertEqual(client.isDisconnectedByUser, true)
    }

    func testOpenSocket() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.close()
        let expectation1 = XCTestExpectation(description: "Response delegate")
        client.open(isUserWantsToConnect: true) { error in
            XCTAssertNotNil(error) // Should always fail since WS is not intercepted.
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testCloseFromServer() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            throw ParseError(code: .otherCause,
                             message: "Should be able to get client")
        }
        let delegate = TestDelegate()
        client.receiveDelegate = delegate
        client.task = await URLSession.liveQuery.createTask(client.url,
                                                            taskDelegate: client)
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = await URLSession.liveQuery.tasks.receivers[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        await client.status(.closed, closeCode: .goingAway, reason: nil)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        XCTAssertEqual(delegate.code, .goingAway)
        XCTAssertNil(delegate.reason)

        let receivers = await URLSession.liveQuery.tasks.receivers[client.task]
        switch client.task.state {
        case .running, .suspended:
            XCTAssertNotNil(receivers)
        default:
            XCTAssertNil(receivers)
        }
    }

    func testCloseExternal() async throws {
        let client = try await ParseLiveQuery()
        guard let originalTask = client.task,
              client.task.state == .running else {
            throw XCTSkip("Skip this test when state is not running")
        }
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = await URLSession.liveQuery.tasks.receivers[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        await client.setStatus(.connected)
        await client.close()

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        XCTAssertTrue(client.task.state == .suspended)
        XCTAssertEqual(client.status, .socketNotEstablished)
        let delegates = await URLSession.liveQuery.tasks.delegates
        let receivers = await URLSession.liveQuery.tasks.receivers
        XCTAssertNil(delegates[originalTask])
        XCTAssertNil(receivers[originalTask])
        XCTAssertNotNil(delegates[client.task])
        XCTAssertEqual(receivers[client.task], true)
    }

    func testCloseAll() async throws {
        let client = try await ParseLiveQuery()
        guard let originalTask = client.task,
              client.task.state == .running else {
            throw XCTSkip("Skip this test when state is not running")
        }
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = await URLSession.liveQuery.tasks.receivers[client.task] else {
            throw XCTSkip("Skip this test when the receiving task is nil")
        }
        XCTAssertEqual(receivingTask, true)
        await client.setStatus(.connected)
        await client.closeAll()

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        XCTAssertTrue(client.task.state == .suspended)
        XCTAssertEqual(client.status, .socketNotEstablished)
        let delegates = await URLSession.liveQuery.tasks.delegates
        let receivers = await URLSession.liveQuery.tasks.receivers
        XCTAssertNil(delegates[originalTask])
        XCTAssertNil(receivers[originalTask])
        XCTAssertNotNil(delegates[client.task])
        XCTAssertEqual(receivers[client.task], true)
    }

    func testPingSocketNotEstablished() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.close()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        client.sendPing { error in
            XCTAssertEqual(client.status, .socketNotEstablished)
            guard let urlError = error as? URLError else {
                _ = XCTSkip("Skip this test when error cannot be unwrapped")
                expectation1.fulfill()
                return
            }
            // "Could not connect to the server"
            // because webSocket connections are not intercepted.
            XCTAssertTrue([-1003, -1004, -1022].contains(urlError.errorCode))
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testPing() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.setStatus(.connected)
        client.clientId = "yolo"

        let expectation1 = XCTestExpectation(description: "Send Ping")
        client.sendPing { error in
            XCTAssertEqual(client.status, .connected)
            XCTAssertNotNil(error) // Should have error because testcases do not intercept websocket
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testRandomIdGenerator() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        for index in 1 ..< 50 {
            let idGenerated = await client.subscriptions.requestIdGenerator()
            XCTAssertEqual(idGenerated.value, index)
        }
    }

    func testSubscribeNotConnected() async throws {
        let query = GameScore.query("points" > 9)
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)
        let isSubscribed = try await client.isSubscribed(query)
        let isPendingSubscription = try await client.isPendingSubscription(query)
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        let current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        do {
            try await client.removePendingSubscription(query)
        } catch {
            XCTFail(error.localizedDescription)
        }
        pending = await client.subscriptions.pending
        XCTAssertEqual(pending.count, 0)
    }

    func pretendToBeConnected(_ delegate: ParseLiveQueryDelegate? = nil) async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            throw ParseError(code: .otherCause,
                             message: "Should be able to get client")
        }
        let oldTask = client.task
        client.receiveDelegate = delegate
        client.task = await URLSession.liveQuery.createTask(client.url,
                                                            taskDelegate: client)
        if let oldTask = oldTask {
            await URLSession.liveQuery.removeTask(oldTask)
        }
        await client.status(.open)
        let installationId = try await BaseParseInstallation.current().installationId
        let response = ConnectionResponse(op: .connected,
                                          clientId: "yolo",
                                          installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        await URLSession.liveQuery.tasks.updateReceivers([client.task: true])
        // Only continue test if this is not nil, otherwise skip
        guard let receivingTask = await URLSession.liveQuery.tasks.receivers[client.task],
            receivingTask == true else {
            throw XCTSkip("Skip this test when the receiving task is nil or not true")
        }
    }

    func testSubscribeConnected() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        var isSubscribed = try await client.isSubscribed(query)
        XCTAssertFalse(isSubscribed)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        XCTAssertTrue(isPendingSubscription)
        var subscriptions = await client.subscriptions.current
        XCTAssertEqual(subscriptions.count, 0)
        var pending = await client.subscriptions.pending
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        subscriptions = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertTrue(isSubscribed)
        XCTAssertFalse(isPendingSubscription)
        XCTAssertEqual(subscriptions.count, 1)
        XCTAssertEqual(pending.count, 0)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        guard let subscribed = subscription.subscribed else {
            XCTFail("Should unwrap subscribed.")
            return
        }
        XCTAssertTrue(subscription.isSubscribed)
        XCTAssertFalse(subscription.isUnsubscribed)
        XCTAssertEqual(query, subscribed.query)
        XCTAssertTrue(subscribed.isNew)
        XCTAssertNil(subscription.unsubscribed)
        XCTAssertNil(subscription.event)

        // Unsubscribe
        do {
            try await query.unsubscribe()
        } catch {
            XCTFail(error.localizedDescription)
        }
        subscriptions = await client.subscriptions.current
        XCTAssertEqual(subscriptions.count, 1)
        pending = await client.subscriptions.pending
        XCTAssertEqual(pending.count, 1)

        // Received Unsubscribe
        let response2 = PreliminaryMessageResponse(op: .unsubscribed,
                                                   requestId: 1,
                                                   clientId: "yolo",
                                                   installationId: installationId)
        guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
            XCTFail("Should have encoded second response")
            return
        }
        await client.received(encoded2)
        subscriptions = await client.subscriptions.current
        XCTAssertEqual(subscriptions.count, 0)
        pending = await client.subscriptions.pending
        XCTAssertEqual(pending.count, 0)

        try await Task.sleep(nanoseconds: nanoSeconds)

        guard let unsubscribed = subscription.unsubscribed else {
            XCTFail("Should unwrap unsubscribed.")
            return
        }
        XCTAssertFalse(subscription.isSubscribed)
        XCTAssertTrue(subscription.isUnsubscribed)
        XCTAssertEqual(query, unsubscribed)
        XCTAssertNil(subscription.subscribed)
        XCTAssertNil(subscription.event)
    }

    func testSubscribeCallbackConnected() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)

        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            XCTAssertTrue(isNew)
            expectation1.fulfill()

            // Unsubscribe
            subscription.handleUnsubscribe { query in
                XCTAssertEqual(query, subscribedQuery)
                XCTAssertEqual(client.status, .connected)
                Task {
                    let current = await client.subscriptions.current
                    let pending = await client.subscriptions.pending
                    XCTAssertTrue(current.isEmpty)
                    XCTAssertTrue(pending.isEmpty)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
            }

            Task {
                do {
                    try await query.unsubscribe()
                } catch {
                    XCTFail(error.localizedDescription)
                }
                var current = await client.subscriptions.current
                var pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 1)
                XCTAssertEqual(pending.count, 1)

                // Received Unsubscribe
                let response2 = PreliminaryMessageResponse(op: .unsubscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: installationId)
                guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                    XCTFail("Should have encoded second response")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded2)
                current = await client.subscriptions.current
                pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 0)
                XCTAssertEqual(pending.count, 0)
            }
        }

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertTrue(isSubscribed)
        if !isPendingSubscription {
            XCTAssertFalse(isPendingSubscription)
        }
        if current.count == 1 {
            XCTAssertEqual(current.count, 1)
        } else {
            XCTAssertEqual(current.count, 0)
        }
        if pending.count == 0 {
            XCTAssertEqual(pending.count, 0)
        } else {
            XCTAssertEqual(pending.count, 1)
        }
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testSubscribeCallbackConnected2() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribeCallback()

        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            XCTAssertTrue(isNew)
            expectation1.fulfill()

            // Unsubscribe
            subscription.handleUnsubscribe { query in
                XCTAssertEqual(query, subscribedQuery)
                XCTAssertEqual(client.status, .connected)
                Task {
                    let current = await client.subscriptions.current
                    let pending = await client.subscriptions.pending
                    XCTAssertTrue(current.isEmpty)
                    XCTAssertTrue(pending.isEmpty)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
            }

            Task {
                do {
                    try await query.unsubscribe()
                } catch {
                    XCTFail(error.localizedDescription)
                }
                var current = await client.subscriptions.current
                var pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 1)
                XCTAssertEqual(pending.count, 1)

                // Received Unsubscribe
                let response2 = PreliminaryMessageResponse(op: .unsubscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: installationId)
                guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                    XCTFail("Should have encoded second response")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded2)
                current = await client.subscriptions.current
                pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 0)
                XCTAssertEqual(pending.count, 0)
            }
        }

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        if isSubscribed {
            XCTAssertTrue(isSubscribed)
        } else {
            _ = XCTSkip("Should be subscribed")
        }
        if !isPendingSubscription {
            XCTAssertFalse(isPendingSubscription)
        } else {
            _ = XCTSkip("Should not have pending subscriptions")
        }
        if current.count == 1 {
            XCTAssertEqual(current.count, 1)
        } else {
            _ = XCTSkip("Should have 1 subscription, currently has \(current.count)")
        }
        if pending.count == 0 {
            XCTAssertEqual(pending.count, 0)
        } else {
            _ = XCTSkip("Should have 0 pending subscriptions, currently has \(pending.count)")
        }
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testSubscribeCallbackConnected3() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        let subscription = try await query.subscribeCallback(client)
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            XCTAssertTrue(isNew)
            expectation1.fulfill()

            // Unsubscribe
            subscription.handleUnsubscribe { query in
                XCTAssertEqual(query, subscribedQuery)
                XCTAssertEqual(client.status, .connected)
                Task {
                    let current = await client.subscriptions.current
                    let pending = await client.subscriptions.pending
                    XCTAssertTrue(current.isEmpty)
                    XCTAssertTrue(pending.isEmpty)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
            }

            Task {
                do {
                    try await query.unsubscribe()
                } catch {
                    XCTFail(error.localizedDescription)
                }
                var current = await client.subscriptions.current
                var pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 1)
                XCTAssertEqual(pending.count, 1)

                // Received Unsubscribe
                let response2 = PreliminaryMessageResponse(op: .unsubscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: installationId)
                guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                    XCTFail("Should have encoded second response")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded2)
                current = await client.subscriptions.current
                pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 0)
                XCTAssertEqual(pending.count, 0)
            }
        }

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        if isSubscribed {
            XCTAssertTrue(isSubscribed)
        } else {
            _ = XCTSkip("Should be subscribed")
        }
        if !isPendingSubscription {
            XCTAssertFalse(isPendingSubscription)
        } else {
            _ = XCTSkip("Should not have pending subscriptions")
        }
        if current.count == 1 {
            XCTAssertEqual(current.count, 1)
        } else {
            _ = XCTSkip("Should have 1 subscription, currently has \(current.count)")
        }
        if pending.count == 0 {
            XCTAssertEqual(pending.count, 0)
        } else {
            _ = XCTSkip("Should have 0 pending subscriptions, currently has \(pending.count)")
        }
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testSubscribeCloseSubscribe() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)

        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Resubscribe Handler")
        var count = 0
        var originalTask: URLSessionWebSocketTask?
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            if count == 0 {
                XCTAssertTrue(isNew)
                XCTAssertNotNil(ParseLiveQuery.client?.task)
                originalTask = ParseLiveQuery.client?.task
                count += 1
                Task {
                    let current = await client.subscriptions.current
                    let pending = await client.subscriptions.pending
                    XCTAssertEqual(current.count, 1)
                    XCTAssertEqual(pending.count, 0)
                    expectation1.fulfill()
                }
            } else {
                XCTAssertNotNil(ParseLiveQuery.client?.task)
                XCTAssertFalse(originalTask == ParseLiveQuery.client?.task)
                expectation2.fulfill()
                return
            }

            Task {
                await ParseLiveQuery.client?.close()

                guard ParseLiveQuery.client?.status == .socketNotEstablished else {
                    XCTFail("Should have socket that is not established")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }

                // Resubscribe
                try? await self.pretendToBeConnected()
                let response2 = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: installationId)
                guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                    XCTFail("Should have encoded second response")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded2)
            }
        }

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertTrue(isSubscribed)
        XCTAssertFalse(isPendingSubscription)
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 0)

        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testSubscribeCloseWrongClientId() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)

        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Resubscribe Handler")

        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            XCTAssertTrue(isNew)
            XCTAssertNotNil(ParseLiveQuery.client?.task)
            Task {
                let current = await client.subscriptions.current
                let pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 1)
                XCTAssertEqual(pending.count, 0)
                DispatchQueue.main.async {
                    expectation1.fulfill()
                }

                await ParseLiveQuery.client?.close()

                guard ParseLiveQuery.client?.status == .socketNotEstablished else {
                    XCTFail("Should have socket that is not established")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }

                // Resubscribe
                let delegate = TestDelegate()
                try? await self.pretendToBeConnected(delegate)
                let response2 = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "wow",
                                                           installationId: installationId)
                guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                    XCTFail("Should have encoded second response")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded2)
                let nanoSeconds = UInt64(1 * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoSeconds)
                guard let receivedError = delegate.error else {
                    XCTFail("Should have received error")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                XCTAssertTrue(receivedError.message.contains("clientId"))
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        }
    }

    func testSubscribeCloseWrongInstallationId() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)

        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Resubscribe Handler")

        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            XCTAssertTrue(isNew)
            XCTAssertNotNil(ParseLiveQuery.client?.task)
            Task {
                let current = await client.subscriptions.current
                let pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 1)
                XCTAssertEqual(pending.count, 0)
                DispatchQueue.main.async {
                    expectation1.fulfill()
                }

                await ParseLiveQuery.client?.close()

                guard ParseLiveQuery.client?.status == .socketNotEstablished else {
                    XCTFail("Should have socket that is not established")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }

                // Resubscribe
                let delegate = TestDelegate()
                try? await self.pretendToBeConnected(delegate)
                let response2 = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 1,
                                                           clientId: "yolo",
                                                           installationId: "naw")
                guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                    XCTFail("Should have encoded second response")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded2)
                let nanoSeconds = UInt64(1 * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoSeconds)
                guard let receivedError = delegate.error else {
                    XCTFail("Should have received error")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                XCTAssertTrue(receivedError.message.contains("installationId"))
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        }
    }

    func testSubscribeCloseRequestIdNotPending() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)

        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Resubscribe Handler")

        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            XCTAssertTrue(isNew)
            XCTAssertNotNil(ParseLiveQuery.client?.task)
            Task {
                let current = await client.subscriptions.current
                let pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 1)
                XCTAssertEqual(pending.count, 0)
                DispatchQueue.main.async {
                    expectation1.fulfill()
                }

                await ParseLiveQuery.client?.close()

                guard ParseLiveQuery.client?.status == .socketNotEstablished else {
                    XCTFail("Should have socket that is not established")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }

                // Resubscribe
                let delegate = TestDelegate()
                try? await self.pretendToBeConnected(delegate)
                let response2 = PreliminaryMessageResponse(op: .subscribed,
                                                           requestId: 100,
                                                           clientId: "yolo",
                                                           installationId: installationId)
                guard let encoded2 = try? ParseCoding.jsonEncoder().encode(response2) else {
                    XCTFail("Should have encoded second response")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded2)
                let nanoSeconds = UInt64(1 * 1_000_000_000)
                try await Task.sleep(nanoseconds: nanoSeconds)
                guard let receivedError = delegate.error else {
                    XCTFail("Should have received error")
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                    return
                }
                XCTAssertTrue(receivedError.message.contains("with requestId"))
                DispatchQueue.main.async {
                    expectation2.fulfill()
                }
            }
        }

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        if isSubscribed {
            XCTAssertTrue(isSubscribed)
        } else {
            _ = XCTSkip("Should be subscribed")
        }
        if !isPendingSubscription {
            XCTAssertFalse(isPendingSubscription)
        } else {
            _ = XCTSkip("Should not have pending subscriptions")
        }
        if current.count == 1 {
            XCTAssertEqual(current.count, 1)
        } else {
            _ = XCTSkip("Should have 1 subscription, currently has \(current.count)")
        }
        if pending.count == 0 {
            XCTAssertEqual(pending.count, 0)
        } else {
            _ = XCTSkip("Should have 0 pending subscriptions, currently has \(pending.count)")
        }
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }

    func testServerRedirectResponse() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }

        guard let url = URL(string: "wss://parse.com") else {
            XCTFail("Should create url")
            return
        }
        XCTAssertNotEqual(client.url, url)
        let response = RedirectResponse(op: .redirect, url: url)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        XCTAssertEqual(client.url, url)
    }

    func testServerErrorResponse() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        let delegate = TestDelegate()
        client.receiveDelegate = delegate
        try await pretendToBeConnected(delegate)
        XCTAssertNil(delegate.error)
        guard let url = URL(string: "http://parse.com") else {
            XCTFail("Should create url")
            return
        }
        XCTAssertNotEqual(client.url, url)
        let response = ErrorResponse(op: .error, code: 1, message: "message", reconnect: true)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        XCTAssertNotNil(delegate.error)
        XCTAssertEqual(delegate.error?.code, ParseError.Code.internalServer)
        XCTAssertTrue(delegate.error?.message.contains("message") != nil)
    }

    func testServerErrorResponseNoReconnect() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        let delegate = TestDelegate()
        client.receiveDelegate = delegate
        try await pretendToBeConnected(delegate)
        XCTAssertNil(delegate.error)
        guard let url = URL(string: "http://parse.com") else {
            XCTFail("Should create url")
            return
        }
        XCTAssertNotEqual(client.url, url)
        let response = ErrorResponse(op: .error, code: 1, message: "message", reconnect: false)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        XCTAssertNotNil(delegate.error)
        XCTAssertEqual(delegate.error?.code, ParseError.Code.internalServer)
        XCTAssertTrue(delegate.error?.message.contains("message") != nil)

        try await Task.sleep(nanoseconds: nanoSeconds)

        XCTAssertTrue(client.isDisconnectedByUser)
        XCTAssertEqual(client.status, .socketNotEstablished)
    }

    func testEventEnter() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)
        let score = GameScore(points: 10)

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .enter,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        // Only continue test if this is not nil, otherwise skip
        guard let event = subscription.event else {
            _ = XCTSkip("Skip this test when event is missing")
            return
        }
        XCTAssertEqual(query, event.query)
        XCTAssertNil(subscription.subscribed)
        XCTAssertNil(subscription.unsubscribed)

        switch event.event {

        case .entered(let enter):
            XCTAssertEqual(enter, score)
        default:
            XCTFail("Should have receeived event")
        }
    }

    func testEventLeave() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Only continue test if this is not nil, otherwise skip
            guard let event = subscription.event else {
                _ = XCTSkip("Skip this test when event is missing")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)
            XCTAssertNil(subscription.subscribed)
            XCTAssertNil(subscription.unsubscribed)

            switch event.event {

            case .left(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .leave,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testEventCreate() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Only continue test if this is not nil, otherwise skip
            guard let event = subscription.event else {
                _ = XCTSkip("Skip this test when event is missing")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)
            XCTAssertNil(subscription.subscribed)
            XCTAssertNil(subscription.unsubscribed)

            switch event.event {

            case .created(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .create,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testEventUpdate() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)
        XCTAssertNil(subscription.subscribed)
        XCTAssertNil(subscription.unsubscribed)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // Only continue test if this is not nil, otherwise skip
            guard let event = subscription.event else {
                _ = XCTSkip("Skip this test when event is missing")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)

            switch event.event {

            case .updated(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .update,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testEventDelete() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            guard let event = subscription.event else {
                _ = XCTSkip("Skip this test when event is missing")
                expectation1.fulfill()
                return
            }
            XCTAssertEqual(query, event.query)
            XCTAssertNil(subscription.subscribed)
            XCTAssertNil(subscription.unsubscribed)

            switch event.event {

            case .deleted(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .delete,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testSubscriptionUpdate() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)
        XCTAssertNil(subscription.event)
        XCTAssertNil(subscription.unsubscribed)

        var count = 0

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        var response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertTrue(isSubscribed)
        XCTAssertFalse(isPendingSubscription)
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 0)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        guard let subscribed = subscription.subscribed else {
            XCTFail("Should unwrap")
            return
        }

        XCTAssertEqual(query, subscribed.query)
        if count == 0 {
            XCTAssertTrue(subscribed.isNew)
            count += 1
        }

        do {
            try await query.update(subscription)
            let isSubscribed = try await client.isSubscribed(query)
            let isPending = try await client.isPendingSubscription(query)
            XCTAssertTrue(isSubscribed)
            XCTAssertTrue(isPending)
        } catch {
            XCTFail(error.localizedDescription)
            return
        }
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 1)

        response = PreliminaryMessageResponse(op: .subscribed,
                                              requestId: 1,
                                              clientId: "yolo",
                                              installationId: installationId)
        guard let encoded = try? ParseCoding.jsonEncoder().encode(response) else {
            XCTFail("Should encode")
            return
        }
        await client.received(encoded)

        // Update
        try await Task.sleep(nanoseconds: nanoSeconds)

        guard let subscribed = subscription.subscribed else {
            XCTFail("Should unwrap")
            return
        }

        XCTAssertFalse(subscribed.isNew)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 0)
    }

    func testResubscribing() async throws {
        let query = GameScore.query("points" > 9)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await query.subscribe()
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        var count = 0

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        var response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertTrue(isSubscribed)
        XCTAssertFalse(isPendingSubscription)
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 0)

        let nanoSeconds = UInt64(1 * 1_000_000_000)
        try await Task.sleep(nanoseconds: nanoSeconds)

        guard let subscribed = subscription.subscribed else {
            XCTFail("Should unwrap")
            return
        }

        if count == 0 {
            XCTAssertTrue(subscribed.isNew)
            XCTAssertNil(subscription.event)
            XCTAssertNil(subscription.unsubscribed)
            count += 1
        }

        // Disconnect, subscriptions should remain the same
        await client.setStatus(.disconnected)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 0)

        // Connect moving to true should move to pending
        client.clientId = "yolo"
        await client.setStatus(.connected)
        try await Task.sleep(nanoseconds: nanoSeconds)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)

        // Fake server response
        response = PreliminaryMessageResponse(op: .subscribed,
                                              requestId: 1,
                                              clientId: "yolo",
                                              installationId: installationId)
        guard let encoded = try? ParseCoding.jsonEncoder().encode(response) else {
            XCTFail("Should have encoded")
            return
        }
        await client.received(encoded)

        try await Task.sleep(nanoseconds: nanoSeconds)

        guard let subscribed = subscription.subscribed else {
            XCTFail("Should unwrap")
            return
        }

        XCTAssertTrue(subscribed.isNew)
        XCTAssertNil(subscription.event)
        XCTAssertNil(subscription.unsubscribed)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 0)
    }

    func testEventEnterSubscriptionCallback() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .entered(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .enter,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testEventLeaveSubscriptioinCallback() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .left(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .leave,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testEventCreateSubscriptionCallback() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .created(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .create,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testEventUpdateSubscriptionCallback() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .updated(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .update,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testEventDeleteSubscriptionCallback() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let score = GameScore(points: 10)
        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        subscription.handleEvent { subscribedQuery, event in
            XCTAssertEqual(query, subscribedQuery)

            switch event {

            case .deleted(let enter):
                XCTAssertEqual(enter, score)
            default:
                XCTFail("Should have receeived event")
            }
            expectation1.fulfill()
        }

        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)

        let response2 = EventResponse(op: .delete,
                                      requestId: 1,
                                      object: score,
                                      clientId: "yolo",
                                      installationId: installationId)
        let encoded2 = try ParseCoding.jsonEncoder().encode(response2)
        await client.received(encoded2)
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testSubscriptionUpdateSubscriptionCallback() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        var count = 0
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            if count == 0 {
                XCTAssertTrue(isNew)
                count += 1
                expectation1.fulfill()
            } else {
                XCTAssertFalse(isNew)
                Task {
                    let current = await client.subscriptions.current
                    let pending = await client.subscriptions.pending
                    XCTAssertEqual(current.count, 1)
                    if pending.count == 0 {
                        XCTAssertEqual(pending.count, 0)
                    }
                }
                return
            }
        }

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        XCTAssertTrue(isSubscribed)
        XCTAssertFalse(isPendingSubscription)
        XCTAssertEqual(current.count, 1)
        XCTAssertEqual(pending.count, 0)

		await fulfillment(of: [expectation1], timeout: 20.0)
    }

    func testResubscribingSubscriptionCallback() async throws {
        let query = GameScore.query("points" > 9)
        let handler = SubscriptionCallback(query: query)
        let installationId = try await BaseParseInstallation.current().installationId
        let subscription = try await Query<GameScore>.subscribe(handler)
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        XCTAssertEqual(subscription.query, query)

        let expectation1 = XCTestExpectation(description: "Subscribe Handler")
        let expectation2 = XCTestExpectation(description: "Unsubscribe Handler")
        var count = 0
        subscription.handleSubscribe { subscribedQuery, isNew in
            XCTAssertEqual(query, subscribedQuery)
            if count == 0 {
                XCTAssertTrue(isNew)
                count += 1
                expectation1.fulfill()
            } else {
                XCTAssertTrue(isNew)
                Task {
                    let current = await client.subscriptions.current
                    let pending = await client.subscriptions.pending
                    XCTAssertEqual(current.count, 1)
                    XCTAssertEqual(pending.count, 0)
                    DispatchQueue.main.async {
                        expectation2.fulfill()
                    }
                }
                return
            }

            Task {
                // Disconnect, subscriptions should remain the same
                await client.setStatus(.disconnected)
                var current = await client.subscriptions.current
                var pending = await client.subscriptions.pending
                XCTAssertEqual(current.count, 1)
                XCTAssertEqual(pending.count, 0)

                // Connect moving to true should move to pending
                client.clientId = "yolo"
                await client.setStatus(.connected)
                current = await client.subscriptions.current
                pending = await client.subscriptions.pending
                if current.count == 0 {
                    XCTAssertEqual(current.count, 0)
                }
                if pending.count == 1 {
                    XCTAssertEqual(pending.count, 1)
                }

                // Fake server response
                let response = PreliminaryMessageResponse(op: .subscribed,
                                                          requestId: 1,
                                                          clientId: "yolo",
                                                          installationId: installationId)
                guard let encoded = try? ParseCoding.jsonEncoder().encode(response) else {
                    XCTFail("Should have encoded")
                    DispatchQueue.main.async {
                        expectation1.fulfill()
                        expectation2.fulfill()
                    }
                    return
                }
                await client.received(encoded)
            }
        }

        var isSubscribed = try await client.isSubscribed(query)
        var isPendingSubscription = try await client.isPendingSubscription(query)
        var current = await client.subscriptions.current
        var pending = await client.subscriptions.pending
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(isPendingSubscription)
        XCTAssertEqual(current.count, 0)
        XCTAssertEqual(pending.count, 1)
        try await pretendToBeConnected()
        let response = PreliminaryMessageResponse(op: .subscribed,
                                                  requestId: 1,
                                                  clientId: "yolo",
                                                  installationId: installationId)
        let encoded = try ParseCoding.jsonEncoder().encode(response)
        await client.received(encoded)
        isSubscribed = try await client.isSubscribed(query)
        isPendingSubscription = try await client.isPendingSubscription(query)
        current = await client.subscriptions.current
        pending = await client.subscriptions.pending
        if isSubscribed {
            XCTAssertTrue(isSubscribed)
        } else {
            _ = XCTSkip("Should be subscribed")
        }
        if !isPendingSubscription {
            XCTAssertFalse(isPendingSubscription)
        } else {
            _ = XCTSkip("Should not have pending subscriptions")
        }
        if current.count == 1 {
            XCTAssertEqual(current.count, 1)
        } else {
            _ = XCTSkip("Should have 1 subscription, currently has \(current.count)")
        }
        if pending.count == 0 {
            XCTAssertEqual(pending.count, 0)
        } else {
            _ = XCTSkip("Should have 0 pending subscriptions, currently has \(pending.count)")
        }
        await fulfillment(of: [expectation1, expectation2], timeout: 20.0)
    }
}
#endif
