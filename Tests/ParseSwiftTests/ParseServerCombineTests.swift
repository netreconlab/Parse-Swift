//
//  ParseServerCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseServerCombineTests: XCTestCase, @unchecked Sendable {
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
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    func testCheckOk() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Received Value")
        let expectation2 = XCTestExpectation(description: "Received Complete")

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

        ParseServer.checkPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }, receiveValue: { health in
                XCTAssertEqual(health, healthOfServer)
                expectation1.fulfill()
            })
            .store(in: &current)

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testCheckError() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Received Value")
        let expectation2 = XCTestExpectation(description: "Received Complete")

        let healthOfServer = ParseServer.Status.error
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 503)
        }

        ParseServer.healthPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }, receiveValue: { health in
                XCTAssertEqual(health, healthOfServer)
                expectation1.fulfill()
            })
            .store(in: &current)

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }

    func testCheckInitialized() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Received Value")

        let healthOfServer = ParseServer.Status.initialized
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 429)
        }

        ParseServer.healthPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                XCTFail("Should not have received completion")
                expectation1.fulfill()
            }, receiveValue: { health in
                XCTAssertEqual(health, healthOfServer)
                expectation1.fulfill()
            })
            .store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testCheckStarting() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Received Value")

        let healthOfServer = ParseServer.Status.starting
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 429)
        }

        ParseServer.healthPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                XCTFail("Should not have received completion")
                expectation1.fulfill()
            }, receiveValue: { health in
                XCTAssertEqual(health, healthOfServer)
                expectation1.fulfill()
            })
            .store(in: &current)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testInformation() throws {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Received Value")
        let expectation2 = XCTestExpectation(description: "Received Complete")

        let information = "6.0.0"
        let serverResponse = ["parseServerVersion": information]
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

        let version = try ParseVersion(string: information)
        ParseServer.informationPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation2.fulfill()
            }, receiveValue: { info in
                XCTAssertEqual(info.version, version)
                expectation1.fulfill()
            })
            .store(in: &current)

        wait(for: [expectation1, expectation2], timeout: 20.0)
    }
}
#endif
