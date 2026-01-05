//
//  ParseHookTriggerTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 6/20/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length

class ParseHookTriggerTests: XCTestCase, @unchecked Sendable {

    struct GameScore: ParseObject {
        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        //: Your own properties
        var points: Int?

        //: custom initializers
        init() {}

        init(points: Int) {
            self.points = points
        }

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.points,
                                         original: object) {
                updated.points = object.points
            }
            return updated
        }
    }

    struct User: ParseUser {

        //: These are required by ParseObject
        var objectId: String?
        var createdAt: Date?
        var updatedAt: Date?
        var ACL: ParseACL?
        var originalData: Data?

        // These are required by ParseUser
        var username: String?
        var email: String?
        var emailVerified: Bool?
        var password: String?
        var authData: [String: [String: String]?]?

        // Your custom keys
        var customKey: String?
    }

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

    // swiftlint:disable:next function_body_length
    func testCoding() throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }

        let parseObjectType = GameScore.self
        let object = ParseHookTriggerObject.objectType(parseObjectType)
        let hookTrigger = try ParseHookTrigger(
            object: object,
            trigger: .afterSave,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected = "{\"className\":\"GameScore\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger.description, expected)

        let parseObject = GameScore()
        let object2 = ParseHookTriggerObject.object(parseObject)
        let hookTrigger2 = try ParseHookTrigger(
            object: object2,
            trigger: .afterSave,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected2 = "{\"className\":\"GameScore\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger2.description, expected2)

        let hookTrigger3 = try ParseHookTrigger(
            object: .file,
            trigger: .afterSave,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected3 = "{\"className\":\"@File\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger3.description, expected3)

        let hookTrigger4 = try ParseHookTrigger(
            object: .liveQueryConnect,
            trigger: .beforeConnect,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected4 = "{\"className\":\"@Connect\",\"triggerName\":\"beforeConnect\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger4.description, expected4)

        let hookTrigger5 = try ParseHookTrigger(
            object: .config,
            trigger: .afterSave,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected5 = "{\"className\":\"@Config\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger5.description, expected5)

        let parseUserType = User.self
        let parseUser = User()

        let object3 = ParseHookTriggerObject.objectType(parseUserType)
        let object4 = ParseHookTriggerObject.object(parseUser)

        let hookTrigger6 = try ParseHookTrigger(
            object: object3,
            trigger: .beforeLogin,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected6 = "{\"className\":\"_User\",\"triggerName\":\"beforeLogin\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger6.description, expected6)

        let hookTrigger7 = try ParseHookTrigger(
            object: object3,
            trigger: .afterLogin,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected7 = "{\"className\":\"_User\",\"triggerName\":\"afterLogin\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger7.description, expected7)

        let hookTrigger8 = try ParseHookTrigger(
            object: object3,
            trigger: .afterLogout,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected8 = "{\"className\":\"_User\",\"triggerName\":\"afterLogout\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger8.description, expected8)

        let hookTrigger9 = try ParseHookTrigger(
            object: object4,
            trigger: .beforeLogin,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected9 = "{\"className\":\"_User\",\"triggerName\":\"beforeLogin\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger9.description, expected9)

        let hookTrigger10 = try ParseHookTrigger(
            object: object4,
            trigger: .afterLogin,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected10 = "{\"className\":\"_User\",\"triggerName\":\"afterLogin\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger10.description, expected10)

        let hookTrigger11 = try ParseHookTrigger(
            object: object4,
            trigger: .afterLogout,
            url: url
        )
        // swiftlint:disable:next line_length
        let expected11 = "{\"className\":\"_User\",\"triggerName\":\"afterLogout\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger11.description, expected11)
    }

    // swiftlint:disable:next function_body_length
    func testParseHookTriggerObjectUnsupported() throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }

        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.objectType(GameScore.self),
                trigger: .beforeConnect,
                url: url
            )
        )
        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.object(GameScore()),
                trigger: .beforeConnect,
                url: url
            )
        )
        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.object(GameScore()),
                trigger: .beforeLogin,
                url: url
            )
        )
        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.object(GameScore()),
                trigger: .afterLogin,
                url: url
            )
        )
        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.object(GameScore()),
                trigger: .afterLogout,
                url: url
            )
        )
        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.file,
                trigger: .beforeConnect,
                url: url
            )
        )
        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.config,
                trigger: .beforeConnect,
                url: url
            )
        )
        XCTAssertThrowsError(
            try ParseHookTrigger(
                object: ParseHookTriggerObject.liveQueryConnect,
                trigger: .beforeFind,
                url: url
            )
        )
    }

    @MainActor
    func testCreate() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }

        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let created = try await hookTrigger.create()
        XCTAssertEqual(created, server)
    }

    @MainActor
    func testCreateError() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        do {
            _ = try await hookTrigger.create()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testCreateError2() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        var hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        hookTrigger.className = nil
        do {
            _ = try await hookTrigger.create()
            XCTFail("Should have thrown error")
        } catch {
            print(error)
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testUpdate() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let updated = try await hookTrigger.update()
        XCTAssertEqual(updated, server)
    }

    @MainActor
    func testUpdateError() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        do {
            _ = try await hookTrigger.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testUpdateError2() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        var hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        hookTrigger.className = nil
        do {
            _ = try await hookTrigger.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testUpdateError3() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        var hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterDelete,
                                           url: url)
        hookTrigger.trigger = nil
        do {
            _ = try await hookTrigger.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testFetch() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)

        let server = hookTrigger
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await hookTrigger.fetch()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchError() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        do {
            _ = try await hookTrigger.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testFetchError2() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        var hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        hookTrigger.className = nil
        do {
            _ = try await hookTrigger.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testFetchAll() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)

        let server = [hookTrigger]
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await hookTrigger.fetchAll()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchAllError() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        do {
            _ = try await hookTrigger.fetchAll()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testDelete() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let server = NoBody()
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        try await hookTrigger.delete()
    }

    @MainActor
    func testDeleteError() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        do {
            try await hookTrigger.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testDeleteError2() async throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        var hookTrigger = ParseHookTrigger(className: "foo",
                                           trigger: .afterSave,
                                           url: url)
        hookTrigger.className = nil
        do {
            _ = try await hookTrigger.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }
}
