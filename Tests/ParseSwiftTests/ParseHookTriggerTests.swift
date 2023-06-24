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

class ParseHookTriggerTests: XCTestCase {

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

    func testCoding() throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }

        let hookTrigger = try ParseHookTrigger(className: "foo",
                                               triggerName: .afterSave,
                                               url: url)
        // swiftlint:disable:next line_length
        let expected = "{\"className\":\"foo\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger.description, expected)
        let object = GameScore()
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        let hookTrigger2 = ParseHookTrigger(object: object,
                                            triggerName: .afterSave,
                                            url: url)
        // swiftlint:disable:next line_length
        let expected2 = "{\"className\":\"GameScore\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger2.description, expected2)
        let hookTrigger3 = try ParseHookTrigger(triggerName: .afterSave,
                                                url: url)
        // swiftlint:disable:next line_length
        let expected3 = "{\"className\":\"@File\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger3.description, expected3)
        let hookTrigger4 = try ParseHookTrigger(trigger: .beforeConnect,
                                                url: url)
        // swiftlint:disable:next line_length
        let expected4 = "{\"className\":\"@Connect\",\"triggerName\":\"beforeConnect\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger4.description, expected4)
        let hookTrigger5 = ParseHookTrigger(object: GameScore.self,
                                            trigger: .afterSave,
                                            url: url)
        // swiftlint:disable:next line_length
        let expected5 = "{\"className\":\"GameScore\",\"triggerName\":\"afterSave\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookTrigger5.description, expected5)
    }

    func testInitializerError() throws {
        guard let url = URL(string: "https://api.example.com/foo") else {
            XCTFail("Should have unwrapped")
            return
        }
        XCTAssertThrowsError(try ParseHookTrigger(trigger: .afterFind,
                                                  url: url))
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
        let hookTrigger = try ParseHookTrigger(trigger: .afterSave,
                                               url: url)
        do {
            _ = try await hookTrigger.create()
            XCTFail("Should have thrown error")
        } catch {
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
                                           triggerName: .afterSave,
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
        let hookTrigger = try ParseHookTrigger(trigger: .afterSave,
                                               url: url)
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
        hookTrigger.triggerName = nil
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
        let hookTrigger = try ParseHookTrigger(trigger: .afterSave,
                                               url: url)
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
        let hookTrigger = try ParseHookTrigger(trigger: .afterSave,
                                               url: url)
        do {
            _ = try await hookTrigger.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }
}
