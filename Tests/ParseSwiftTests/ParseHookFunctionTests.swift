//
//  ParseHookFunctionTests.swift
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

class ParseHookFunctionTests: XCTestCase {

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
        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        let expected = "{\"functionName\":\"foo\",\"url\":\"https:\\/\\/api.example.com\\/foo\"}"
        XCTAssertEqual(hookFunction.description, expected)
    }

    @MainActor
    func testCreate() async throws {

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let created = try await hookFunction.create()
        XCTAssertEqual(created, server)
    }

    @MainActor
    func testCreateError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.create()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testCreateError2() async throws {

        var hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        hookFunction.functionName = nil
        do {
            _ = try await hookFunction.create()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testUpdate() async throws {

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let updated = try await hookFunction.update()
        XCTAssertEqual(updated, server)
    }

    @MainActor
    func testUpdateError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testUpdateError2() async throws {

        var hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        hookFunction.functionName = nil
        do {
            _ = try await hookFunction.update()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testFetch() async throws {

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))

        let server = hookFunction
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await hookFunction.fetch()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testFetchError2() async throws {

        var hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        hookFunction.functionName = nil
        do {
            _ = try await hookFunction.fetch()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }

    @MainActor
    func testFetchAll() async throws {

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))

        let server = [hookFunction]
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let fetched = try await hookFunction.fetchAll()
        XCTAssertEqual(fetched, server)
    }

    @MainActor
    func testFetchAllError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        do {
            _ = try await hookFunction.fetchAll()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testDelete() async throws {
        let server = NoBody()
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        try await hookFunction.delete()
    }

    @MainActor
    func testDeleteError() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)

        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        do {
            try await hookFunction.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testDeleteError2() async throws {

        var hookFunction = ParseHookFunction(name: "foo",
                                             url: URL(string: "https://api.example.com/foo"))
        hookFunction.functionName = nil
        do {
            _ = try await hookFunction.delete()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }
}
