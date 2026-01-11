//
//  ParseServerAsyncTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 9/28/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

// Currently can't takeover URLSession with MockURLProtocol
// on Linux, Windows, etc. so disabling networking tests on
// those platforms.
#if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseServerAsyncTests: XCTestCase, @unchecked Sendable {
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
        try KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    @MainActor
    func testHealth() async throws {

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

        let health = try await ParseServer.health()
        XCTAssertEqual(health, healthOfServer)
    }

    @MainActor
    func testInformation() async throws {

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

        var info = try await ParseServer.information()
        XCTAssertEqual(info.version, try ParseVersion(string: information))

        // Test version not available
        info.versionString = nil
        XCTAssertNil(info.version)
    }

    @MainActor
    func testFeatures() async throws {

        let information = "6.0.0"
        let features = ["hello": true]
        let serverResponse: [String: AnyCodable] = [
            "parseServerVersion": AnyCodable(information),
            "features": AnyCodable(features)
        ]
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

        var info = try await ParseServer.information()
        XCTAssertEqual(info.version, try ParseVersion(string: information))
        XCTAssertEqual(try info.getFeatures(), features)

        // Test wrong feature cast
        do {
            let featureString: String = try info.getFeatures()
            XCTFail("Should not have casted to: \(featureString)")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("cast"))
        }

        // Test no features
        info.features = nil
        do {
            let featureDictionary: [String: Bool] = try info.getFeatures()
            XCTFail("Should not have casted to: \(featureDictionary)")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("no features"))
        }
    }
}
#endif
