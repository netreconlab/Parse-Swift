//
//  ParseAnalyticsCombineTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 5/22/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

#if canImport(Combine)

import Foundation
import XCTest
import Combine
@testable import ParseSwift

class ParseAnalyticsCombineTests: XCTestCase, @unchecked Sendable {

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

    #if os(iOS)
    func testTrackAppOpenedUIKit() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let serverResponse = NoBody()

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
        let options = [UIApplication.LaunchOptionsKey.remoteNotification: ["stop": "drop"]]
        let publisher = ParseAnalytics.trackAppOpenedPublisher(launchOptions: options)
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }
    #endif

    func testTrackAppOpened() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let serverResponse = NoBody()

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

        let publisher = ParseAnalytics.trackAppOpenedPublisher(dimensions: ["stop": "drop"])
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testTrackEvent() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let serverResponse = NoBody()

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
        let event = ParseAnalytics(name: "hello")
        let publisher = event.trackPublisher()
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }

    func testTrackEventMutated() {
        var current = Set<AnyCancellable>()
        let expectation1 = XCTestExpectation(description: "Save")

        let serverResponse = NoBody()

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
        let event = ParseAnalytics(name: "hello")
        let publisher = event.trackPublisher(dimensions: ["stop": "drop"])
            .sink(receiveCompletion: { result in

                if case let .failure(error) = result {
                    XCTFail(error.localizedDescription)
                }
                expectation1.fulfill()

        }, receiveValue: { _ in })
        publisher.store(in: &current)
        wait(for: [expectation1], timeout: 20.0)
    }
}
#endif
