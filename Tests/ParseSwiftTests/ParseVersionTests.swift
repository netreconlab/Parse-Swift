//
//  ParseVersionTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/2/21.
//  Copyright © 2021 Parse Community. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseVersionTests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
        guard let url = URL(string: "http://localhost:1337/1") else {
            XCTFail("Should create valid URL")
            return
        }
        try ParseSwift.initialize(applicationId: "applicationId",
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

    func testGetSet() throws {
        XCTAssertEqual(ParseVersion.current?.string, ParseConstants.version)
        ParseVersion.current = try ParseVersion(string: "1.0.0")
        XCTAssertEqual(ParseVersion.current?.string, "1.0.0")
    }

    func testDebug() throws {
        let version = try ParseVersion(string: "1.0.0")
        XCTAssertEqual(version.debugDescription, "1.0.0")
        XCTAssertEqual(version.description, "1.0.0")
    }

    func testCantInitializeWithBadString() throws {
        XCTAssertThrowsError(try ParseVersion(string: "1.0"))
    }

    func testDeleteFromKeychain() throws {
        XCTAssertEqual(ParseVersion.current?.string, ParseConstants.version)
        ParseVersion.deleteCurrentContainerFromKeychain()
        XCTAssertNil(ParseVersion.current)
        ParseVersion.current = try ParseVersion(string: "1.0.0")
        XCTAssertEqual(ParseVersion.current?.string, "1.0.0")
        XCTAssertEqual(ParseVersion.current?.description, "1.0.0")
    }

    #if !os(Linux) && !os(Android) && !os(Windows)
    func testCanRetrieveFromKeychain() throws {
        guard let original = ParseVersion.current else {
            XCTFail("Should have unwrapped")
            return
        }
        try ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        XCTAssertEqual(ParseVersion.current, original)
    }
    #endif

    func testEqualTo() throws {
        let version1 = try ParseVersion(string: "1.0.0")
        let version2 = try ParseVersion(string: "0.9.0")
        XCTAssertTrue(version1 == version1)
        XCTAssertFalse(version1 == version2)
    }

    func testLessThan() throws {
        let version1 = try ParseVersion(string: "1.0.0")
        var version2 = try ParseVersion(string: "2.0.0")
        XCTAssertFalse(version1 < version1)
        XCTAssertTrue(version1 < version2)
        XCTAssertFalse(version2 < version1)
        version2 = try ParseVersion(string: "1.1.0")
        XCTAssertTrue(version1 < version2)
        XCTAssertFalse(version2 < version1)
        version2 = try ParseVersion(string: "1.0.1")
        XCTAssertTrue(version1 < version2)
        XCTAssertFalse(version2 < version1)
    }

    func testLessThanEqual() throws {
        let version1 = try ParseVersion(string: "1.0.0")
        var version2 = version1
        XCTAssertTrue(version1 <= version2)
        version2 = try ParseVersion(string: "0.9.0")
        XCTAssertFalse(version1 <= version2)
        version2 = try ParseVersion(string: "2.0.0")
        XCTAssertTrue(version1 <= version2)
        XCTAssertFalse(version2 <= version1)
        version2 = try ParseVersion(string: "1.1.0")
        XCTAssertTrue(version1 <= version2)
        XCTAssertFalse(version2 <= version1)
        version2 = try ParseVersion(string: "1.0.1")
        XCTAssertTrue(version1 <= version2)
        XCTAssertFalse(version2 <= version1)
    }

    func testGreaterThan() throws {
        let version1 = try ParseVersion(string: "1.0.0")
        var version2 = try ParseVersion(string: "2.0.0")
        XCTAssertFalse(version1 > version1)
        XCTAssertTrue(version2 > version1)
        XCTAssertFalse(version1 > version2)
        version2 = try ParseVersion(string: "1.1.0")
        XCTAssertTrue(version2 > version1)
        XCTAssertFalse(version1 > version2)
        version2 = try ParseVersion(string: "1.0.1")
        XCTAssertTrue(version2 > version1)
        XCTAssertFalse(version1 > version2)
    }

    func testGreaterThanEqual() throws {
        let version1 = try ParseVersion(string: "1.0.0")
        var version2 = version1
        // XCTAssertTrue(version1 >= version2)
        version2 = try ParseVersion(string: "0.9.0")
        XCTAssertFalse(version2 >= version1)
        version2 = try ParseVersion(string: "2.0.0")
        XCTAssertTrue(version2 >= version1)
        XCTAssertFalse(version1 >= version2)
        version2 = try ParseVersion(string: "1.1.0")
        XCTAssertTrue(version2 >= version1)
        XCTAssertFalse(version1 >= version2)
        version2 = try ParseVersion(string: "1.0.1")
        XCTAssertTrue(version2 >= version1)
        XCTAssertFalse(version1 >= version2)
    }
}
