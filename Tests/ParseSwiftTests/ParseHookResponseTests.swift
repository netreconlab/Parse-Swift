//
//  ParseHookResponseTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/21/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseHookResponseTests: XCTestCase {
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

    func testInitializers() throws {
        let response1 = ParseHookResponse<String>(success: "test")
        XCTAssertNotNil(response1.success)
        XCTAssertNil(response1.error)
        let response4 = ParseHookResponse<String>(error: .init(code: .otherCause, message: "yup"))
        XCTAssertNil(response4.success)
        XCTAssertNotNil(response4.error)
    }

    func testSuccess() throws {
        var response = ParseHookResponse(success: true)
        let expected = "{\"success\":true}"
        XCTAssertEqual(response.description, expected)
        response.error = .init(code: .accountAlreadyLinked, message: "yo")
        XCTAssertEqual(response.description, expected)
    }

    func testError() throws {
        let code = -1
        let message = "testing ParseHookResponse"
        guard let encoded: Data = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseHookResponse<String>.self, from: encoded)
        XCTAssertEqual(decoded.error?.code.rawValue, code)
        XCTAssertEqual(decoded.error?.message, message)
        XCTAssertNil(decoded.success)
        XCTAssertEqual(decoded.debugDescription, "{\"code\":\(code),\"error\":\"\(message)\"}")
        XCTAssertEqual(decoded.description, "{\"code\":\(code),\"error\":\"\(message)\"}")
        XCTAssertEqual(decoded.errorDescription, "{\"code\":\(code),\"error\":\"\(message)\"}")
    }

    func testCompare() throws {
        let code = ParseError.Code.objectNotFound.rawValue
        let message = "testing ParseHookResponse"
        guard let encoded = "{\"code\":\(code),\"error\":\"\(message)\"}".data(using: .utf8),
                let decoded = try ParseCoding
                    .jsonDecoder()
                    .decode(ParseHookResponse<String>.self,
                            from: encoded).error else {
            XCTFail("Should have unwrapped")
            return
        }

        let error: Error = decoded

        XCTAssertTrue(error.equalsTo(.objectNotFound))
        XCTAssertFalse(error.equalsTo(.invalidQuery))

        XCTAssertTrue(error.containedIn(.objectNotFound, .invalidQuery))
        XCTAssertFalse(error.containedIn(.operationForbidden, .invalidQuery))

        XCTAssertTrue(error.containedIn([.objectNotFound, .invalidQuery]))
        XCTAssertFalse(error.containedIn([.operationForbidden, .invalidQuery]))

        XCTAssertNotNil(error.equalsTo(.objectNotFound))
        XCTAssertNil(error.equalsTo(.invalidQuery))

        XCTAssertNotNil(error.containedIn(.objectNotFound, .invalidQuery))
        XCTAssertNil(error.containedIn(.operationForbidden, .invalidQuery))

        XCTAssertNotNil(error.containedIn([.objectNotFound, .invalidQuery]))
        XCTAssertNil(error.containedIn([.operationForbidden, .invalidQuery]))
    }
}
