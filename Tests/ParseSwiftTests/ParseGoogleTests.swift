//
//  ParseGoogleTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/1/22.
//  Copyright © 2022 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

class ParseGoogleTests: XCTestCase { // swiftlint:disable:this type_body_length
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
    }

    struct LoginSignupResponse: ParseUser {

        var objectId: String?
        var createdAt: Date?
        var sessionToken: String?
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

        init() {
            let date = Date()
            self.createdAt = date
            self.updatedAt = date
            self.objectId = "yarr"
            self.ACL = nil
            self.customKey = "blah"
            self.sessionToken = "myToken"
            self.username = "hello10"
            self.email = "hello@parse.com"
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

    @MainActor
    func loginNormally() async throws -> User {
        let loginResponse = LoginSignupResponse()

        MockURLProtocol.mockRequests { _ in
            do {
                let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
                return MockURLResponse(data: encoded, statusCode: 200)
            } catch {
                return nil
            }
        }
        return try await User.login(username: "parse", password: "user")
    }

    @MainActor
    func loginAnonymousUser() async throws {
        let authData = ["id": "yolo"]

        //: Convert the anonymous user to a real new user.
        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.anonymous.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.anonymous.login()
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))
    }

    func testAuthenticationKeys() throws {
        let authData = ParseGoogle<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  idToken: "this",
                                                  accessToken: "that")
        XCTAssertEqual(authData, ["id": "testing", "access_token": "that"])
        let authData2 = ParseGoogle<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  accessToken: "that")
        XCTAssertEqual(authData2, ["id": "testing", "access_token": "that"])
        let authData3 = ParseGoogle<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  idToken: "this")
        XCTAssertEqual(authData3, ["id": "testing", "id_token": "this"])
    }

    func testVerifyMandatoryKeys() throws {
        let authData = ["id": "testing", "id_token": "this"]
        let authData2 = ["id": "testing", "access_token": "this"]
        let authDataWrong = ["id": "testing", "hello": "test"]
        XCTAssertTrue(ParseGoogle<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertTrue(ParseGoogle<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData2))
        XCTAssertFalse(ParseGoogle<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
    }

    @MainActor
    func testLogin() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.google.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.google.login(id: "testing",
                                               idToken: "this",
                                               accessToken: "that")
        let currentUser = try await User.current()
        var isLinked = await user.google.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")

        // Test stripping
        let strippedUser = user.google.strip(currentUser)
        isLinked = ParseGoogle.isLinked(with: strippedUser)
        XCTAssertFalse(isLinked)
    }

    @MainActor
    func testLoginAuthData() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.google.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.google.login(authData: (["id": "testing",
                                                           "id_token": "this"]))
        let currentUser = try await User.current()
        let isLinked = await user.google.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertEqual(user.password, "world")
    }

    @MainActor
    func testLoginAuthDataBadAuth() async throws {
        do {
            _ = try await User.google.login(authData: (["id": "testing",
                                                        "bad": "token"]))
        } catch {
            guard let parseError = error.containedIn([.otherCause]) else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }

    @MainActor
    func testReplaceAnonymousWithLoggedIn() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.password = nil

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.google.login(id: "testing",
                                               idToken: "this",
                                               accessToken: "that")
        _ = try await User.current()
        let isLinked = await user.google.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testReplaceAnonymousWithLinked() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.password = nil

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.google.link(id: "testing",
                                              idToken: "this",
                                              accessToken: "that")
        _ = try await User.current()
        let isLinked = await user.google.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testLink() async throws {

        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.google.link(id: "testing",
                                              idToken: "this",
                                              accessToken: "that")
        _ = try await User.current()
        let isLinked = await user.google.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testLinkLoggedInAuthData() async throws {

        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()
        serverResponse.sessionToken = nil

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let authData = ParseGoogle<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing", accessToken: "accessToken")

        let user = try await User.google.link(authData: authData)
        _ = try await User.current()
        let isLinked = await user.google.isLinked()
        XCTAssertTrue(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testLinkLoggedInUserWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()
        do {
            _ = try await User.google.link(authData: ["hello": "world"])
        } catch {
            guard let parseError = error.containedIn([.otherCause]) else {
                XCTFail("Should have casted")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }

    @MainActor
    func testUnlink() async throws {

        var initialUser = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseGoogle<User>
            .AuthenticationKeys.id.makeDictionary(id: "testing",
                                                  idToken: "this")
        initialUser.authData = [User.google.__type: authData]
        try await User.setCurrent(initialUser)
        XCTAssertTrue(ParseGoogle.isLinked(with: initialUser))

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = initialUser.updatedAt

        var userOnServer: User!

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
            // Get dates in correct format from ParseDecoding strategy
            userOnServer = try serverResponse.getDecoder().decode(User.self, from: encoded)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.google.unlink()
        _ = try await User.current()
        let isLinked = await user.google.isLinked()
        XCTAssertFalse(isLinked)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
    }
}
