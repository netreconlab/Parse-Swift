//
//  ParseVersionTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 7/2/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
import XCTest
@testable import ParseSwift

class ParseVersionTests: XCTestCase {
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

    func testGetSet() async throws {
        var current = try await ParseVersion.current()
        XCTAssertEqual(current.description, ParseConstants.version)
        try await ParseVersion.setCurrent(try ParseVersion(string: "1.0.0"))
        current = try await ParseVersion.current()
        XCTAssertEqual(current.description, "1.0.0")
    }

    func testDebug() async throws {
        let version = try ParseVersion(string: "1.0.0")
        XCTAssertEqual(version.debugDescription, "1.0.0")
        XCTAssertEqual(version.description, "1.0.0")
        XCTAssertEqual((try ParseVersion(string: "1.0.0-alpha.1")).description, "1.0.0-alpha.1")
        XCTAssertEqual((try ParseVersion(string: "1.0.0-beta.1")).description, "1.0.0-beta.1")
    }

    func testInitializers() async throws {
        let version1 = ParseVersion(major: 1, minor: 0, patch: 0)
        XCTAssertEqual(version1, try ParseVersion(string: "1.0.0"))
        let version1alpha = try ParseVersion(major: 1,
                                             minor: 0,
                                             patch: 0,
                                             prereleaseName: .alpha,
                                             prereleaseVersion: 1)
        XCTAssertEqual(version1alpha, try ParseVersion(string: "1.0.0-alpha.1"))
        let version1beta = try ParseVersion(major: 1,
                                            minor: 0,
                                            patch: 0,
                                            prereleaseName: .beta,
                                            prereleaseVersion: 1)
        XCTAssertEqual(version1beta, try ParseVersion(string: "1.0.0-beta.1"))
        XCTAssertThrowsError(try ParseVersion(major: 1,
                                              minor: 0,
                                              patch: 0,
                                              prereleaseName: .beta,
                                              prereleaseVersion: nil))
        XCTAssertThrowsError(try ParseVersion(major: 1,
                                              minor: 0,
                                              patch: 0,
                                              prereleaseName: nil,
                                              prereleaseVersion: 1))
    }

    func testCantInitializeWithBadStrings() async throws {
        XCTAssertThrowsError(try ParseVersion(string: "1"))
        XCTAssertThrowsError(try ParseVersion(string: "1.0"))
        XCTAssertThrowsError(try ParseVersion(string: "1.0.0.0"))
        XCTAssertThrowsError(try ParseVersion(string: "1.0.0-alpha"))
        XCTAssertThrowsError(try ParseVersion(string: "1.0.0-alpha.1.1"))
        XCTAssertThrowsError(try ParseVersion(string: "1.0.0-delta.1"))
        XCTAssertThrowsError(try ParseVersion(string: "alpha.0.0"))
        XCTAssertThrowsError(try ParseVersion(string: "1.0.alpha"))
    }

    func testDeleteFromStorage() async throws {
        var current = try await ParseVersion.current()
        XCTAssertEqual(current.description, ParseConstants.version)
        await ParseVersion.deleteCurrentContainerFromStorage()
        do {
            _ = try await ParseVersion.current()
            XCTFail("Should have failed")
        } catch {
            XCTAssertTrue(error.containedIn([.otherCause]))
        }
        try await ParseVersion.setCurrent(try ParseVersion(string: "1.0.0"))
        current = try await ParseVersion.current()
        XCTAssertEqual(current.description, "1.0.0")
    }

    #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
    func testCanRetrieveFromKeychain() async throws {
        let original = try await ParseVersion.current()
        try await ParseStorage.shared.delete(valueFor: ParseStorage.Keys.currentVersion)
        let current = try await ParseVersion.current()
        XCTAssertEqual(current, original)
    }
    #endif

    func testEqualTo() async throws {
        let version1 = try ParseVersion(string: "1.0.0")
        let version2 = try ParseVersion(string: "0.9.0")
        XCTAssertTrue(version1 == version1)
        XCTAssertFalse(version1 == version2)
    }

    func testLessThan() async throws {
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
        let version3 = try ParseVersion(string: "1.0.0-alpha.1")
        let version4 = try ParseVersion(string: "1.0.0-alpha.2")
        let version5 = try ParseVersion(string: "1.0.0-beta.1")
        let version6 = try ParseVersion(string: "1.0.1-beta.1")
        XCTAssertFalse(version2 < version6)
        XCTAssertFalse(version2 < version3)
        XCTAssertTrue(version3 < version1)
        XCTAssertTrue(version3 < version2)
        XCTAssertTrue(version5 < version1)
        XCTAssertTrue(version5 < version2)
        XCTAssertTrue(version3 < version4)
        XCTAssertFalse(version4 < version3)
        XCTAssertTrue(version3 < version5)
        XCTAssertTrue(version4 < version5)
        XCTAssertFalse(version5 < version4)
        XCTAssertTrue(version5 < version2)
    }

    func testLessThanEqual() async throws {
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
        let version3 = try ParseVersion(string: "1.0.0-alpha.1")
        let version4 = try ParseVersion(string: "1.0.0-alpha.2")
        let version5 = try ParseVersion(string: "1.0.0-beta.1")
        XCTAssertTrue(version3 <= version1)
        XCTAssertTrue(version3 <= version2)
        XCTAssertTrue(version5 <= version1)
        XCTAssertTrue(version5 <= version2)
        XCTAssertTrue(version3 <= version4)
        XCTAssertTrue(version3 <= version5)
        XCTAssertTrue(version4 <= version5)
        XCTAssertTrue(version5 <= version2)
    }

    func testGreaterThan() async throws {
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
        let version3 = try ParseVersion(string: "1.0.1-alpha.1")
        let version4 = try ParseVersion(string: "1.0.1-alpha.2")
        let version5 = try ParseVersion(string: "1.0.1-beta.1")
        XCTAssertFalse(version3 > version2)
        XCTAssertTrue(version2 > version4)
        XCTAssertTrue(version2 > version5)
        XCTAssertFalse(version1 > version3)
        XCTAssertTrue(version3 > version1)
        XCTAssertFalse(version3 > version4)
        XCTAssertTrue(version4 > version3)
        XCTAssertTrue(version5 > version3)
        XCTAssertFalse(version3 > version5)
        XCTAssertTrue(version5 > version4)
    }

    func testGreaterThanEqual() async throws {
        let version1 = try ParseVersion(string: "1.0.0")
        var version2 = version1
        XCTAssertTrue(version1 >= version2)
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
        let version3 = try ParseVersion(string: "1.0.1-alpha.1")
        let version4 = try ParseVersion(string: "1.0.1-alpha.2")
        let version5 = try ParseVersion(string: "1.0.1-beta.1")
        XCTAssertTrue(version2 >= version3)
        XCTAssertTrue(version2 >= version4)
        XCTAssertTrue(version2 >= version5)
        XCTAssertTrue(version3 >= version1)
        XCTAssertTrue(version4 >= version3)
        XCTAssertTrue(version5 >= version3)
        XCTAssertTrue(version5 >= version4)
    }
}
