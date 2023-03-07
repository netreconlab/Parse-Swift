//
//  ParseBytesTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/9/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import XCTest
@testable import ParseSwift

class ParseBytesTests: XCTestCase {
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

    func testDecode() throws {
        let bytes = ParseBytes(base64: "ZnJveW8=")
        let encoded = try ParseCoding.jsonEncoder().encode(bytes)
        let decoded = try ParseCoding.jsonDecoder().decode(ParseBytes.self, from: encoded)
        XCTAssertEqual(decoded, bytes)
    }

    func testDebugString() {
        let bytes = ParseBytes(base64: "ZnJveW8=")
        let expected = "{\"__type\":\"Bytes\",\"base64\":\"ZnJveW8=\"}"
        XCTAssertEqual(bytes.debugDescription, expected)
        guard let data = Data(base64Encoded: "ZnJveW8=") else {
            XCTFail("Should have unwrapped")
            return
        }
        let bytes2 = ParseBytes(data: data)
        XCTAssertEqual(bytes2.debugDescription, expected)
    }

    func testDescription() {
        let bytes = ParseBytes(base64: "ZnJveW8=")
        let expected = "{\"__type\":\"Bytes\",\"base64\":\"ZnJveW8=\"}"
        XCTAssertEqual(bytes.description, expected)
        guard let data = Data(base64Encoded: "ZnJveW8=") else {
            XCTFail("Should have unwrapped")
            return
        }
        let bytes2 = ParseBytes(data: data)
        XCTAssertEqual(bytes2.description, expected)
    }
}
