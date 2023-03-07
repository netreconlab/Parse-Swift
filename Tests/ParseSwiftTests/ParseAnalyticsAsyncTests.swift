//
//  ParseAnalyticsAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseAnalyticsAsyncTests: XCTestCase {
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

    #if os(iOS)
    @MainActor
    func testTrackAppOpenedUIKit() async throws {

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
        _ = try await ParseAnalytics.trackAppOpened(launchOptions: options)
    }

    func testTrackAppOpenedUIKitError() async throws {

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
        _ = try await ParseAnalytics.trackAppOpened(launchOptions: options)
    }
    #endif

    @MainActor
    func testTrackAppOpened() async throws {
        let serverResponse = ParseError(code: .internalServer, message: "none")

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
            _ = try await ParseAnalytics.trackAppOpened(dimensions: ["stop": "drop"])
            XCTFail("Should have thrown error")
        } catch {

            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
    }

    @MainActor
    func testTrackAppOpenedError() async throws {
        let serverResponse = ParseError(code: .internalServer, message: "none")

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
            _ = try await ParseAnalytics.trackAppOpened(dimensions: ["stop": "drop"])
            XCTFail("Should have thrown error")
        } catch {

            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
    }

    @MainActor
    func testTrackEvent() async throws {
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
        _ = try await event.track()
    }

    @MainActor
    func testTrackEventError() async throws {
        let serverResponse = ParseError(code: .internalServer, message: "none")

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

        do {
            _ = try await event.track()
            XCTFail("Should have thrown error")
        } catch {

            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
    }

    func testTrackEventMutated() async throws {
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
        var event = ParseAnalytics(name: "hello")
        _ = try await event.track(dimensions: ["stop": "drop"])
    }

    func testTrackEventMutatedError() async throws {
        let serverResponse = ParseError(code: .internalServer, message: "none")

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
        var event = ParseAnalytics(name: "hello")
        do {
            _ = try await event.track(dimensions: ["stop": "drop"])
            XCTFail("Should have thrown error")
        } catch {

            guard let error = error as? ParseError else {
                XCTFail("Should be ParseError")
                return
            }
            XCTAssertEqual(error.message, serverResponse.message)
        }
    }
}
