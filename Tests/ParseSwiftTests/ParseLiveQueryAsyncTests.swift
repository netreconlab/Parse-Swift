//
//  ParseLiveQueryAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseLiveQueryAsyncTests: XCTestCase, @unchecked Sendable {
    override func setUp() async throws {
        try await super.setUp()
        guard let url = URL(string: "http://localhost:1337/parse") else {
            XCTFail("Should create valid URL")
            return
        }
        try await ParseSwift.initialize(applicationId: "applicationId",
                                        clientKey: "clientKey",
                                        primaryKey: "primaryKey",
                                        serverURL: url,
                                        liveQueryMaxConnectionAttempts: 1,
                                        testing: true,
                                        testLiveQueryDontCloseSocket: true)
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

    @MainActor
    func testOpen() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.close()

        do {
            _ = try await client.open(isUserWantsToConnect: true)
            XCTFail("Should always fail since WS is not intercepted.")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    @MainActor
    func testPingSocketNotEstablished() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.close()

        do {
            _ = try await client.sendPing()
            XCTFail("Should have produced error")
        } catch {
            XCTAssertEqual(client.status, .socketNotEstablished)
            guard let urlError = error as? URLError else {
                throw XCTSkip("Skip this test when error cannot be unwrapped")
            }
            // "Could not connect to the server"
            // because webSocket connections are not intercepted.
            XCTAssertTrue([-1003, -1004, -1022].contains(urlError.errorCode))
        }
    }

    @MainActor
    func testPing() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.setStatus(.connected)
        client.clientId = "yolo"

        do {
            _ = try await client.sendPing()
            XCTFail("Should have produced error")
        } catch {
            XCTAssertEqual(client.status, .connected)
            XCTAssertNotNil(error) // Should have error because testcases do not intercept websocket
        }
    }
}
#endif
