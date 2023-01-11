//
//  ParseHealthCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 4/28/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseHealthCombineTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        ParseSwift.initialize(applicationId: "applicationId",
                              clientKey: "clientKey",
                              primaryKey: "primaryKey",
                              serverURL: url,
                              testing: true)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try KeychainStore.shared.deleteAll()
        #endif
        try ParseStorage.shared.deleteAll()
    }

    func testCheckOk() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let healthOfServer = ParseHealth.Status.ok
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        ParseHealth.checkPublisher()
            .sink(receiveCompletion: { result in
                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()
            }, receiveValue: { health in
                XCTAssertEqual(health, healthOfServer)
                expectation1.fulfill()
            })
            .store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testCheckInitialized() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let healthOfServer = ParseHealth.Status.initialized
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        ParseHealth.checkPublisher()
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
            .store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }

    func testCheckStarting() {
        var subscriptions = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let healthOfServer = ParseHealth.Status.starting
        let serverResponse = HealthResponse(status: healthOfServer)
        let encoded: Data!
        do {
            encoded = try ParseCoding.jsonEncoder().encode(serverResponse)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200, delay: 0.0)
        }

        ParseHealth.checkPublisher()
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
            .store(in: &subscriptions)

        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
