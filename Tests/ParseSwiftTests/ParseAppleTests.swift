//
//  ParseAppleTests.swift
//  ParseSwift
//
//  Created by Corey Baker on 1/16/21.
//  Copyright © 2021 Network Reconnaissance Lab. All rights reserved.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import XCTest
@testable import ParseSwift

// swiftlint:disable:next type_body_length
class ParseAppleTests: XCTestCase, @unchecked Sendable {
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
        XCTAssertTrue(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testAuthenticationKeys() async throws {
        guard let tokenData = "test".data(using: .utf8) else {
            XCTFail("Should have created Data")
            return
        }
        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)
        XCTAssertEqual(authData, ["id": "testing", "token": "test"])
    }

    @MainActor
    func testVerifyMandatoryKeys() async throws {
        let authData = ["id": "testing", "token": "test"]
        let authDataWrong = ["id": "testing", "hello": "test"]
        XCTAssertTrue(ParseApple<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authData))
        XCTAssertFalse(ParseApple<User>
                        .AuthenticationKeys.id.verifyMandatoryKeys(authData: authDataWrong))
    }

    @MainActor
    func testLogin() async throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.apple.__type: authData]
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

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let user = try await User.apple.login(user: "testing", identityToken: tokenData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseApple<User>.isLinked(with: user))

        // Test stripping
        let strippedUser = user.apple.strip(currentUser)
        let isLinked = ParseApple.isLinked(with: strippedUser)
        XCTAssertFalse(isLinked)
    }

    @MainActor
    func testLoginAuthData() async throws {
        var serverResponse = LoginSignupResponse()
        let authData = ParseAnonymous<User>.AuthenticationKeys.id.makeDictionary()
        serverResponse.username = "hello"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.apple.__type: authData]
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

        let user = try await User.apple.login(authData: ["id": "testing",
                                                         "token": "test"])
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user, userOnServer)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseApple<User>.isLinked(with: user))
    }

    @MainActor
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

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)

        let user = try await User.apple.link(authData: authData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseApple<User>.isLinked(with: user))
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testReplaceAnonymousWithApple() async throws {
        try await loginAnonymousUser()
        MockURLProtocol.removeAll()
        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)

        var serverResponse = LoginSignupResponse()
        serverResponse.username = "hello"
        serverResponse.password = "world"
        serverResponse.objectId = "yarr"
        serverResponse.sessionToken = "myToken"
        serverResponse.authData = [serverResponse.apple.__type: authData,
                                   serverResponse.anonymous.__type: nil]
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

        let user = try await User.apple.login(user: "testing", identityToken: tokenData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.authData, userOnServer.authData)
        XCTAssertEqual(user.username, "hello")
        XCTAssertNil(user.password)
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testReplaceAnonymousWithLinkedApple() async throws {
        try await loginAnonymousUser()
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

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let user = try await User.apple.link(user: "testing", identityToken: tokenData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
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

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let user = try await User.apple.link(user: "testing", identityToken: tokenData)
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseApple<User>.isLinked(with: user))
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
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

        let user = try await User.apple.link(authData: ["id": "testing",
                                                        "token": "test"])
        let currentUser = try await User.current()
        XCTAssertEqual(user, currentUser)
        XCTAssertEqual(user.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(user.username, "hello10")
        XCTAssertNil(user.password)
        XCTAssertTrue(ParseApple<User>.isLinked(with: user))
        XCTAssertFalse(ParseAnonymous<User>.isLinked(with: user))
    }

    @MainActor
    func testLoginWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        do {
            _ = try await User.apple.login(authData: ["hello": "world"])
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
    func testLinkLoggedInUserWrongKeys() async throws {
        _ = try await loginNormally()
        MockURLProtocol.removeAll()

        do {
            _ = try await User.apple.link(authData: ["hello": "world"])
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

        guard let tokenData = "this".data(using: .utf8) else {
            XCTFail("Could not convert token data to string")
            return
        }

        let authData = try ParseApple<User>
            .AuthenticationKeys.id.makeDictionary(user: "testing",
                                                  identityToken: tokenData)
        user.authData = [User.apple.__type: authData]
        try await User.setCurrent(user)
        XCTAssertTrue(ParseApple.isLinked(with: user))

        var serverResponse = LoginSignupResponse()
        serverResponse.updatedAt = user.updatedAt

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

        let updatedUser = try await User.apple.unlink()
        let currentUser = try await User.current()
        XCTAssertEqual(updatedUser, currentUser)
        XCTAssertEqual(updatedUser.updatedAt, userOnServer.updatedAt)
        XCTAssertEqual(updatedUser.username, "hello10")
        XCTAssertNil(updatedUser.password)
        XCTAssertFalse(ParseApple<User>.isLinked(with: updatedUser))
    }

    @MainActor
    func testUnlinkNotLoggedIn() async throws {
        do {
            _ = try await User.apple.unlink()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertTrue(error.containedIn([.invalidLinkedSession]))
            let isLinked = await User.apple.isLinked()
            XCTAssertFalse(isLinked)
        }
    }

    func testUnlinkNotLoggedInCompletion() async throws {
        let expectation1 = XCTestExpectation(description: "Wait 1")
        User.apple.unlink { result in
            switch result {
            case .success:
                XCTFail("Should have produced error")
            case .failure(let error):
                XCTAssertEqual(error.code, .invalidLinkedSession)
            }
            expectation1.fulfill()
        }
        await fulfillment(of: [expectation1], timeout: 20.0)
    }

}
