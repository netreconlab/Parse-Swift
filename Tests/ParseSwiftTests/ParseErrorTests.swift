//
//  ParseErrorTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseErrorTests: XCTestCase {

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
        let error = ParseError(code: .accountAlreadyLinked, message: "hello")
        let expected = "ParseError code=208 error=hello"
        XCTAssertEqual(error.description, expected)
        let error2 = ParseError(otherCode: 593, message: "yolo")
        let expected2 = "error=yolo otherCode=593"
        XCTAssertTrue(error2.description.contains(expected2))
    }

    func testDecode() throws {
        let code = -1
        let message = "testing ParseError"
        guard let encoded: Data = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)
        XCTAssertEqual(decoded.code.rawValue, code)
        XCTAssertEqual(decoded.message, message)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.debugDescription, "ParseError code=\(code) error=\(message)")
        XCTAssertEqual(decoded.description, "ParseError code=\(code) error=\(message)")
        XCTAssertEqual(decoded.errorDescription, "ParseError code=\(code) error=\(message)")
    }

    func testDecodeMessage() throws {
        let code = -1
        let message = "testing ParseError"
        guard let encoded: Data = "{\"message\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)
        XCTAssertEqual(decoded.code.rawValue, code)
        XCTAssertEqual(decoded.message, message)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.debugDescription, "ParseError code=\(code) error=\(message)")
        XCTAssertEqual(decoded.description, "ParseError code=\(code) error=\(message)")
        XCTAssertEqual(decoded.errorDescription, "ParseError code=\(code) error=\(message)")
    }

    func testDecodeOther() throws {
        let code = 2000
        let message = "testing ParseError"
        guard let encoded = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)
        XCTAssertEqual(decoded.code, .other)
        XCTAssertEqual(decoded.message, message)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.debugDescription,
                       "ParseError code=\(ParseError.Code.other.rawValue) error=\(message) otherCode=\(code)")
        XCTAssertEqual(decoded.otherCode, code)
    }

    func testDecodeMissingCode() throws {
        let code = -1
        let message = "testing ParseError"
        guard let encoded = "{\"error\":\"\(message)\"}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)
        XCTAssertEqual(decoded.code, .otherCause)
        XCTAssertEqual(decoded.message, message)
        XCTAssertNil(decoded.error)
        XCTAssertEqual(decoded.debugDescription,
                       "ParseError code=\(code) error=\(message)")
        XCTAssertNil(decoded.otherCode)
    }

    func testCompare() throws {
        let code = ParseError.Code.objectNotFound.rawValue
        let message = "testing ParseError"
        guard let encoded = "{\"error\":\"\(message)\",\"code\":\(code)}".data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(ParseError.self, from: encoded)

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

    func testErrorCount() throws {
        let errorCodes = ParseError.Code.allCases
        XCTAssertGreaterThan(errorCodes.count, 50)
    }
}
