//
//  ParseHookFunctionRequestTests.swift
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

// swiftlint:disable:next type_body_length
class ParseHookFunctionRequestTests: XCTestCase {

    struct Parameters: ParseHookParametable {
        var hello = "world"
    }

    struct User: ParseCloudUser {

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

        // These are required by ParseCloudUser
        var sessionToken: String?
        var _failed_login_count: Int?
        var _account_lockout_expires_at: Date?

        // Your custom keys
        var customKey: String?

        //: Implement your own version of merge
        func merge(with object: Self) throws -> Self {
            var updated = try mergeParse(with: object)
            if updated.shouldRestoreKey(\.customKey,
                                         original: object) {
                updated.customKey = object.customKey
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

    func testCloudUserCoding() async throws {
        let sessionToken = "heel"
        let failedLoginCount = 3
        var accountLockoutExpiresAt = Date()
        let encodedDate = try ParseCoding.jsonEncoder().encode(accountLockoutExpiresAt)
        guard let encodeedDateString = String(data: encodedDate, encoding: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        accountLockoutExpiresAt = try ParseCoding.jsonDecoder().decode(Date.self, from: encodedDate)
        // swiftlint:disable:next line_length
        let encodedString = "{\"className\":\"_User\",\"sessionToken\":\"\(sessionToken)\",\"_failed_login_count\":\(failedLoginCount),\"_account_lockout_expires_at\":\(encodeedDateString)}"
        guard let encoded = encodedString.data(using: .utf8) else {
            XCTFail("Should have unwrapped")
            return
        }
        let decoded = try ParseCoding.jsonDecoder().decode(User.self, from: encoded)
        XCTAssertEqual(decoded.sessionToken, sessionToken)
        XCTAssertEqual(decoded.failedLoginCount, failedLoginCount)
        XCTAssertEqual(decoded.accountLockoutExpiresAt, accountLockoutExpiresAt)
    }

    func testCoding() async throws {
        let parameters = Parameters()
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         functionName: "wow",
                                                                         parameters: parameters)
        // swiftlint:disable:next line_length
        let expected = "{\"functionName\":\"wow\",\"headers\":{\"yolo\":\"me\"},\"ip\":\"1.1.1.1\",\"master\":true,\"params\":{\"hello\":\"world\"}}"
        XCTAssertEqual(functionRequest.description, expected)
    }

    func testGetLog() async throws {
        let parameters = Parameters()
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters,
                                                                         log: AnyCodable("peace"))
        let log: String = try functionRequest.getLog()
        XCTAssertEqual(log, "peace")
    }

    func testGetLogError() async throws {
        let parameters = Parameters()
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters,
                                                                         log: AnyCodable("peace"))
        do {
            let _: Double = try functionRequest.getLog()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("inferred"))
        }
    }

    func testGetContext() async throws {
        let parameters = Parameters()
        let context = ["peace": "out"]
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters,
                                                                         context: AnyCodable(context))
        let requestContext: [String: String] = try functionRequest.getContext()
        XCTAssertEqual(requestContext, context)
    }

    func testGetContextError() async throws {
        let parameters = Parameters()
        let context = ["peace": "out"]
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters,
                                                                         context: AnyCodable(context))
        do {
            let _: Double = try functionRequest.getContext()
            XCTFail("Should have failed")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("inferred"))
        }
    }

    func testOptions() throws {
        let parameters = Parameters()
        let sessionToken = "dog"
        let installationId = "cat"
        let user = User(sessionToken: sessionToken)
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         user: user,
                                                                         installationId: installationId,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters)
        let options = API.Options([.usePrimaryKey])
        let requestOptions = functionRequest.options()
        XCTAssertEqual(requestOptions, options)
        let functionRequest2 = ParseHookFunctionRequest<User, Parameters>(primaryKey: false,
                                                                          user: user,
                                                                          installationId: installationId,
                                                                          ipAddress: "1.1.1.1",
                                                                          headers: ["yolo": "me"],
                                                                          parameters: parameters)
        let options2 = API.Options([.sessionToken(sessionToken),
            .installationId(installationId)])
        let requestOptions2 = functionRequest2.options()
        XCTAssertEqual(requestOptions2, options2)
        let functionRequest3 = ParseHookFunctionRequest<User, Parameters>(primaryKey: false,
                                                                          user: user,
                                                                          ipAddress: "1.1.1.1",
                                                                          headers: ["yolo": "me"],
                                                                          parameters: parameters)
        let options3 = API.Options([.sessionToken(sessionToken)])
        let requestOptions3 = functionRequest3.options()
        XCTAssertEqual(requestOptions3, options3)
        let functionRequest4 = ParseHookFunctionRequest<User, Parameters>(primaryKey: false,
                                                                          installationId: installationId,
                                                                          ipAddress: "1.1.1.1",
                                                                          headers: ["yolo": "me"],
                                                                          parameters: parameters)
        let options4 = API.Options([.installationId(installationId)])
        let requestOptions4 = functionRequest4.options()
        XCTAssertEqual(requestOptions4, options4)
        let functionRequest5 = ParseHookFunctionRequest<User, Parameters>(primaryKey: false,
                                                                          ipAddress: "1.1.1.1",
                                                                          headers: ["yolo": "me"],
                                                                          parameters: parameters)
        let options5 = API.Options()
        let requestOptions5 = functionRequest5.options()
        XCTAssertEqual(requestOptions5, options5)
    }

    @MainActor
    func testHydrateUser() async throws {
        let sessionToken = "dog"
        let user = User(objectId: "objectId", sessionToken: sessionToken)
        var userOnServer = user
        userOnServer.createdAt = Date()
        userOnServer.updatedAt = Date()
        var server = userOnServer
        let encoded = try ParseCoding.jsonEncoder().encode(server)
        // Get dates in correct format from ParseDecoding strategy
        server = try ParseCoding.jsonDecoder().decode(User.self, from: encoded)
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let parameters = Parameters()
        let installationId = "cat"
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         user: user,
                                                                         installationId: installationId,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters)
        let requestHydrated = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         user: server,
                                                                         installationId: installationId,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters)
        let hydrated = try await functionRequest.hydrateUser()
        XCTAssertEqual(hydrated, requestHydrated)
    }

    @MainActor
    func testHydrateUserError() async throws {
        let sessionToken = "dog"
        let user = User(objectId: "objectId", sessionToken: sessionToken)
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let parameters = Parameters()
        let installationId = "cat"
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         user: user,
                                                                         installationId: installationId,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters)
        do {
            _ = try await functionRequest.hydrateUser()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(server.code))
        }
    }

    @MainActor
    func testHydrateUserError3() async throws {
        let server = ParseError(code: .commandUnavailable, message: "no delete")
        let encoded = try ParseCoding.jsonEncoder().encode(server)
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let parameters = Parameters()
        let installationId = "cat"
        let functionRequest = ParseHookFunctionRequest<User, Parameters>(primaryKey: true,
                                                                         installationId: installationId,
                                                                         ipAddress: "1.1.1.1",
                                                                         headers: ["yolo": "me"],
                                                                         parameters: parameters)
        do {
            _ = try await functionRequest.hydrateUser()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.equalsTo(.otherCause))
        }
    }
}
