//
//  ParseLiveQueryCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/25/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI) && canImport(Combine)
import Foundation
import XCTest
@testable import ParseSwift
import Combine

class ParseLiveQueryCombineTests: XCTestCase, @unchecked Sendable {

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
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
        await URLSession.liveQuery.closeAll()
        ParseLiveQuery.defaultClient = nil
    }

    func testOpen() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.close()

        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        let publisher = client.openPublisher(isUserWantsToConnect: true)
            .sink(receiveCompletion: { result in

                switch result {

                case .finished:
                    XCTFail("Should have produced failure")
                case .failure(let error):
                    XCTAssertNotNil(error) // Should always fail since WS is not intercepted.
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have produced error")
        })
        publisher.store(in: &current)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testPingSocketNotEstablished() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.close()
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        let publisher = client.sendPingPublisher()
            .sink(receiveCompletion: { result in

                switch result {

                case .finished:
                    XCTFail("Should have produced failure")
                case .failure(let error):
                    XCTAssertEqual(client.status, .socketNotEstablished)
                    guard let urlError = error as? URLError else {
                        _ = XCTSkip("Skip this test when error cannot be unwrapped")
                        expectation1.fulfill()
                        return
                    }
                    // "Could not connect to the server"
                    // because webSocket connections are not intercepted.
                    XCTAssertTrue([-1003, -1004, -1022].contains(urlError.errorCode))
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have produced error")
        })
        publisher.store(in: &current)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }

    func testPing() async throws {
        guard let client = ParseLiveQuery.defaultClient else {
            XCTFail("Should be able to get client")
            return
        }
        await client.setStatus(.connected)
        client.clientId = "yolo"

        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Send Ping")
        let publisher = client.sendPingPublisher()
            .sink(receiveCompletion: { result in

                switch result {

                case .finished:
                    XCTFail("Should have produced failure")
                case .failure(let error):
                    XCTAssertEqual(client.status, .connected)
                    XCTAssertNotNil(error) // Should have error because testcases do not intercept websocket
                }
                expectation1.fulfill()

        }, receiveValue: { _ in
            XCTFail("Should have produced error")
        })
        publisher.store(in: &current)
        #if compiler(>=5.8.0) && !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        await fulfillment(of: [expectation1], timeout: 20.0)
        #elseif compiler(<5.8.0) && !os(iOS) && !os(tvOS)
        wait(for: [expectation1], timeout: 20.0)
        #endif
    }
}
#endif
