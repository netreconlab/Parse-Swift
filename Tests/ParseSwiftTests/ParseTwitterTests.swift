//
//  ParseTwitterTests.swift
//  ParseSwift
//
//  Created by Abdulaziz Alhomaidhi on 3/17/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

// swiftlint:disable type_body_length

class ParseTwitterTests: XCTestCase, @unchecked Sendable {
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
        #if !os(Linux) && !os(Android) && !os(Windows) && !os(WASI)
        try KeychainStore.shared.deleteAll()
        #endif
        try await ParseStorage.shared.deleteAll()
    }

    @MainActor
    func loginNormally() async throws -> User {
        let loginResponse = LoginSignupResponse()

        let encoded = try loginResponse.getEncoder().encode(loginResponse, skipKeys: .none)
        MockURLProtocol.mockRequests { _ in
			MockURLResponse(data: encoded, statusCode: 200)
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

    @MainActor
    func testAuthenticationKeys() async throws {

        let authData = ParseTwitter<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  screenName: "screenName",
                                                  consumerKey: "consumerKey",
                                                  consumerSecret: "consumerSecret",
                                                  authToken: "authToken",
                                                  authTokenSecret: "authTokenSecret")
        XCTAssertEqual(authData, ["id": "testing",
                                  "screen_name": "screenName",
                                  "consumer_key": "consumerKey",
                                  "consumer_secret": "consumerSecret",
                                  "auth_token": "authToken",
                                  "auth_token_secret": "authTokenSecret"])
    }

    @MainActor
    func testVerifyMandatoryKeys() async throws {
        let authData = ["id": "testing",
                        "screen_name": "screenName",
                        "consumer_key": "consumerKey",
                        "consumer_secret": "consumerSecret",
                        "auth_token": "authToken",
                        "auth_token_secret": "authTokenSecret"]
        let authDataWrong = ["id": "testing",
                             "screenName": "screenName",
                             "consumerKey": "consumerKey",
                             "consumerSecret": "consumerSecret",
                             "authToken": "authToken",
                             "hello": "authTokenSecret"]
        XCTAssertTrue(ParseTwitter<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertFalse(ParseTwitter<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
    }

    @MainActor
    func testLogin() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.twitter.__type: authData]
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

        let user = try await User.twitter.login(userId: "testing",
                                                screenName: "screenName",
                                                consumerKey: "consumerKey",
                                                consumerSecret: "consumerSecret",
                                                authToken: "tokenData",
                                                authTokenSecret: "authTokenSecret")

        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        var isLinked = ParseTwitter.isLinked(with: currentUser)
        XCTAssertTrue(isLinked)

        // Test stripping
        let strippedUser = user.twitter.strip(currentUser)
        isLinked = ParseTwitter.isLinked(with: strippedUser)
        XCTAssertFalse(isLinked)
    }

    @MainActor
    func testLoginAuthData() async throws {

        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.twitter.__type: authData]
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

        let twitterAuthData = ParseTwitter<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  screenName: "screenName",
                                                  consumerKey: "consumerKey",
                                                  consumerSecret: "consumerSecret",
                                                  authToken: "authToken",
                                                  authTokenSecret: "authTokenSecret")

        let user = try await User.twitter.login(authData: twitterAuthData)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = ParseTwitter.isLinked(with: currentUser)
        XCTAssertTrue(isLinked)
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

        let user = try await User.twitter.link(userId: "testing",
                                               screenName: "screenName",
                                               consumerKey: "consumerKey",
                                               consumerSecret: "consumerSecret",
                                               authToken: "tokenData",
                                               authTokenSecret: "authTokenSecret")
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = ParseTwitter.isLinked(with: currentUser)
        XCTAssertTrue(isLinked)
    }

    @MainActor
    func testLinkAuthData() async throws {

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

        let twitterAuthData = ParseTwitter<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  screenName: "screenName",
                                                  consumerKey: "consumerKey",
                                                  consumerSecret: "consumerSecret",
                                                  authToken: "authToken",
                                                  authTokenSecret: "authTokenSecret")
        let user = try await User.twitter.link(authData: twitterAuthData)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = ParseTwitter.isLinked(with: currentUser)
        XCTAssertTrue(isLinked)
    }

    func testReplaceAnonymousWithTwitter() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()

        let authData = ParseTwitter<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  screenName: "screenName",
                                                  consumerKey: "consumerSecret",
                                                  consumerSecret: "consumerSecret",
                                                  authToken: "this",
                                                  authTokenSecret: "authTokenSecret")

        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.twitter.__type: authData]
        serverResponse.createdAt = Date()
        serverResponse.updatedAt = serverResponse.createdAt?.addingTimeInterval(+300)

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.twitter.login(userId: "testing",
                                                screenName: "screenName",
                                                consumerKey: "consumerKey",
                                                consumerSecret: "consumerSecret",
                                                authToken: "this",
                                                authTokenSecret: "authTokenSecret")
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseTwitter<User>.isLinked(with: user))
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    func testReplaceAnonymousWithLinkedTwitter() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()
        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        let user = try await User.twitter.link(userId: "testing",
                                               screenName: "screenName",
                                               consumerKey: "consumerKey",
                                               consumerSecret: "consumerSecret",
                                               authToken: "this",
                                               authTokenSecret: "authTokenSecret")
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseTwitter<User>.isLinked(with: user))
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    func testLinkLoggedInUserWithTwitter() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil
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

        let user = try await User.twitter.link(userId: "testing",
                                               screenName: "screenName",
                                               consumerKey: "consumerKey",
                                               consumerSecret: "consumerSecret",
                                               authToken: "this",
                                               authTokenSecret: "authTokenSecret")
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = ParseTwitter.isLinked(with: currentUser)
        XCTAssertTrue(isLinked)
    }

    func testLinkLoggedInAuthData() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        var serverResponse = LoginSignupResponse()
        serverResponse.sessionToken = nil
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

        let authData = ParseTwitter<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  screenName: "screenName",
                                                  consumerKey: "consumerKey",
                                                  consumerSecret: "consumerSecret",
                                                  authToken: "authToken",
                                                  authTokenSecret: "authTokenSecret")
        let user = try await User.twitter.link(authData: authData)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = ParseTwitter.isLinked(with: currentUser)
        XCTAssertTrue(isLinked)
    }

    @MainActor
    func testLoginWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        do {
            _ = try await User.twitter.login(authData: ["hello": "world"])
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }

    @MainActor
    func testLinkWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        do {
            _ = try await User.twitter.link(authData: ["hello": "world"])
            XCTFail("Should have thrown error")
        } catch {
            guard let parseError = error as? ParseError else {
                XCTFail("Should have casted to ParseError")
                return
            }
            XCTAssertTrue(parseError.message.contains("consisting of keys"))
        }
    }

    @MainActor
    func testUnlink() async throws {
        var user = try await loginNormally()
        MockURLProtocol.removeAll()

        let authData = ParseTwitter<User>
            .AuthenticationKeys.id.makeDictionary(userId: "testing",
                                                  screenName: "screenName",
                                                  consumerKey: "consumerKey",
                                                  consumerSecret: "consumerSecret",
                                                  authToken: "tokenData",
                                                  authTokenSecret: "authTokenSecret")
        user = try await User.current()
        user.authData = [User.twitter.__type: authData]
        XCTAssertTrue(ParseTwitter.isLinked(with: user))
        try await User.setCurrent(user)

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = Date()

        let encoded: Data!
        do {
            encoded = try serverResponse.getEncoder().encode(serverResponse, skipKeys: .none)
        } catch {
            XCTFail("Should encode/decode. Error \(error)")
            return
        }
        MockURLProtocol.mockRequests { _ in
            return MockURLResponse(data: encoded, statusCode: 200)
        }

        user = try await User.twitter.unlink()
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        let isLinked = ParseTwitter.isLinked(with: currentUser)
        XCTAssertFalse(isLinked)
    }
}
