//
//  ParseServerTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseServerTests: XCTestCase {

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
                                        testing: true)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func testCheckCommand() throws {
        let command = ParseServer.healthCommand()
        XCTAssertEqual(command.path.urlComponent, "/health")
        XCTAssertEqual(command.method, API.Method.POST)
        XCTAssertNil(command.body)
    }

    func testCheck() async throws {

        let healthOfServer = ParseServer.Status.ok
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }
        do {
            let health = try await ParseHealth.check()
            XCTAssertEqual(health, healthOfServer)

        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    func testCheckAsync() {
        let healthOfServer = ParseServer.Status.ok
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let expectation = XCTestExpectation(description: "Health check")
        ParseServer.health { result in
            switch result {

            case .success(let health):
                XCTAssertEqual(health, healthOfServer)

            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }

    func testCheckErrorAsync() {
        let healthOfServer = "Should throw error"
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(healthOfServer)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let expectation = XCTestExpectation(description: "Health check")
        ParseServer.health { result in
            if case .success = result {
                XCTFail("Should have thrown error")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
}
