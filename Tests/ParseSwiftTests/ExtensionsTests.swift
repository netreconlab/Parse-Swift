//
//  ExtensionsTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 11/19/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ExtensionsTests: XCTestCase {
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
                                        testing: false)
    }

    override func tearDown() async throws {
        try await super.tearDown()
        MockURLProtocol.removeAll()
        #if !os(Linux) && !os(Android) && !os(Windows)
        try await KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testURLSessionTesting() throws {
        XCTAssertNotNil(URLSession.parse.configuration.urlCache)
    }

    func testURLSession() throws {
        let headerKey = "User-Agent"
        let headerValue = "ParseSwift/\(ParseConstants.version) (\(ParseConstants.deviceType)"
        Parse.configuration.httpAdditionalHeaders = [headerKey: headerValue]
        let session = URLSession.parse
        XCTAssertNotNil(session.configuration.urlCache)
        XCTAssertEqual(session.configuration.requestCachePolicy, ParseSwift.configuration.requestCachePolicy)
    }

    func testReconnectInterval() throws {
        for index in 1 ..< 50 {
            let time = Utility.reconnectInterval(index)
            XCTAssertLessThan(time, 30)
            XCTAssertGreaterThan(time, -1)
        }
    }
    #endif
}
